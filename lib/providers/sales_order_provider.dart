import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/orders/models/sales_order.dart';
import '../features/orders/models/cart_item.dart';
import '../features/catalog/models/product.dart';
import '../features/catalog/models/dropdown_lists.dart';
import '../services/asset_loader_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_export_service.dart';
import '../services/excel_export_service.dart';
import '../services/cloud_order_service.dart';
import '../services/auth_role_helper.dart';

class SalesOrderProvider extends ChangeNotifier {
  SalesOrder _order = SalesOrder();
  DropdownLists _dropdownLists = DropdownLists.defaultLists();
  bool _isSidebarVisible = true;
  int _currentTabIndex = 0; // 0: Order Details, 1: Catalog, 2: Cart Summary, 3: Order History

  SalesOrder get order => _order;
  SalesOrder get salesOrder => _order;
  List<CartItem> get cart => _order.items;
  DropdownLists get dropdownLists => _dropdownLists;
  bool get isSidebarVisible => _isSidebarVisible;
  int get currentTabIndex => _currentTabIndex;

  bool _isSaving = false;
  bool _isRepushing = false;
  bool _isClearing = false;

  bool get isSaving => _isSaving;
  bool get isRepushing => _isRepushing;
  bool get isClearing => _isClearing;

  double get subtotal => _order.subtotal;
  double get gst => _order.gst;
  double get grandTotal => _order.grandTotal;
  int get totalQty => _order.totalQty;
  int get cartCount => _order.items.length;

  SalesOrderProvider() {
    init();
  }

  Future<void> init() async {
    _dropdownLists = await AssetLoaderService.loadDropdownLists();
    final draft = await StorageService.loadDraft();
    if (draft != null) {
      _order = draft;
    }
    notifyListeners();
  }

  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void toggleSidebar() {
    _isSidebarVisible = !_isSidebarVisible;
    notifyListeners();
  }

  void setSidebarVisible(bool visible) {
    if (_isSidebarVisible != visible) {
      _isSidebarVisible = visible;
      notifyListeners();
    }
  }

  // --- Header Field Updaters ---
  void updateOrderNo(String val) {
    _order.salesOrderNo = val;
    notifyListeners();
  }

  void updateOrderDate(DateTime val) {
    _order.orderDate = val;
    notifyListeners();
  }

  void updateRequiredDate(DateTime val) {
    _order.requiredDate = val;
    notifyListeners();
  }

  void updatePoNo(String val) {
    _order.poNo = val;
    notifyListeners();
  }

  void updateCustomerCode(String val) {
    _order.customerCode = val;
    notifyListeners();
  }

  void updateCustomerName(String val) {
    _order.customerName = val;
    notifyListeners();
  }

  void updateContactPerson(String val) {
    _order.contactPerson = val;
    notifyListeners();
  }

  void updatePhone(String val) {
    _order.phone = val;
    notifyListeners();
  }

  void updateMobile(String val) {
    _order.mobile = val;
    notifyListeners();
  }

  void updateBill1(String val) {
    _order.bill1 = val;
    if (_order.sameBill) _syncBillToShip();
    notifyListeners();
  }

  void updateBill2(String val) {
    _order.bill2 = val;
    if (_order.sameBill) _syncBillToShip();
    notifyListeners();
  }

  void updateBillCity(String val) {
    _order.billCity = val;
    if (_order.sameBill) _syncBillToShip();
    notifyListeners();
  }

  void updateBillProvince(String val) {
    _order.billProvince = val;
    if (_order.sameBill) _syncBillToShip();
    notifyListeners();
  }

  void updateBillZip(String val) {
    _order.billZip = val;
    if (_order.sameBill) _syncBillToShip();
    notifyListeners();
  }

  void updateShip1(String val) {
    _order.ship1 = val;
    if (_order.sameShip) _syncShipToBill();
    notifyListeners();
  }

  void updateShip2(String val) {
    _order.ship2 = val;
    if (_order.sameShip) _syncShipToBill();
    notifyListeners();
  }

  void updateShipCity(String val) {
    _order.shipCity = val;
    if (_order.sameShip) _syncShipToBill();
    notifyListeners();
  }

  void updateShipProvince(String val) {
    _order.shipProvince = val;
    if (_order.sameShip) _syncShipToBill();
    notifyListeners();
  }

