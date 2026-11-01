import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/orders/models/app_notification.dart';

class NotificationService {
  static const String collectionName = 'notifications';
  static const String _localKey = 'hpf_user_notifications';

  /// Send a targeted notification to a specific user (and persist to Firestore & cache)
  static Future<bool> sendNotification({
    required String recipientEmail,
    required String title,
    required String message,
    required String orderNo,
    required String type,
  }) async {
    final cleanRecipient = recipientEmail.trim().toLowerCase();
    if (cleanRecipient.isEmpty) {
      debugPrint('NotificationService: Skipping notification - empty recipient');
      return false;
    }

    final id = 'notif_${DateTime.now().millisecondsSinceEpoch}_${cleanRecipient.hashCode.abs()}';
    final notif = AppNotification(
      id: id,
      recipientEmail: cleanRecipient,
      title: title,
      message: message,
      orderNo: orderNo,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // 1. Cloud Firestore write
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(id)
          .set(notif.toJson());
      debugPrint('NotificationService: Sent notification to $cleanRecipient');
    } catch (e) {
      debugPrint('NotificationService: Cloud Firestore error (fallback to local): $e');
    }

    // 2. Local storage cache
    await _saveToLocalCache(notif);
    return true;
  }

  /// Real-time stream of notifications strictly for the targeted user
  static Stream<List<AppNotification>> streamUserNotifications(String userEmail) {
    final cleanEmail = userEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return Stream.value([]);
    }

    try {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .where('recipientEmail', isEqualTo: cleanEmail)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return AppNotification.fromJson(data);
        }).toList();

        // Sort newest first
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      });
    } catch (e) {
      debugPrint('NotificationService: stream error: $e');
      return Stream.value([]);
    }
  }

  /// Mark single notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('NotificationService: markAsRead cloud error: $e');
    }

    // Update local cache
    final localList = await loadLocalNotifications();
    for (var n in localList) {
      if (n.id == notificationId) {
        n.isRead = true;
      }
    }
    await _saveAllLocalCache(localList);
  }

  /// Mark all notifications as read for current user
  static Future<void> markAllAsRead(String userEmail) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('recipientEmail', isEqualTo: cleanEmail)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint('NotificationService: markAllAsRead cloud error: $e');
    }

    final localList = await loadLocalNotifications();
    for (var n in localList) {
      if (n.recipientEmail == cleanEmail) {
        n.isRead = true;
      }
    }
    await _saveAllLocalCache(localList);
  }

  static Future<void> _saveToLocalCache(AppNotification notif) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await loadLocalNotifications();
      list.insert(0, notif);
      final trimmed = list.take(50).map((n) => n.toJson()).toList();
      await prefs.setString(_localKey, json.encode(trimmed));
    } catch (_) {}
  }

  static Future<void> _saveAllLocalCache(List<AppNotification> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = list.take(50).map((n) => n.toJson()).toList();
      await prefs.setString(_localKey, json.encode(trimmed));
    } catch (_) {}
  }

  static Future<List<AppNotification>> loadLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw);
        return decoded.map((i) => AppNotification.fromJson(i)).toList();
      }
    } catch (_) {}
    return [];
  }
}
