import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/sales_order_provider.dart';

class BulkDiscountBar extends StatefulWidget {
  final SalesOrderProvider orderProvider;

  const BulkDiscountBar({super.key, required this.orderProvider});

  @override
  State<BulkDiscountBar> createState() => _BulkDiscountBarState();
}

class _BulkDiscountBarState extends State<BulkDiscountBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Default prefill from first item if available, or 52% as standard
    final currentDisc = widget.orderProvider.cart.isNotEmpty
        ? (widget.orderProvider.cart.first.discount * 100).toStringAsFixed(0)
        : '52';
    _controller = TextEditingController(text: currentDisc);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyDiscount() {
    final text = _controller.text.trim();
    final value = double.tryParse(text);

    if (value == null || value < 0 || value > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid discount percentage (0% to 100%)'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _focusNode.unfocus();
    widget.orderProvider.applyDiscountToAll(value);

    final displayVal = value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Applied $displayVal% discount to all ${widget.orderProvider.cart.length} items',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.percent_rounded, size: 15, color: Color(0xFF059669)),
          const SizedBox(width: 6),
          const Text(
            'All Discount:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            height: 32,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF047857),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                suffixText: '%',
                suffixStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF047857),
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF6EE7B7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                ),
              ),
              onSubmitted: (_) => _applyDiscount(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _applyDiscount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Apply All',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper dialog if user clicks DISCOUNT table header
void showBulkDiscountDialog(BuildContext context, SalesOrderProvider orderProvider) {
  final currentDisc = orderProvider.cart.isNotEmpty
      ? (orderProvider.cart.first.discount * 100).toStringAsFixed(0)
      : '52';
  final controller = TextEditingController(text: currentDisc);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: const [
          Icon(Icons.percent_rounded, color: Color(0xFF059669), size: 22),
          SizedBox(width: 8),
          Text('Change All Discounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apply the same discount percentage to all items currently in your cart:',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
            decoration: InputDecoration(
              labelText: 'Discount %',
              suffixText: '%',
              suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
              filled: true,
              fillColor: const Color(0xFFECFDF5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
              ),
            ),
            onSubmitted: (_) {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0 && val <= 100) {
                orderProvider.applyDiscountToAll(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Applied ${val.toStringAsFixed(0)}% discount to all items'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final val = double.tryParse(controller.text.trim());
            if (val != null && val >= 0 && val <= 100) {
              orderProvider.applyDiscountToAll(val);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Applied ${val.toStringAsFixed(0)}% discount to all items'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply to All Items'),
        ),
      ],
    ),
  );
}
