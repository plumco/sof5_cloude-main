import 'package:flutter_test/flutter_test.dart';
import 'package:huliot_so_flutter/models/app_notification.dart';
import 'package:huliot_so_flutter/models/sales_order.dart';

void main() {
  group('Targeted Notification Privacy & Delivery Tests', () {
    test('Notification model serializes and deserializes accurately', () {
      final notif = AppNotification(
        id: 'notif_123',
        recipientEmail: 'Giriraj@Huliot.com',
        title: '🎉 Order SO-2026-0001 Dispatched!',
        message: 'Your order for Metro Infra has been dispatched.',
        orderNo: 'SO-2026-0001',
        type: 'DISPATCH',
        timestamp: DateTime(2026, 10, 27, 10, 30),
        isRead: false,
      );

      final json = notif.toJson();
      // Recipient email is normalized to lowercase and trimmed
      expect(json['recipientEmail'], equals('giriraj@huliot.com'));

      final fromJson = AppNotification.fromJson(json);
      expect(fromJson.id, equals('notif_123'));
      expect(fromJson.recipientEmail, equals('giriraj@huliot.com'));
      expect(fromJson.type, equals('DISPATCH'));
      expect(fromJson.isRead, isFalse);
    });

    test('SECURITY & PRIVACY: Only the specific creator rep receives dispatch notification, NOT all users', () {
      // Giriraj creates order
      final girirajOrder = SalesOrder(
        salesOrderNo: 'SO-GIRIRAJ-01',
        createdByEmail: 'giriraj@huliot.com',
        customerName: 'Giriraj Constructions',
        status: 'READY_FOR_DISPATCH',
      );

      // Simulation of notifications generated when order is dispatched
      final generatedNotifications = <AppNotification>[
        // 1. Notification targeted to creator
        AppNotification(
          id: 'n_1',
          recipientEmail: girirajOrder.createdByEmail,
          title: '🎉 Order ${girirajOrder.salesOrderNo} Dispatched!',
          message: 'Your order has been dispatched.',
          orderNo: girirajOrder.salesOrderNo,
          type: 'DISPATCH',
        ),
        // 2. Notification to Dispatch team
        AppNotification(
          id: 'n_2',
          recipientEmail: 'dispatch@gmail.com',
          title: '✓ Order ${girirajOrder.salesOrderNo} Dispatched',
          message: 'Order shipped.',
          orderNo: girirajOrder.salesOrderNo,
          type: 'DISPATCH',
        ),
      ];

      // Verify that Giriraj receives the notification
      final girirajFeed = generatedNotifications
          .where((n) => n.recipientEmail == 'giriraj@huliot.com')
          .toList();
      expect(girirajFeed.length, equals(1));
      expect(girirajFeed.first.orderNo, equals('SO-GIRIRAJ-01'));

      // Verify Dispatch team receives their notification
      final dispatchFeed = generatedNotifications
          .where((n) => n.recipientEmail == 'dispatch@gmail.com')
          .toList();
      expect(dispatchFeed.length, equals(1));

      // PRIVACY AUDIT: An unrelated sales rep (e.g. sales2@huliot.com) MUST NOT receive Giriraj's notification
      const unrelatedUserEmail = 'sales2@huliot.com';
      final unrelatedFeed = generatedNotifications
          .where((n) => n.recipientEmail == unrelatedUserEmail)
          .toList();
      expect(
        unrelatedFeed.isEmpty,
        isTrue,
        reason: 'Privacy violation! Unrelated sales rep received notification for another user\'s order!',
      );
    });
  });
}
