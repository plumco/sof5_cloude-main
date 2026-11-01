// File: test/unit/offline_save_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huliot_so_flutter/features/orders/models/order_model.dart';
import 'package:huliot_so_flutter/features/orders/models/cart_item.dart';
import 'package:huliot_so_flutter/features/orders/providers/sales_order.dart';
import 'package:huliot_so_flutter/services/cloud_order_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Mock connectivity method channel to simulate offline instantly without hanging
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/connectivity'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return <String>['none']; // Offline state
      }
      return null;
    },
  );

  group('Offline Save & Network Resilience Suite', () {
    late SalesOrder testOrder;

    setUp(() {
      testOrder = SalesOrder(
        salesOrderNo: 'SO-TEST-OFFLINE-001',
        customerName: 'Test Offline Builders',
        items: [
          CartItem(
            itemCode: 'HPF-TEST-001',
            description: 'Test HT Pro Bend 50mm 45°',
            qty: 5,
            listPrice: 150.0,
          ),
        ],
      );
    });

    test('isSaving state toggles accurately during saveOrder', () async {
      final provider = SalesOrderProvider();
      provider.loadOrder(testOrder);

      expect(provider.isSaving, isFalse);
      expect(provider.isRepushing, isFalse);
      expect(provider.isClearing, isFalse);

      final future = provider.saveOrder();
      // Should be saving immediately
      expect(provider.isSaving, isTrue);

      final result = await future;
      // After completion, isSaving resets to false
      expect(provider.isSaving, isFalse);
      expect(result.isLocalSaved, isTrue);
    });

    test('Offline save returns localOnly and warns user instead of false cloud success', () async {
      final provider = SalesOrderProvider();
      provider.loadOrder(testOrder);

      // Save order without live firebase connection
      final result = await provider.saveOrder();

      expect(result.isLocalSaved, isTrue);
      // Without live cloud connection in unit tests, isCloudSynced is false
      expect(result.isCloudSynced, isFalse);
    });

    testWidgets('Save button shows warning snackbar with Retry when cloud is unreachable', (tester) async {
      final provider = SalesOrderProvider();
      provider.loadOrder(testOrder);

      BuildContext? testContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Text('Test Container');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger saveOrder with context
      await provider.saveOrder(context: testContext);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should show warning snackbar, NOT false success
      expect(find.text('⚠️ Saved locally only. Will sync when online.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('✅ Order synced to Cloud'), findsNothing);
      expect(find.textContaining('Order saved to History successfully!'), findsNothing);

      // Drain snackbar auto-dismiss timer so test completes cleanly
      await tester.pump(const Duration(seconds: 7));
    });
  });
}
