import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/orders/models/sales_order.dart';

class StorageService {
  static const String _draftKey = 'hpf_sales_order_draft';
  static const String _historyKey = 'hpf_order_history';

  static Future<bool> saveDraft(SalesOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(order.toJson());
    return await prefs.setString(_draftKey, jsonString);
  }

  static Future<SalesOrder?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_draftKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        return SalesOrder.fromJson(jsonMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<bool> saveOrderToHistory(SalesOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadOrderHistory();
    
    // Check if order already exists in history
    final existingIndex = history.indexWhere((o) =>
        (order.firestoreId.isNotEmpty && o.firestoreId == order.firestoreId) ||
        (order.salesOrderNo.isNotEmpty && o.salesOrderNo == order.salesOrderNo));

    order.savedAt ??= DateTime.now();

    if (existingIndex >= 0) {
      history[existingIndex] = order;
    } else {
      history.insert(0, order);
    }

    // Keep max 50 orders
    final trimmed = history.take(50).map((o) => o.toJson()).toList();
    return await prefs.setString(_historyKey, json.encode(trimmed));
  }

  static Future<List<SalesOrder>> loadOrderHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(jsonString);
        return list.map((item) => SalesOrder.fromJson(item)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  static Future<bool> deleteOrderFromHistory(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadOrderHistory();
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      final jsonList = history.map((o) => o.toJson()).toList();
      return await prefs.setString(_historyKey, json.encode(jsonList));
    }
    return false;
  }

  static Future<bool> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_historyKey);
  }
}
