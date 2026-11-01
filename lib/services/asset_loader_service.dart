import 'dart:convert';
import 'package:flutter/services.dart';
import '../features/catalog/models/product.dart';
import '../features/catalog/models/dropdown_lists.dart';

class AssetLoaderService {
  static Future<List<Product>> loadProducts() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/products.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => Product.fromJson(j)).toList();
    } catch (e) {
      // Fallback if asset load fails
      return [];
    }
  }

  static Future<DropdownLists> loadDropdownLists() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/lists.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return DropdownLists.fromJson(jsonMap);
    } catch (e) {
      return DropdownLists.defaultLists();
    }
  }
}
