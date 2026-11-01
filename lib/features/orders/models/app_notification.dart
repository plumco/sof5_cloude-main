// File: lib/features/orders/models/app_notification.dart

class AppNotification {
  final String id;
  final String recipientEmail;
  final String title;
  final String message;
  final String orderNo;
  final String type; // 'DISPATCH', 'REVERT', 'READY_FOR_DISPATCH', 'SYSTEM'
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.recipientEmail,
    required this.title,
    required this.message,
    required this.orderNo,
    required this.type,
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      recipientEmail: (json['recipientEmail']?.toString() ?? '').toLowerCase().trim(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      orderNo: json['orderNo']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipientEmail': recipientEmail.toLowerCase().trim(),
    'title': title,
    'message': message,
    'orderNo': orderNo,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };
}