  void updateShipZip(String val) {
    _order.shipZip = val;
    if (_order.sameShip) _syncShipToBill();
    notifyListeners();
  }

  void setSameBill(bool val) {
    _order.sameBill = val;
    if (val) {
      _order.sameShip = false;
      _syncBillToShip();
    }
    notifyListeners();
  }

  void setSameShip(bool val) {
    _order.sameShip = val;
    if (val) {
      _order.sameBill = false;
      _syncShipToBill();
    }
    notifyListeners();
  }

  void _syncBillToShip() {
    _order.ship1 = _order.bill1;
    _order.ship2 = _order.bill2;
    _order.shipCity = _order.billCity;
    _order.shipProvince = _order.billProvince;
    _order.shipZip = _order.billZip;
  }

  void _syncShipToBill() {
    _order.bill1 = _order.ship1;
    _order.bill2 = _order.ship2;
    _order.billCity = _order.shipCity;
    _order.billProvince = _order.shipProvince;
    _order.billZip = _order.shipZip;
  }

  void updatePaymentTerms(String val) {
    _order.paymentTerms = val;
    notifyListeners();
  }

  void updateSalesPerson(String val) {
    _order.salesPerson = val;
    notifyListeners();
  }

  void updateDeliveryTerm(String val) {
    _order.deliveryTerm = val;
    notifyListeners();
  }

  void updateProjectName(String val) {
    _order.projectName = val;
    notifyListeners();
  }

  void updateRemarks(String val) {
    _order.remarks = val;
    notifyListeners();
  }

