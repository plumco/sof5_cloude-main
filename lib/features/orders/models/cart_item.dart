// File: lib/features/orders/models/cart_item.dart

class CartItem {
  final String itemCode;
  final String description;
  final dynamic dn;
  final String category;
  final String subGroup;
  final dynamic hsn;
  final int moq;
  int qty;
  final double listPrice;
  double discount; // 0.0 to 1.0 (e.g. 0.52 for 52%)
  double cashDiscount; // 0.0 to 1.0
  double unitPrice;
  double amount;
  String location;

  CartItem({
    required this.itemCode,
    required this.description,
    this.dn,
    this.category = '',
    this.subGroup = '',
    this.hsn = '',
    this.moq = 1,
    int qty = 1,
    required this.listPrice,
    double discount = 0.52,
    double cashDiscount = 0.0,
    this.location = 'NA',
    double? unitPrice,
    double? amount,
  })  : qty = qty < 0 ? 0 : qty,
        discount = discount.clamp(0.0, 1.0),
        cashDiscount = cashDiscount.clamp(0.0, 1.0),
        unitPrice = (unitPrice ?? _calcUnitPrice(listPrice, discount, cashDiscount)).clamp(0.0, double.infinity),
        amount = (amount ?? (_calcUnitPrice(listPrice, discount, cashDiscount) * (qty < 0 ? 0 : qty))).clamp(0.0, double.infinity);

  static double _calcUnitPrice(double listPrice, double discount, double cashDiscount) {
    final d = discount.clamp(0.0, 1.0);
    final cd = cashDiscount.clamp(0.0, 1.0);
    final netDiscount = 1.0 - ((1.0 - d) * (1.0 - cd));
    final calculated = listPrice * (1.0 - netDiscount);
    return calculated < 0.0 ? 0.0 : calculated;
  }

  void recalculate() {
    if (qty < 0) qty = 0;
    discount = discount.clamp(0.0, 1.0);
    cashDiscount = cashDiscount.clamp(0.0, 1.0);
    unitPrice = _calcUnitPrice(listPrice, discount, cashDiscount);
    amount = (unitPrice * qty).clamp(0.0, double.infinity);
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemCode: json['itemCode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dn: json['dn'],
      category: json['category']?.toString() ?? '',
      subGroup: json['subGroup']?.toString() ?? '',
      hsn: json['hsn']?.toString() ?? '',
      moq: (json['moq'] is num) ? (json['moq'] as num).toInt() : 1,
      qty: (json['qty'] is num) ? (json['qty'] as num).toInt() : 1,
      listPrice: (json['listPrice'] is num) ? (json['listPrice'] as num).toDouble() : 0.0,
      discount: (json['discount'] is num) ? (json['discount'] as num).toDouble() : 0.0,
      cashDiscount: (json['cashDiscount'] is num) ? (json['cashDiscount'] as num).toDouble() : 0.0,
      location: json['location']?.toString() ?? 'NA',
      unitPrice: (json['unitPrice'] is num) ? (json['unitPrice'] as num).toDouble() : null,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'itemCode': itemCode,
    'description': description,
    'dn': dn,
    'category': category,
    'subGroup': subGroup,
    'hsn': hsn,
    'moq': moq,
    'qty': qty,
    'listPrice': listPrice,
    'discount': discount,
    'cashDiscount': cashDiscount,
    'location': location,
    'unitPrice': unitPrice,
    'amount': amount,
  };
}

