import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/orders/models/sales_order.dart';
import 'auth_role_helper.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class SaveOrderResult {
  final bool isCloudSynced;
  final bool isLocalSaved;
  final String? error;

  const SaveOrderResult({
    required this.isCloudSynced,
    required this.isLocalSaved,
    this.error,
  });
}

class CloudOrderService {
  static const String collectionName = 'sales_orders';

  /// Save an order with detailed cloud vs local persistence status
  static Future<SaveOrderResult> saveOrderWithStatus(SalesOrder order) async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    if (user != null) {
      if (order.createdByEmail.isEmpty) {
        order.createdByEmail = user.email ?? '';
      }
      if (order.createdById.isEmpty) {
        order.createdById = user.uid;
      }
    }
    order.savedAt ??= DateTime.now();
    if (order.isAdminEdited) {
      if (order.lastEditedBy.isEmpty) {
        order.lastEditedBy = user?.email ?? 'admin@so.com';
      }
      order.lastEditedAt ??= DateTime.now();
    }

    bool cloudSuccess = false;
    String? cloudError;

    // 1. Check Connectivity
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty;

      if (isOffline) {
        cloudError = 'Device is currently offline';
      } else {
        // 2. Save or update in Cloud Firestore
        final collection = FirebaseFirestore.instance.collection(collectionName);
        DocumentReference docRef;

        if (order.firestoreId.isNotEmpty) {
          docRef = collection.doc(order.firestoreId);
        } else {
          final existingQuery = await collection
              .where('salesOrderNo', isEqualTo: order.salesOrderNo)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 4));

