import 'package:flutter_test/flutter_test.dart';
import 'package:huliot_so_flutter/models/cart_item.dart';
import 'package:huliot_so_flutter/models/sales_order.dart';

void main() {
  group('SalesOrder & CartItem Financial Integrity Tests', () {
    test('Standard price and discount calculation produces accurate totals', () {
      final item = CartItem(
        itemCode: 'ITEM001',
        description: 'Test Pipe',
        listPrice: 1000.0,
        discount: 0.50, // 50% discount -> net = 500
        cashDiscount: 0.10, // 10% additional -> net = 450
        qty: 2,
      );

      // (1 - ( (1 - 0.5) * (1 - 0.1) )) = 1 - (0.5 * 0.9) = 1 - 0.45 = 0.55 net discount
      // unit price = 1000 * (1 - 0.55) = 450.0
      expect(item.unitPrice, closeTo(450.0, 0.001));
      expect(item.amount, closeTo(900.0, 0.001));

      final order = SalesOrder(
        items: [item],
      );

      expect(order.subtotal, closeTo(900.0, 0.001));
      expect(order.gst, closeTo(162.0, 0.001)); // 18% of 900 = 162
      expect(order.grandTotal, closeTo(1062.0, 0.001));
    });

    test('Zero items in order handles totals safely without NaN or division by zero', () {
      final emptyOrder = SalesOrder(items: []);
      expect(emptyOrder.subtotal, equals(0.0));
      expect(emptyOrder.gst, equals(0.0));
      expect(emptyOrder.grandTotal, equals(0.0));
      expect(emptyOrder.totalQty, equals(0));
    });

    test('SECURITY CHECK: Negative quantity injection should not result in negative subtotal', () {
      // Adversarial test: User tampers with item payload to inject negative quantity
      final maliciousItem = CartItem(
        itemCode: 'EXPLOIT01',
        description: 'Negative Qty Exploit',
        listPrice: 1000.0,
        qty: -10, // Exploit: steals 10 items or reduces billing balance
      );

      final order = SalesOrder(items: [maliciousItem]);
      // A secure system must not allow negative total
      expect(
        order.subtotal >= 0,
        isTrue,
        reason: 'Financial Vulnerability: Order subtotal allowed negative balance of ${order.subtotal}',
      );
    });

    test('SECURITY CHECK: Excessive discount (> 100%) should not invert price into negative credit', () {
      final exploitItem = CartItem(
        itemCode: 'DISC_EXPLOIT',
        description: 'Over 100% discount',
        listPrice: 1000.0,
        discount: 1.5, // 150% discount
        qty: 1,
      );

      expect(
        exploitItem.unitPrice >= 0,
        isTrue,
        reason: 'Financial Vulnerability: Unit price is negative: ${exploitItem.unitPrice}',
      );
    });

    test('Serialization round-trip preserves all workflow timestamps and status fields', () {
      final original = SalesOrder(
        salesOrderNo: 'SO-TEST-2026',
        status: 'READY_FOR_DISPATCH',
        pushedAt: DateTime(2026, 10, 27, 10, 0),
        dispatchPushedAt: DateTime(2026, 10, 27, 11, 30),
        dispatchedAt: DateTime(2026, 10, 27, 12, 0),
        revertReason: 'Check billing address',
      );

      final json = original.toJson();
      final deserialized = SalesOrder.fromJson(json);

      expect(deserialized.salesOrderNo, equals('SO-TEST-2026'));
      expect(deserialized.status, equals('READY_FOR_DISPATCH'));
      expect(deserialized.revertReason, equals('Check billing address'));
      expect(deserialized.dispatchPushedAt, isNotNull);
      expect(deserialized.dispatchedAt, isNotNull);
    });
  });
}
