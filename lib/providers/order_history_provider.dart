import 'package:flutter/foundation.dart';
import '../features/orders/models/sales_order.dart';
import '../services/storage_service.dart';
import '../services/cloud_order_service.dart';

class OrderHistoryProvider extends ChangeNotifier {
  List<SalesOrder> _history = [];
  bool _isLoading = false;

  List<SalesOrder> get history => _history;
  bool get isLoading => _isLoading;

  OrderHistoryProvider({bool autoLoad = true}) {
    if (autoLoad) {
      loadHistory();
    }
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _history = await CloudOrderService.fetchAllOrders();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> pushOrder(SalesOrder order) async {
    _isLoading = true;
    notifyListeners();
    order.status = OrderStatus.pushedToBackOffice;
    order.pushedAt = DateTime.now();
    final success = await CloudOrderService.pushOrderForDispatch(order);
    await loadHistory();
    return success;
  }

  Future<bool> repushOrder(SalesOrder order) async {
    _isLoading = true;
    notifyListeners();
    final success = await CloudOrderService.repushOrder(order);
    await loadHistory();
    return success;
  }

  Future<bool> revertOrder(SalesOrder order, String reason) async {
    _isLoading = true;
    notifyListeners();
    final success = await CloudOrderService.revertOrderToRep(order, reason);
    await loadHistory();
    return success;
  }

  Future<bool> markDispatched(SalesOrder order) async {
    _isLoading = true;
    notifyListeners();
    final success = await CloudOrderService.markOrderDispatched(order);
    await loadHistory();
    return success;
  }

  Future<bool> pushToDispatch(SalesOrder order) async {
    _isLoading = true;
    notifyListeners();
    final success = await CloudOrderService.pushToDispatchTeam(order);
    await loadHistory();
    return success;
  }

  Future<void> deleteOrder(int index) async {
    if (index >= 0 && index < _history.length) {
      final order = _history[index];
      await CloudOrderService.deleteOrder(order, index);
      _history.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    await StorageService.clearHistory();
    _history.clear();
    notifyListeners();
  }

  /// Sets orders in memory (primarily for unit testing and offline previews)
  void setOrders(List<SalesOrder> orders) {
    _history = List.from(orders);
    notifyListeners();
  }
}
