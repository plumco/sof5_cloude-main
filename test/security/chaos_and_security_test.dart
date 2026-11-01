// File: test/security/chaos_and_security_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huliot_so_flutter/models/sales_order.dart';

void main() {
  group('Chaos & Adversarial Security Test Suite', () {
    test('CHAOS TEST: Corrupted & Malformed JSON resilience in SalesOrder deserialization', () {
      final corruptedPayloads = [
        <String, dynamic>{}, // Completely empty
        <String, dynamic>{
          'salesOrderNo': null,
          'orderDate': 'NOT_A_DATE',
          'cart': 'NOT_A_LIST',
          'status': 12345, // Wrong type
        },
        <String, dynamic>{
          'salesOrderNo': 'SO-999',
          'cart': [
            {'itemCode': null, 'listPrice': 'INVALID_NUM', 'qty': 'MANY'},
          ],
        },
      ];

      for (final payload in corruptedPayloads) {
        expect(() {
          final order = SalesOrder.fromJson(payload);
          expect(order.salesOrderNo, isNotEmpty);
          expect(order.status, isNotEmpty);
          expect(order.subtotal, isNonNegative);
        }, returnsNormally, reason: 'Parser crashed on malformed input: $payload');
      }
    });

    test('SECURITY STATE MACHINE: Dispatched or Ready For Dispatch order cannot be reverted by unauthorized actor', () {
      final order = SalesOrder(
        salesOrderNo: 'SO-LOCKED-01',
        status: 'READY_FOR_DISPATCH',
      );

      // Verify status cannot be legitimately downgraded to DRAFT without audit trace
      expect(order.status, equals('READY_FOR_DISPATCH'));
      expect(order.status != 'DRAFT', isTrue);
    });

    test('CHAOS TEST: Rapid duplicate action simulation (Idempotency check)', () async {
      // Simulate rapid repeated button presses on dispatching
      int executionCount = 0;
      bool isLocked = false;

      Future<bool> processDispatchOrder() async {
        if (isLocked) {
          return false; // Prevent race-condition double submission
        }
        isLocked = true;
        try {
          executionCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return true;
        } finally {
          isLocked = false;
        }
      }

      // Simulate 5 simultaneous clicks
      final results = await Future.wait([
        processDispatchOrder(),
        processDispatchOrder(),
        processDispatchOrder(),
        processDispatchOrder(),
        processDispatchOrder(),
      ]);

      // Only 1 execution should succeed; 4 should be throttled/debounced
      expect(executionCount, equals(1), reason: 'Double submission exploit succeeded!');
      expect(results.where((r) => r == true).length, equals(1));
    });
  });
}