  bool canEditCart([String? userRole]) {
    String role = userRole ?? '';
    if (role.isEmpty) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        role = AuthRoleHelper.isAdmin(user?.email)
            ? 'admin'
            : (AuthRoleHelper.isBackOffice(user?.email)
                ? 'backoffice'
                : (AuthRoleHelper.isDispatch(user?.email) ? 'dispatch' : 'sales'));
      } catch (_) {
        role = 'sales';
      }
    }
    return canEditOrder(_order, role);
  }

  String? get adminEditingBannerText {
    final s = _order.status.toUpperCase().trim();
    if ((s == OrderStatus.dispatched || s == OrderStatus.delivered || s == OrderStatus.cancelled || _order.isAdminEdited) &&
        _order.adminEditReason.isNotEmpty) {
      return '🔓 Admin Editing Dispatched Order: ${_order.salesOrderNo} - Reason: ${_order.adminEditReason}';
    }
    return null;
  }

  // --- Cart Actions ---
  bool addItemFromCatalog(Product p, int qty, double discountPercent, {String location = 'NA', String? userRole, BuildContext? context}) {
    if (!canEditCart(userRole)) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only Admin can edit dispatched orders'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
    final discountFraction = discountPercent / 100.0;
    
    // Check if already in cart for this location
    final existingIndex = _order.items.indexWhere((it) => it.itemCode == p.itemCode && it.location == location);
    if (existingIndex >= 0) {
      _order.items[existingIndex].qty += qty;
      _order.items[existingIndex].discount = discountFraction;
      _order.items[existingIndex].recalculate();
    } else {
      final cartItem = CartItem(
        itemCode: p.itemCode,
        description: p.description,
        dn: p.dn,
        category: p.category,
        subGroup: p.subGroup,
        hsn: p.hsn,
        moq: p.moq,
        qty: qty,
        listPrice: p.listPrice,
        discount: discountFraction,
        cashDiscount: 0.0,
        location: location,
      );
      _order.items.add(cartItem);
    }
    notifyListeners();
    return true;
  }

  bool updateItemQty(int index, int qty, {String? userRole, BuildContext? context}) {
    if (!canEditCart(userRole)) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only Admin can edit dispatched orders'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
    if (index >= 0 && index < _order.items.length) {
      if (qty <= 0) {
        _order.items.removeAt(index);
      } else {
        _order.items[index].qty = qty;
        _order.items[index].recalculate();
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  bool updateItemDiscount(int index, double discountPercent, {String? userRole}) {
    if (!canEditCart(userRole)) return false;
    if (index >= 0 && index < _order.items.length) {
      _order.items[index].discount = discountPercent / 100.0;
      _order.items[index].recalculate();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool applyDiscountToAll(double discountPercent, {String? userRole}) {
    if (!canEditCart(userRole)) return false;
    final double discount = (discountPercent.clamp(0.0, 100.0)) / 100.0;
    for (var item in _order.items) {
      item.discount = discount;
      item.recalculate();
    }
    notifyListeners();
    return true;
  }

  bool removeItem(int index, {String? userRole, BuildContext? context}) {
    if (!canEditCart(userRole)) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only Admin can edit dispatched orders'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
    if (index >= 0 && index < _order.items.length) {
      _order.items.removeAt(index);
      notifyListeners();
      return true;
    }
    return false;
  }

  bool clearCart({String? userRole, BuildContext? context, bool force = false}) {
    if (!force && !canEditCart(userRole)) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only Admin can edit dispatched orders'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
    _isClearing = true;
    notifyListeners();
    try {
      _order.items.clear();
      return true;
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }

  // --- Storage / Export Actions ---
  Future<void> saveDraft() async {
    await StorageService.saveDraft(_order);
  }

  Future<SaveOrderResult> saveOrder({BuildContext? context}) async {
    _isSaving = true;
    notifyListeners();
    try {
      final result = await CloudOrderService.saveOrderWithStatus(_order);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (result.isCloudSynced) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Order synced to Cloud & saved to History!'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        } else if (result.isLocalSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Saved locally only. Will sync when online.'),
              backgroundColor: const Color(0xFFD97706),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  saveOrder(context: context);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to save order: ${result.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return result;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveOrderToHistory({BuildContext? context}) async {
    await saveOrder(context: context);
  }

  bool _isPushingToBackOffice = false;
  bool get isPushingToBackOffice => _isPushingToBackOffice;

  /// Pushes active cart order to Back Office for review:
  /// 1. Updates order status to OrderStatus.pushedToBackOffice
  /// 2. Updates Firestore and local storage
  /// 3. Clears the cart so Sales cannot edit it further
  Future<bool> pushToBackOffice({BuildContext? context}) async {
    _isPushingToBackOffice = true;
    notifyListeners();
    try {
      // 1. Order ka status = OrderStatus.pushedToBackOffice karo (Draft se change)
      _order.status = OrderStatus.pushedToBackOffice;
      _order.pushedAt = DateTime.now();

      // 2. Firestore mein update karo
      final saveRes = await CloudOrderService.saveOrderWithStatus(_order);
      final pushSuccess = await CloudOrderService.pushOrderForDispatch(_order);

      final orderNo = _order.salesOrderNo;

      // 3. Cart clear karo
      clearCart(force: true);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (pushSuccess || saveRes.isCloudSynced || saveRes.isLocalSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order $orderNo pushed to Back Office for review! Cart cleared.'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Push saved locally only. Will sync when online.'),
              backgroundColor: Color(0xFFD97706),
            ),
          );
        }
      }
      return pushSuccess || saveRes.isCloudSynced;
    } finally {
      _isPushingToBackOffice = false;
      notifyListeners();
    }
  }

  Future<bool> repushOrder({BuildContext? context}) async {
    _isRepushing = true;
    notifyListeners();
    try {
      final saveRes = await CloudOrderService.saveOrderWithStatus(_order);
      final pushSuccess = await CloudOrderService.repushOrder(_order);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (pushSuccess && saveRes.isCloudSynced) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${_order.salesOrderNo} re-pushed to Back Office for review!'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Re-push saved locally only. Will sync when online.'),
              backgroundColor: const Color(0xFFD97706),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  repushOrder(context: context);
                },
              ),
            ),
          );
        }
      }
      return pushSuccess;
    } finally {
      _isRepushing = false;
      notifyListeners();
    }
  }

  void loadOrder(SalesOrder order) {
    _order = SalesOrder.fromJson(order.toJson());
    notifyListeners();
  }

  void loadAdminEditedDispatchedOrder(SalesOrder order, {required String reason, required String adminEmail}) {
    _order = SalesOrder.fromJson(order.toJson());
    _order.recordAdminEdit(email: adminEmail, reason: reason);
    notifyListeners();
  }

  Future<void> printSalesOrder() async {
    await PdfExportService.printOrExportSalesOrder(_order);
  }

  Future<void> downloadExcel({String? customFileName}) async {
    await ExcelExportService.generateAndDownloadExcel(_order, customFileName: customFileName);
  }
}
