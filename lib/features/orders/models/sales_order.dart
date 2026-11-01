// File: lib/features/orders/models/sales_order.dart
import 'cart_item.dart';

class OrderStatus {
  static const String draft = 'DRAFT';
  static const String pushed = 'PUSHED';
  static const String pushedToBackOffice = 'PUSHED';
  static const String inReview = 'IN_REVIEW';
  static const String reverted = 'REVERTED';
  static const String readyForDispatch = 'READY_FOR_DISPATCH';
  static const String dispatched = 'DISPATCHED';
  static const String delivered = 'DELIVERED';
  static const String cancelled = 'CANCELLED';
}

/// Helper function to check edit permissions per role
bool canEditOrder(SalesOrder order, String userRole) {
  final s = order.status.toUpperCase().trim();
  final role = userRole.toLowerCase().trim();

  // Dispatched, Delivered, Cancelled: Sirf Admin edit kar sakta hai
  if (s == OrderStatus.dispatched || s == OrderStatus.delivered || s == OrderStatus.cancelled) {
    return role == 'admin'; // sirf admin
  }

  // Pushed to Back Office / In Review / Ready for Dispatch: Admin aur Backoffice review/edit kar sakte hain, Sales NAHI
  if (s == OrderStatus.pushedToBackOffice ||
      s == OrderStatus.pushed ||
      s == 'PUSHED_TO_BACKOFFICE' ||
      s == OrderStatus.inReview ||
      s == 'IN_REVIEW' ||
      s == OrderStatus.readyForDispatch) {
    return role == 'admin' || role == 'backoffice';
  }

  return true; // Draft/Saved/Reverted sab edit kar sakte hain
}

class SalesOrder {
  String salesOrderNo;
  DateTime orderDate;
  DateTime requiredDate;
  String poNo;

  // Customer Info
  String customerCode;
  String customerName;
  String contactPerson;
  String phone;
  String mobile;

  // Bill To
  String bill1;
  String bill2;
  String billCity;
  String billProvince;
  String billZip;
  bool sameShip;

  // Ship To
  String ship1;
  String ship2;
  String shipCity;
  String shipProvince;
  String shipZip;
  bool sameBill;

  // Additional Info
  String paymentTerms;
  String salesPerson;
  String deliveryTerm;
  String projectName;
  String remarks;

  // Items
  List<CartItem> items;
  DateTime? savedAt;
  String createdByEmail;
  String createdById;
  String firestoreId;

  // Workflow & Dispatch Tracking
  String status; // 'DRAFT', 'PUSHED', 'REVERTED', 'READY_FOR_DISPATCH', 'DISPATCHED', 'DELIVERED', 'CANCELLED'
  DateTime? pushedAt;
  DateTime? revertedAt;
  String revertReason;
  DateTime? dispatchPushedAt; // When backoffice pushed to dispatch team
  DateTime? dispatchedAt;

  // Audit Trail & Admin Override Fields
  String adminEditReason;
  String adminEditLog;
  String lastEditedBy;
  DateTime? lastEditedAt;
  List<Map<String, dynamic>> editHistory;
  bool isAdminEdited;

  SalesOrder({
    this.salesOrderNo = 'SO-2026-0001',
    DateTime? orderDate,
    DateTime? requiredDate,
    this.poNo = '',
    this.customerCode = '',
    this.customerName = '',
    this.contactPerson = '',
    this.phone = '',
    this.mobile = '',
    this.bill1 = '',
    this.bill2 = '',
    this.billCity = '',
    this.billProvince = '',
    this.billZip = '',
    this.sameShip = false,
    this.ship1 = '',
    this.ship2 = '',
    this.shipCity = '',
    this.shipProvince = '',
    this.shipZip = '',
    this.sameBill = true,
    this.paymentTerms = 'Advance ',
    this.salesPerson = '',
    this.deliveryTerm = 'FOR ',
    this.projectName = '',
    this.remarks = 'Please deliver during office hours. Contact site engineer before delivery.',
    List<CartItem>? items,
    this.savedAt,
    this.createdByEmail = '',
    this.createdById = '',
    this.firestoreId = '',
    this.status = OrderStatus.draft,
    this.pushedAt,
    this.revertedAt,
    this.revertReason = '',
    this.dispatchPushedAt,
    this.dispatchedAt,
    this.adminEditReason = '',
    this.adminEditLog = '',
    this.lastEditedBy = '',
    this.lastEditedAt,
    List<Map<String, dynamic>>? editHistory,
    this.isAdminEdited = false,
  })  : orderDate = orderDate ?? DateTime.now(),
        requiredDate = requiredDate ?? DateTime.now().add(const Duration(days: 7)),
        items = items ?? [],
        editHistory = editHistory ?? [];

  double get subtotal => items.fold(0.0, (sum, it) => sum + it.amount);
  int get totalQty => items.fold(0, (sum, it) => sum + it.qty);
  double get gst => subtotal * 0.18;
  double get grandTotal => subtotal + gst;