          if (existingQuery.docs.isNotEmpty) {
            docRef = existingQuery.docs.first.reference;
            order.firestoreId = docRef.id;
          } else {
            docRef = collection.doc();
            order.firestoreId = docRef.id;
          }
        }

        await docRef.set(order.toJson(), SetOptions(merge: true)).timeout(const Duration(seconds: 4));
        cloudSuccess = true;
        debugPrint('CloudOrderService: Saved order to Firestore doc ${docRef.id}');
      }
    } catch (e) {
      cloudError = e.toString();
      debugPrint('CloudOrderService: Firestore save error (continuing with local cache): $e');
    }

    // 3. Always persist locally in cache
    final localSaved = await StorageService.saveOrderToHistory(order);

    return SaveOrderResult(
      isCloudSynced: cloudSuccess,
      isLocalSaved: localSaved,
      error: cloudError,
    );
  }

  /// Save an order to both Cloud Firestore and local storage cache (legacy compatibility)
  static Future<bool> saveOrder(SalesOrder order) async {
    final res = await saveOrderWithStatus(order);
    return res.isCloudSynced || res.isLocalSaved;
  }

  /// Push order from sales rep to Back Office for review (Locks order)
  static Future<bool> pushOrderForDispatch(SalesOrder order) async {
    order.status = 'PUSHED';
    order.pushedAt = DateTime.now();
    final saved = await saveOrder(order);

    // Notify Back Office team
    if (saved) {
      await NotificationService.sendNotification(
        recipientEmail: 'backoffice@gmail.com',
        title: '📋 New Order ${order.salesOrderNo} for Review',
        message: 'Sales Rep ${order.createdByEmail.isNotEmpty ? order.createdByEmail : order.salesPerson} submitted ${order.salesOrderNo} (${order.customerName}).',
        orderNo: order.salesOrderNo,
        type: 'PUSHED',
      );
    }
    return saved;
  }

  /// Back Office / Admin reverts order back to sales rep with a problem/correction note
  static Future<bool> revertOrderToRep(SalesOrder order, String reason) async {
    order.status = 'REVERTED';
    order.revertedAt = DateTime.now();
    order.revertReason = reason.trim();
    final saved = await saveOrder(order);

    // TARGETED NOTIFICATION: Send ONLY to the sales rep who created this SO
    if (saved && order.createdByEmail.isNotEmpty) {
      await NotificationService.sendNotification(
        recipientEmail: order.createdByEmail,
        title: '⚠️ Order ${order.salesOrderNo} Reverted',
        message: 'Back Office requested corrections: ${reason.trim()}',
        orderNo: order.salesOrderNo,
        type: 'REVERT',
      );
    }
    return saved;
  }

  /// Sales rep re-pushes corrected order to Back Office
  static Future<bool> repushOrder(SalesOrder order) async {
    return await pushOrderForDispatch(order);
  }

  /// Back Office / Admin pushes order to dispatch team after reviewing
  static Future<bool> pushToDispatchTeam(SalesOrder order) async {
    order.status = 'READY_FOR_DISPATCH';
    order.dispatchPushedAt = DateTime.now();
    final saved = await saveOrder(order);

    // Notify Dispatch team
    if (saved) {
      await NotificationService.sendNotification(
        recipientEmail: 'dispatch@gmail.com',
        title: '📦 Order ${order.salesOrderNo} Ready for Dispatch',
        message: 'Order for ${order.customerName} approved by Back Office and ready for shipping.',
        orderNo: order.salesOrderNo,
        type: 'READY_FOR_DISPATCH',
      );
    }
    return saved;
  }

  /// Dispatch team marks order as dispatched (shipped)
  static Future<bool> markOrderDispatched(SalesOrder order) async {
    order.status = 'DISPATCHED';
    order.dispatchedAt = DateTime.now();
    final saved = await saveOrder(order);

    if (saved) {
      // 1. TARGETED NOTIFICATION: Sent specifically to THAT CREATOR ONLY (e.g. Giriraj, G1, A1)
      if (order.createdByEmail.isNotEmpty) {
        await NotificationService.sendNotification(
          recipientEmail: order.createdByEmail,
          title: '🎉 Order ${order.salesOrderNo} Dispatched!',
          message: 'Your Sales Order for ${order.customerName} has been successfully dispatched by the dispatch team.',
          orderNo: order.salesOrderNo,
          type: 'DISPATCH',
        );
      }

      // 2. Notification to Dispatch Team
      await NotificationService.sendNotification(
        recipientEmail: 'dispatch@gmail.com',
        title: '✓ Order ${order.salesOrderNo} Dispatched',
        message: 'Order for ${order.customerName} processed and marked dispatched.',
        orderNo: order.salesOrderNo,
        type: 'DISPATCH',
      );
    }
    return saved;
  }

  /// Real-time stream of all users' orders from Firestore
  static Stream<List<SalesOrder>> streamAllOrders() {
    try {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['firestoreId'] = doc.id;
          return SalesOrder.fromJson(data);
        }).toList();

        // Sort descending by savedAt
        list.sort((a, b) {
          final aDate = a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        return list;
      });
    } catch (e) {
      debugPrint('CloudOrderService: stream error: $e');
      return Stream.value([]);
    }
  }

  /// One-time fetch of all orders
  static Future<List<SalesOrder>> fetchAllOrders() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['firestoreId'] = doc.id;
          return SalesOrder.fromJson(data);
        }).toList();

        list.sort((a, b) {
          final aDate = a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        return list;
      }
    } catch (e) {
      debugPrint('CloudOrderService: Firestore fetchAllOrders error: $e');
    }

    // Fallback to local storage
    return await StorageService.loadOrderHistory();
  }

  /// Delete an order from Firestore and local storage
  static Future<bool> deleteOrder(SalesOrder order, int? localIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = AuthRoleHelper.isAdmin(user?.email);
    // Only Admin can delete locked orders (PUSHED, READY_FOR_DISPATCH, DISPATCHED)
    final isLocked = order.status != 'DRAFT' && order.status != 'REVERTED';
    if (isLocked && !isAdmin) {
      debugPrint('CloudOrderService: Attempt to delete locked order (${order.status}) blocked');
      return false;
    }

    bool firestoreDeleted = false;
    try {
      if (order.firestoreId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(order.firestoreId)
            .delete();
        firestoreDeleted = true;
      } else if (order.salesOrderNo.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection(collectionName)
            .where('salesOrderNo', isEqualTo: order.salesOrderNo)
            .get();
        for (var doc in query.docs) {
          await doc.reference.delete();
          firestoreDeleted = true;
        }
      }
    } catch (e) {
      debugPrint('CloudOrderService: Firestore delete error: $e');
    }

    if (localIndex != null) {
      await StorageService.deleteOrderFromHistory(localIndex);
    }

    return firestoreDeleted;
  }
}
