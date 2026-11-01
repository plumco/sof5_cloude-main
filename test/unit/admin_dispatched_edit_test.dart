// File: test/unit/admin_dispatched_edit_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huliot_so_flutter/features/orders/models/order_model.dart';
import 'package:huliot_so_flutter/features/orders/models/cart_item.dart';
import 'package:huliot_so_flutter/features/catalog/models/product.dart';
import 'package:huliot_so_flutter/features/orders/providers/cart_provider.dart';
import 'package:huliot_so_flutter/providers/catalog_provider.dart';
import 'package:huliot_so_flutter/features/catalog/screens/catalog_view.dart';
import 'package:huliot_so_flutter/providers/order_history_provider.dart';
import 'package:huliot_so_flutter/widgets/views/order_history_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Dispatched Order Edit & Audit Trail Protection Suite', () {
    late SalesOrder dispatchedOrder;
    late Product sampleProduct;

    setUp(() {
      sampleProduct = Product(
        itemCode: 'HPF-TEST-001',
        description: 'Test HT Pro Bend 50mm 45°',
        listPrice: 150.0,
      );

      dispatchedOrder = SalesOrder(
        salesOrderNo: 'SO-2026-0001',
        status: OrderStatus.dispatched,
        items: [
          CartItem(
            itemCode: 'HPF-TEST-001',
            description: 'Test HT Pro Bend 50mm 45°',
            qty: 2,
            listPrice: 150.0,
          ),
        ],
      );
    });

    test('Dispatched order should not be editable by Sales role', () {
      // 1. Role permission matrix checks
      expect(canEditOrder(dispatchedOrder, 'sales'), isFalse);
      expect(canEditOrder(dispatchedOrder, 'dispatch'), isFalse);
      expect(canEditOrder(dispatchedOrder, 'backoffice'), isFalse);

      // Delivered and Cancelled orders are also protected against non-admin
      final deliveredOrder = SalesOrder(status: OrderStatus.delivered);
      final cancelledOrder = SalesOrder(status: OrderStatus.cancelled);
      expect(canEditOrder(deliveredOrder, 'sales'), isFalse);
      expect(canEditOrder(cancelledOrder, 'sales'), isFalse);

      // Draft orders remain editable by anyone
      final draftOrder = SalesOrder(status: OrderStatus.draft);
      expect(canEditOrder(draftOrder, 'sales'), isTrue);

      // 2. Cart mutation protection check
      final cartProvider = SalesOrderProvider();
      cartProvider.loadOrder(dispatchedOrder);

      expect(cartProvider.canEditCart('sales'), isFalse);

      final added = cartProvider.addItemFromCatalog(sampleProduct, 5, 52.0, userRole: 'sales');
      expect(added, isFalse);
      expect(cartProvider.cart.length, equals(1)); // Items untouched

      final removed = cartProvider.removeItem(0, userRole: 'sales');
      expect(removed, isFalse);
      expect(cartProvider.cart.length, equals(1)); // Item not removed
    });

    test('Dispatched order should be editable by Admin role with reason', () {
      // 1. Admin permission check
      expect(canEditOrder(dispatchedOrder, 'admin'), isTrue);
      expect(canEditOrder(dispatchedOrder, 'ADMIN'), isTrue);

      final cartProvider = SalesOrderProvider();
      cartProvider.loadOrder(dispatchedOrder);

      expect(cartProvider.canEditCart('admin'), isTrue);

      // Admin loads order with explicit reason
      const reason = 'Client site engineer requested emergency size substitution before loading';
      cartProvider.loadAdminEditedDispatchedOrder(
        dispatchedOrder,
        reason: reason,
        adminEmail: 'admin@so.com',
      );

      expect(cartProvider.order.isAdminEdited, isTrue);
      expect(cartProvider.order.adminEditReason, equals(reason));
      expect(cartProvider.adminEditingBannerText, contains('🔓 Admin Editing Dispatched Order: SO-2026-0001'));
      expect(cartProvider.adminEditingBannerText, contains(reason));

      // Admin can successfully add item
      final added = cartProvider.addItemFromCatalog(sampleProduct, 3, 50.0, userRole: 'admin');
      expect(added, isTrue);
      expect(cartProvider.cart.first.qty, equals(5)); // 2 + 3 pcs
    });

    test('Admin edit should create audit log', () {
      const adminEmail = 'admin@huliot.com';
      const reason = 'Audit revision: customer requested urgent quantity change';

      dispatchedOrder.recordAdminEdit(email: adminEmail, reason: reason);

      expect(dispatchedOrder.isAdminEdited, isTrue);
      expect(dispatchedOrder.lastEditedBy, equals(adminEmail));
      expect(dispatchedOrder.lastEditedAt, isNotNull);
      expect(dispatchedOrder.adminEditReason, equals(reason));
      expect(dispatchedOrder.adminEditLog, contains('Edited by admin@huliot.com'));
      expect(dispatchedOrder.adminEditLog, contains(reason));

      expect(dispatchedOrder.editHistory.length, equals(1));
      final historyEntry = dispatchedOrder.editHistory.first;
      expect(historyEntry['editedBy'], equals(adminEmail));
      expect(historyEntry['reason'], equals(reason));
      expect(historyEntry['oldStatus'], equals('DISPATCHED'));
      expect(historyEntry['oldItems'], isA<List<dynamic>>());

      // Verify serialization round-trip retains audit trail
      final json = dispatchedOrder.toJson();
      expect(json['isAdminEdited'], isTrue);
      expect(json['lastEditedBy'], equals(adminEmail));
      expect(json['adminEditReason'], equals(reason));
      expect(json['editHistory'], isNotEmpty);

      final deserialized = SalesOrder.fromJson(json);
      expect(deserialized.isAdminEdited, isTrue);
      expect(deserialized.lastEditedBy, equals(adminEmail));
      expect(deserialized.adminEditReason, equals(reason));
      expect(deserialized.editHistory.length, equals(1));
    });

    testWidgets('Dispatched order loaded + Catalog Add should show error message instead of fake success', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = SalesOrderProvider();
      cartProvider.loadOrder(dispatchedOrder);

      final catalogProvider = CatalogProvider();
      catalogProvider.setProducts([sampleProduct]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CatalogProvider>.value(value: catalogProvider),
            ChangeNotifierProvider<SalesOrderProvider>.value(value: cartProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CatalogView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the "+ Add" button
      final addBtn = find.widgetWithText(ElevatedButton, '+ Add').first;
      expect(addBtn, findsOneWidget);

      await tester.ensureVisible(addBtn);
      await tester.pumpAndSettle();
      await tester.tap(addBtn);
      await tester.pump();

      // Critical check: Error snackbar MUST be shown
      expect(find.text('❌ Cannot edit Dispatched order. Contact Admin'), findsOneWidget);
      // Critical check: Fake success message MUST NOT be shown
      expect(find.textContaining('Added HPF-TEST-001'), findsNothing);
    });

    testWidgets('Order History Load prompts confirmation dialog when active cart has items', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = SalesOrderProvider();
      cartProvider.addItemFromCatalog(sampleProduct, 2, 50.0);
      expect(cartProvider.cart.isNotEmpty, isTrue);

      final historyProvider = OrderHistoryProvider(autoLoad: false);
      final testOrder = SalesOrder(
        salesOrderNo: 'SO-2026-9999',
        status: OrderStatus.draft,
        items: [
          CartItem(
            itemCode: 'HPF-TEST-002',
            description: 'Test Pipe 110mm',
            qty: 1,
            listPrice: 500.0,
          ),
        ],
      );
      historyProvider.setOrders([testOrder]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SalesOrderProvider>.value(value: cartProvider),
            ChangeNotifierProvider<OrderHistoryProvider>.value(value: historyProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OrderHistoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final loadBtn = find.widgetWithText(ElevatedButton, 'Load').first;
      expect(loadBtn, findsOneWidget);

      await tester.tap(loadBtn);
      await tester.pumpAndSettle();

      // Verify Overwrite Confirmation Dialog opens
      expect(find.text('Overwrite Current Cart?'), findsOneWidget);
      expect(find.textContaining('Current cart has 1 items. Clear and load SO-2026-9999?'), findsOneWidget);

      // Cancel dialog
      final cancelBtn = find.widgetWithText(TextButton, 'Cancel');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Cart remains unchanged
      expect(cartProvider.cart.first.itemCode, equals('HPF-TEST-001'));
    });

    testWidgets('Order History Load confirm clears and loads order into active form', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = SalesOrderProvider();
      cartProvider.addItemFromCatalog(sampleProduct, 2, 50.0);
      expect(cartProvider.cart.length, equals(1));

      final historyProvider = OrderHistoryProvider(autoLoad: false);
      final testOrder = SalesOrder(
        salesOrderNo: 'SO-2026-9999',
        status: OrderStatus.draft,
        items: [
          CartItem(
            itemCode: 'HPF-TEST-002',
            description: 'Test Pipe 110mm',
            qty: 4,
            listPrice: 500.0,
          ),
        ],
      );
      historyProvider.setOrders([testOrder]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SalesOrderProvider>.value(value: cartProvider),
            ChangeNotifierProvider<OrderHistoryProvider>.value(value: historyProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OrderHistoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final loadBtn = find.widgetWithText(ElevatedButton, 'Load').first;
      await tester.tap(loadBtn);
      await tester.pumpAndSettle();

      // Tap "Clear & Load"
      final clearAndLoadBtn = find.widgetWithText(ElevatedButton, 'Clear & Load');
      expect(clearAndLoadBtn, findsOneWidget);
      await tester.tap(clearAndLoadBtn);
      await tester.pumpAndSettle();

      // Cart loaded with testOrder item
      expect(cartProvider.cart.length, equals(1));
      expect(cartProvider.cart.first.itemCode, equals('HPF-TEST-002'));
      expect(find.text('Loaded SO-2026-9999 into active form'), findsOneWidget);
    });

    test('Pushed to Back Office order should not be editable by Sales role, but editable by Back Office and Admin', () {
      final pushedOrder = SalesOrder(
        salesOrderNo: 'SO-2026-0001',
        status: OrderStatus.pushedToBackOffice,
        items: [
          CartItem(
            itemCode: 'HPF-TEST-001',
            description: 'Test HT Pro Bend 50mm 45°',
            qty: 1,
            listPrice: 150.0,
          ),
        ],
      );

      // 1. Role permission matrix
      expect(canEditOrder(pushedOrder, 'sales'), isFalse);
      expect(canEditOrder(pushedOrder, 'dispatch'), isFalse);
      expect(canEditOrder(pushedOrder, 'backoffice'), isTrue);
      expect(canEditOrder(pushedOrder, 'admin'), isTrue);

      // Also check 'inReview' and 'pushed'
      final inReviewOrder = SalesOrder(status: OrderStatus.inReview);
      expect(canEditOrder(inReviewOrder, 'sales'), isFalse);
      expect(canEditOrder(inReviewOrder, 'backoffice'), isTrue);

      // 2. Cart mutation protection check
      final cartProvider = SalesOrderProvider();
      cartProvider.loadOrder(pushedOrder);
      expect(cartProvider.canEditCart('sales'), isFalse);

      final added = cartProvider.addItemFromCatalog(sampleProduct, 5, 52.0, userRole: 'sales');
      expect(added, isFalse);
      expect(cartProvider.cart.first.qty, equals(1)); // Untouched, quantity cannot change from 1 to 6
    });

    test('pushToBackOffice updates order status to pushedToBackOffice and clears active cart', () async {
      final cartProvider = SalesOrderProvider();
      cartProvider.addItemFromCatalog(sampleProduct, 1, 50.0);
      expect(cartProvider.cart.length, equals(1));
      expect(cartProvider.order.status, equals(OrderStatus.draft));

      // Push to back office
      await cartProvider.pushToBackOffice();

      // Status updated and cart cleared
      expect(cartProvider.order.status, equals(OrderStatus.pushedToBackOffice));
      expect(cartProvider.cart, isEmpty);
    });

    testWidgets('Draft -> Push -> Status Pushed -> Sales Load shows View (In Review) and opens Read-Only Dialog', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = SalesOrderProvider();
      final historyProvider = OrderHistoryProvider(autoLoad: false);

      final pushedOrder = SalesOrder(
        salesOrderNo: 'SO-2026-0001',
        status: OrderStatus.pushedToBackOffice,
        items: [
          CartItem(
            itemCode: 'HPF-TEST-001',
            description: 'Test HT Pro Bend 50mm 45°',
            qty: 1,
            listPrice: 150.0,
          ),
        ],
      );
      historyProvider.setOrders([pushedOrder]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SalesOrderProvider>.value(value: cartProvider),
            ChangeNotifierProvider<OrderHistoryProvider>.value(value: historyProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OrderHistoryView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Status Badge
      expect(find.text('Pushed to Back Office'), findsOneWidget);

      // Verify Button says "View (In Review)" instead of "Load"
      expect(find.widgetWithText(ElevatedButton, 'View (In Review)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Load'), findsNothing);

      // Click "View (In Review)"
      final viewBtn = find.widgetWithText(ElevatedButton, 'View (In Review)').first;
      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      // Read-Only Dialog MUST open
      expect(find.text('Order Details: SO-2026-0001'), findsOneWidget);
      expect(find.textContaining('Pushed to Back Office - in review'), findsOneWidget);

      // Active cart MUST remain empty (Sales cannot load it to change quantity 1 to 6)
      expect(cartProvider.cart, isEmpty);
    });
  });
}
