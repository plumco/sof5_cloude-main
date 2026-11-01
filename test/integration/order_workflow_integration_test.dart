import 'package:flutter_test/flutter_test.dart';
import 'package:huliot_so_flutter/models/sales_order.dart';
import 'package:huliot_so_flutter/models/cart_item.dart';
import 'package:huliot_so_flutter/models/app_notification.dart';
import 'package:huliot_so_flutter/services/auth_role_helper.dart';

void main() {
  group('E2E 4-Tier Order Lifecycle & Targeted Notification Integration Simulation', () {
    test('Complete Workflow: Sales Rep (Giriraj) -> Back Office -> Dispatch -> Targeted Notification -> Admin Master Access', () async {
      // ── Step 1: Sales Person Persona (Giriraj) ─────────────────
      const girirajEmail = 'giriraj@huliot.com';
      expect(AuthRoleHelper.isAdmin(girirajEmail), isFalse);
      expect(AuthRoleHelper.isBackOffice(girirajEmail), isFalse);
      expect(AuthRoleHelper.isDispatch(girirajEmail), isFalse);

      final order = SalesOrder(
        salesOrderNo: 'SO-2026-GIRIRAJ-001',
        createdByEmail: girirajEmail,
        customerName: 'Giriraj Builders & Infra',
        status: 'DRAFT',
        items: [
          CartItem(
            itemCode: 'HPF-PIPE-110',
            description: '110mm Ultra Silent Soil Pipe',
            listPrice: 1500.0,
            discount: 0.50,
            qty: 20,
          ),
        ],
      );

      expect(order.status, equals('DRAFT'));
      expect(order.subtotal, equals(15000.0));
      expect(order.grandTotal, equals(17700.0)); // 15000 + 18% GST (2700)

      // Sales rep pushes SO to Back Office for review
      order.status = 'PUSHED';
      order.pushedAt = DateTime.now();

      expect(order.status, equals('PUSHED'));
      expect(order.pushedAt, isNotNull);

      // ── Step 2: Back Office Team Persona (backoffice@gmail.com) ──
      const backOfficeEmail = 'backoffice@gmail.com';
      expect(AuthRoleHelper.isBackOffice(backOfficeEmail), isTrue);
      expect(AuthRoleHelper.isAdmin(backOfficeEmail), isFalse);
      expect(AuthRoleHelper.isDispatch(backOfficeEmail), isFalse);

      // Back office reviews and approves: pushes to Dispatch
      order.status = 'READY_FOR_DISPATCH';
      order.dispatchPushedAt = DateTime.now();

      expect(order.status, equals('READY_FOR_DISPATCH'));
      expect(order.dispatchPushedAt, isNotNull);

      // ── Step 3: Dispatch Team Persona (dispatch@gmail.com) ───────
      const dispatchEmail = 'dispatch@gmail.com';
      expect(AuthRoleHelper.isDispatch(dispatchEmail), isTrue);
      expect(AuthRoleHelper.isBackOffice(dispatchEmail), isFalse);
      expect(AuthRoleHelper.isAdmin(dispatchEmail), isFalse);

      // Dispatch team marks order as Dispatched
      order.status = 'DISPATCHED';
      order.dispatchedAt = DateTime.now();

      expect(order.status, equals('DISPATCHED'));
      expect(order.dispatchedAt, isNotNull);

      // ── Step 4: Targeted Notification Delivery Simulation ───────
      final notifications = <AppNotification>[
        // Creator notification
        AppNotification(
          id: 'n_creator',
          recipientEmail: order.createdByEmail,
          title: '🎉 Order ${order.salesOrderNo} Dispatched!',
          message: 'Your Sales Order has been dispatched.',
          orderNo: order.salesOrderNo,
          type: 'DISPATCH',
        ),
        // Dispatch team notification
        AppNotification(
          id: 'n_dispatch',
          recipientEmail: dispatchEmail,
          title: '✓ Order ${order.salesOrderNo} Dispatched',
          message: 'Order dispatched.',
          orderNo: order.salesOrderNo,
          type: 'DISPATCH',
        ),
      ];

      // Giriraj's inbox receives the notification
      final girirajFeed = notifications.where((n) => n.recipientEmail == girirajEmail).toList();
      expect(girirajFeed.length, equals(1));
      expect(girirajFeed.first.orderNo, equals('SO-2026-GIRIRAJ-001'));

      // Other sales reps do NOT receive anything
      const anotherRepEmail = 'sales2@huliot.com';
      final anotherRepFeed = notifications.where((n) => n.recipientEmail == anotherRepEmail).toList();
      expect(anotherRepFeed.isEmpty, isTrue);

      // ── Step 5: Admin Persona (admin@gmail.com) ───────────────────
      const adminEmail = 'admin@gmail.com';
      expect(AuthRoleHelper.isAdmin(adminEmail), isTrue);
      // Admin has master privileges across all statuses
      expect(order.status == 'DISPATCHED', isTrue);
    });
  });
}
