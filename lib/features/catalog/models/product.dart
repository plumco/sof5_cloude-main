// File: lib/features/catalog/models/product.dart

class Product {
  final String itemCode;
  final String description;
  final dynamic dn;
  final int moq;
  final double listPrice;
  final String category;
  final String subGroup;
  final dynamic hsn;
  final double gst;
  final String type;

  Product({
    required this.itemCode,
    required this.description,
    this.dn,
    this.moq = 1,
    required this.listPrice,
    this.category = '',
    this.subGroup = '',
    this.hsn = '',
    this.gst = 0.18,
    this.type = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      itemCode: json['itemCode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dn: json['dn'],
      moq: (json['moq'] is num) ? (json['moq'] as num).toInt() : 1,
      listPrice: (json['listPrice'] is num) ? (json['listPrice'] as num).toDouble() : 0.0,
      category: json['category']?.toString() ?? '',
      subGroup: json['subGroup']?.toString() ?? '',
      hsn: json['hsn']?.toString() ?? '',
      gst: (json['gst'] is num) ? (json['gst'] as num).toDouble() : 0.18,
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'itemCode': itemCode,
    'description': description,
    'dn': dn,
    'moq': moq,
    'listPrice': listPrice,
    'category': category,
    'subGroup': subGroup,
    'hsn': hsn,
    'gst': gst,
    'type': type,
  };

  String get family {
    final s = '$type $category $subGroup $description'.toUpperCase();
    if (s.contains('ULTRA') || s.contains(' US ')) return 'Ultra Silent';
    if (s.contains('RED FIRE') ||
        s.contains('STAINLESS') ||
        s.contains('INOX') ||
        s.contains('FITTINGS-SS') ||
        s.contains('-SS')) {
      return 'Red Fire / SS';
    }
    if (s.contains('MLCP') ||
        s.contains('PERT') ||
        s.contains('PEX') ||
        s.contains('PRESS')) {
      return 'MLCP / PERT';
    }
    if (s.contains('PPR') ||
        s.contains('HELIROMA') ||
        s.contains('PP-R')) {
      return 'PPR / Heliroma';
    }
    if (s.contains('HT PRO') ||
        s.contains('HTPRO') ||
        s.contains('MFD PIPES INDIA-HT')) {
      return 'HT Pro';
    }
    return 'Accessories';
  }

  String get kind {
    final s = '$subGroup $category $description'.toUpperCase();
    if (s.contains('PIPE')) return 'Pipe';
    if (s.contains('BEND')) return 'Bend';
    if (s.contains('TEE')) return 'Tee';
    if (s.contains('REDUC')) return 'Reducer';
    if (s.contains('TRAP')) return 'Trap';
    if (s.contains('CLAMP')) return 'Clamp';
    if (s.contains('FLANGE')) return 'Flange';
    if (s.contains('END CAP') || s.contains('CAP')) return 'End Cap';
    if (s.contains('INSPECTION')) return 'Inspection';
    if (s.contains('VALVE')) return 'Valve';
    if (s.contains('COUPLER') || s.contains('COUPLING')) return 'Coupler';
    if (s.contains('TOOL') || s.contains('JAW') || s.contains('CALIBRATOR')) return 'Tools';
    return 'Fitting';
  }

  int? get normalizedDn {
    if (dn == null) return null;
    final str = dn.toString().trim();
    final match = RegExp(r'\d+').firstMatch(str);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return null;
  }

  double calculateNetPrice(double discountPercent) {
    return listPrice * (1.0 - (discountPercent / 100.0));
  }
}