  /// Record an administrative edit with reason and full audit trail snapshot
  void recordAdminEdit({required String email, required String reason}) {
    adminEditReason = reason.trim();
    adminEditLog = 'Edited by $email at ${DateTime.now().toIso8601String()} - Reason: $adminEditReason';
    lastEditedBy = email;
    lastEditedAt = DateTime.now();
    isAdminEdited = true;
    editHistory.add({
      'editedBy': email,
      'editedAt': lastEditedAt?.toIso8601String(),
      'oldStatus': status,
      'reason': adminEditReason,
      'oldItems': items.map((it) => it.toJson()).toList(),
    });
  }

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parseHistory(dynamic rawList) {
      if (rawList is List) {
        return rawList
            .whereType<Map<dynamic, dynamic>>()
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
      return [];
    }

    return SalesOrder(
      salesOrderNo: json['salesOrderNo']?.toString() ?? 'SO-2026-0001',
      orderDate: json['orderDate'] != null ? DateTime.tryParse(json['orderDate'].toString()) ?? DateTime.now() : DateTime.now(),
      requiredDate: json['requiredDate'] != null ? DateTime.tryParse(json['requiredDate'].toString()) ?? DateTime.now() : DateTime.now(),
      poNo: json['poNo']?.toString() ?? '',
      customerCode: json['customerCode']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      bill1: json['bill1']?.toString() ?? '',
      bill2: json['bill2']?.toString() ?? '',
      billCity: json['billCity']?.toString() ?? '',
      billProvince: json['billProvince']?.toString() ?? '',
      billZip: json['billZip']?.toString() ?? '',
      sameShip: json['sameShip'] == true,
      ship1: json['ship1']?.toString() ?? '',
      ship2: json['ship2']?.toString() ?? '',
      shipCity: json['shipCity']?.toString() ?? '',
      shipProvince: json['shipProvince']?.toString() ?? '',
      shipZip: json['shipZip']?.toString() ?? '',
      sameBill: json['sameBill'] ?? true,
      paymentTerms: json['paymentTerms']?.toString() ?? 'Advance ',
      salesPerson: json['salesPerson']?.toString() ?? '',
      deliveryTerm: json['deliveryTerm']?.toString() ?? 'FOR ',
      projectName: json['projectName']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      items: (json['cart'] is List)
          ? (json['cart'] as List).map((i) => CartItem.fromJson(i as Map<String, dynamic>)).toList()
          : (json['items'] is List)
              ? (json['items'] as List).map((i) => CartItem.fromJson(i as Map<String, dynamic>)).toList()
              : [],
      savedAt: json['savedAt'] != null ? DateTime.tryParse(json['savedAt'].toString()) : null,
      createdByEmail: json['createdByEmail']?.toString() ?? '',
      createdById: json['createdById']?.toString() ?? '',
      firestoreId: json['firestoreId']?.toString() ?? '',
      status: json['status']?.toString() ?? OrderStatus.draft,
      pushedAt: json['pushedAt'] != null ? DateTime.tryParse(json['pushedAt'].toString()) : null,
      revertedAt: json['revertedAt'] != null ? DateTime.tryParse(json['revertedAt'].toString()) : null,
      revertReason: json['revertReason']?.toString() ?? '',
      dispatchPushedAt: json['dispatchPushedAt'] != null ? DateTime.tryParse(json['dispatchPushedAt'].toString()) : null,
      dispatchedAt: json['dispatchedAt'] != null ? DateTime.tryParse(json['dispatchedAt'].toString()) : null,
      adminEditReason: json['adminEditReason']?.toString() ?? '',
      adminEditLog: json['adminEditLog']?.toString() ?? '',
      lastEditedBy: json['lastEditedBy']?.toString() ?? '',
      lastEditedAt: json['lastEditedAt'] != null ? DateTime.tryParse(json['lastEditedAt'].toString()) : null,
      editHistory: parseHistory(json['editHistory']),
      isAdminEdited: json['isAdminEdited'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'salesOrderNo': salesOrderNo,
    'orderDate': orderDate.toIso8601String().substring(0, 10),
    'requiredDate': requiredDate.toIso8601String().substring(0, 10),
    'poNo': poNo,
    'customerCode': customerCode,
    'customerName': customerName,
    'contactPerson': contactPerson,
    'phone': phone,
    'mobile': mobile,
    'bill1': bill1,
    'bill2': bill2,
    'billCity': billCity,
    'billProvince': billProvince,
    'billZip': billZip,
    'sameShip': sameShip,
    'ship1': ship1,
    'ship2': ship2,
    'shipCity': shipCity,
    'shipProvince': shipProvince,
    'shipZip': shipZip,
    'sameBill': sameBill,
    'paymentTerms': paymentTerms,
    'salesPerson': salesPerson,
    'deliveryTerm': deliveryTerm,
    'projectName': projectName,
    'remarks': remarks,
    'cart': items.map((it) => it.toJson()).toList(),
    'savedAt': (savedAt ?? DateTime.now()).toIso8601String(),
    'createdByEmail': createdByEmail,
    'createdById': createdById,
    'firestoreId': firestoreId,
    'status': status,
    'pushedAt': pushedAt?.toIso8601String(),
    'revertedAt': revertedAt?.toIso8601String(),
    'revertReason': revertReason,
    'dispatchPushedAt': dispatchPushedAt?.toIso8601String(),
    'dispatchedAt': dispatchedAt?.toIso8601String(),
    'adminEditReason': adminEditReason,
    'adminEditLog': adminEditLog,
    'lastEditedBy': lastEditedBy,
    'lastEditedAt': lastEditedAt?.toIso8601String(),
    'editHistory': editHistory,
    'isAdminEdited': isAdminEdited,
  };
}
