import 'package:flutter/foundation.dart';
import '../features/catalog/models/product.dart';
import '../services/asset_loader_service.dart';

class CatalogProvider extends ChangeNotifier {
  List<Product> _allProducts = [];
  bool _isLoading = true;

  String _selectedGroup = 'All';
  String _selectedDn = 'All';
  String _selectedType = 'All';
  String _searchQuery = '';

  List<Product> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String get selectedGroup => _selectedGroup;
  String get selectedDn => _selectedDn;
  String get selectedType => _selectedType;
  String get searchQuery => _searchQuery;

  static const List<String> groupList = [
    'All',
    'HT Pro',
    'Ultra Silent',
    'MLCP / PERT',
    'PPR / Heliroma',
    'Red Fire / SS',
    'Accessories',
  ];

  static const List<String> allTypesList = [
    'All',
    'Pipe',
    'Bend',
    'Tee',
    'Reducer',
    'Trap',
    'Clamp',
    'Flange',
    'End Cap',
    'Inspection',
    'Valve',
    'Coupler',
    'Fitting',
    'Tools',
  ];

  CatalogProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _allProducts = await AssetLoaderService.loadProducts();
    _isLoading = false;
    notifyListeners();
  }

  void setGroup(String group) {
    if (_selectedGroup != group) {
      _selectedGroup = group;
      _selectedDn = 'All';
      _selectedType = 'All';
      notifyListeners();
    }
  }

  void setDn(String dn) {
    if (_selectedDn != dn) {
      _selectedDn = dn;
      notifyListeners();
    }
  }

  void setType(String type) {
    if (_selectedType != type) {
      _selectedType = type;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  @visibleForTesting
  void setProducts(List<Product> products) {
    _allProducts = products;
    _isLoading = false;
    notifyListeners();
  }

  // Base products matching only group
  List<Product> get _groupFiltered {
    if (_selectedGroup == 'All') return _allProducts;
    return _allProducts.where((p) => p.family == _selectedGroup).toList();
  }

  // DN size counts for current group
  Map<String, int> get dnCounts {
    final map = <String, int>{};
    for (final p in _groupFiltered) {
      final dn = p.normalizedDn;
      if (dn != null) {
        final key = dn.toString();
        map[key] = (map[key] ?? 0) + 1;
      }
    }
    return map;
  }

  // Sorted list of available DNs
  List<MapEntry<String, int>> get sortedDnList {
    final entries = dnCounts.entries.toList();
    entries.sort((a, b) {
      final numA = int.tryParse(a.key) ?? 0;
      final numB = int.tryParse(b.key) ?? 0;
      return numA.compareTo(numB);
    });
    return entries;
  }

  // Base products matching group + DN
  List<Product> get _groupAndDnFiltered {
    var list = _groupFiltered;
    if (_selectedDn != 'All') {
      final targetDn = int.tryParse(_selectedDn);
      if (targetDn != null) {
        list = list.where((p) => p.normalizedDn == targetDn).toList();
      }
    }
    return list;
  }

  // Type counts for current group + DN
  Map<String, int> get typeCounts {
    final map = <String, int>{};
    for (final p in _groupAndDnFiltered) {
      final k = p.kind;
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  // Final filtered list of products
  List<Product> get filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    return _groupAndDnFiltered.where((p) {
      // Check type
      if (_selectedType != 'All' && p.kind != _selectedType) {
        return false;
      }
      // Check search query
      if (query.isNotEmpty) {
        final matchCode = p.itemCode.toLowerCase().contains(query);
        final matchDesc = p.description.toLowerCase().contains(query);
        final matchDn = p.dn?.toString().toLowerCase().contains(query) ?? false;
        final matchSub = p.subGroup.toLowerCase().contains(query);
        final matchCat = p.category.toLowerCase().contains(query);
        if (!matchCode && !matchDesc && !matchDn && !matchSub && !matchCat) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
