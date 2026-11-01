import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_order_provider.dart';
import '../../providers/order_history_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/excel_export_service.dart';
import '../../services/cloud_order_service.dart';
import '../editable_quantity_stepper.dart';
import '../excel_download_dialog.dart';
import '../bulk_discount_bar.dart';

class CartSummaryView extends StatelessWidget {
  const CartSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<SalesOrderProvider>();
    final cart = orderProvider.cart;

    // Calculate total list value vs discounted value for savings metric
    final totalListPrice = cart.fold(0.0, (sum, it) => sum + (it.listPrice * it.qty));
    final totalSavings = totalListPrice - orderProvider.subtotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (orderProvider.adminEditingBannerText != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x1AF59E0B), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_open_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      orderProvider.adminEditingBannerText!,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 1. Cart Items Table Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 680;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.blue.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.shopping_cart_rounded, size: 16, color: AppTheme.blue),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cart Summary (${orderProvider.cartCount} items)',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const Text(
                                      'Review items, adjust quantities, and apply special discounts',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (cart.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                BulkDiscountBar(orderProvider: orderProvider),
                                _buildClearCartButton(context, orderProvider),
                              ],
                            ),
                          ],
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.blue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.shopping_cart_rounded, size: 16, color: AppTheme.blue),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cart Summary (${orderProvider.cartCount} items)',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Text(
                                  'Review items, adjust quantities, and apply special discounts',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (cart.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BulkDiscountBar(orderProvider: orderProvider),
                              const SizedBox(width: 10),
                              _buildClearCartButton(context, orderProvider),
                            ],
                          ),
                      ],
                    );
                  },
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 28),

                if (orderProvider.order.status == 'REVERTED')
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Reverted by Admin for Revision',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                              ),
                              if (orderProvider.order.revertReason.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Admin Problem Note: "${orderProvider.order.revertReason}"',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (cart.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(50),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove_shopping_cart_rounded, size: 32, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Your cart is currently empty',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Browse the catalog to add pipes, fittings, and accessories.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () => orderProvider.setTabIndex(1),
                            icon: const Icon(Icons.storefront_rounded, size: 16),
                            label: const Text('Open Product Catalog'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orange,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemDescWidth = (constraints.maxWidth - 560).clamp(240.0, 600.0);
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 56,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                      dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                      columnSpacing: 20,
                      horizontalMargin: 16,
                      columns: [
                        const DataColumn(label: Text('PRODUCT')),
                        const DataColumn(label: Text('DN')),
                        const DataColumn(label: Text('QTY')),
                        const DataColumn(label: Text('UOM')),
                        const DataColumn(label: Text('LIST PRICE')),
                        DataColumn(
                          label: InkWell(
                            onTap: () => showBulkDiscountDialog(context, orderProvider),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('DISCOUNT'),
                                  SizedBox(width: 4),
                                  Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF059669)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataColumn(label: Text('UNIT PRICE')),
                        DataColumn(label: Text('TOTAL AMOUNT')),
                        DataColumn(label: Text('ACTION')),
                      ],
                      rows: cart.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                            return i % 2 == 0 ? Colors.white : const Color(0xFFFAFCFF);
                          }),
                          cells: [
                            // Product Item Code + Desc
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: itemDescWidth),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.itemCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F61B7),
                                      ),
                                    ),
                                    Text(
                                      item.description,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // DN
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF5FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.dn?.toString() ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2F77FF), fontSize: 11),
                                ),
                              ),
                            ),
                            // Quantity Stepper (editable + +/- buttons)
                            DataCell(
                              EditableQuantityStepper(
                                value: item.qty,
                                onChanged: (newQty) => orderProvider.updateItemQty(i, newQty),
                              ),
                            ),
                            // UOM
                            const DataCell(Text('pcs', style: TextStyle(color: Color(0xFF64748B)))),
                            // List Price
                            DataCell(Text(AppTheme.formatINR(item.listPrice))),
                            // Discount % (Editable Input Field)
                            DataCell(
                              SizedBox(
                                width: 72,
                                height: 34,
                                child: TextFormField(
                                  key: ValueKey('cart_disc_${item.itemCode}_${i}_${(item.discount * 100).toStringAsFixed(2)}'),
                                  initialValue: (item.discount * 100).toStringAsFixed(
                                    (item.discount * 100).truncateToDouble() == (item.discount * 100) ? 0 : 2,
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF047857),
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    suffixText: '%',
                                    suffixStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF047857),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFECFDF5),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFFA7F3D0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val) ?? 0.0;
                                    orderProvider.updateItemDiscount(i, parsed);
                                  },
                                ),
                              ),
                            ),
                            // Unit Price
                            DataCell(Text(AppTheme.formatINR(item.unitPrice), style: const TextStyle(fontWeight: FontWeight.w600))),
                            // Amount
                            DataCell(
                              Text(
                                AppTheme.formatINR(item.amount),
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF071A34)),
                              ),
                            ),
                            // Remove Button
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.red),
                                tooltip: 'Remove item',
                                onPressed: () => orderProvider.removeItem(i),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Financial Summary Card
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text('₹', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Order Totals & Savings Summary',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      if (totalSavings > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.greenLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            'You Save: ${AppTheme.formatINR(totalSavings)}',
                            style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 28),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 24,
                        runSpacing: 18,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildSummaryMetric('Subtotal (Excl. Tax)', AppTheme.formatINR(orderProvider.subtotal)),
                          _buildSummaryMetric('GST / VAT (18%)', AppTheme.formatINR(orderProvider.gst)),
                          _buildSummaryMetric('Total Quantity', '${orderProvider.totalQty} pcs'),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Grand Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Text(
                                AppTheme.formatINR(orderProvider.grandTotal),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.orange),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  if (cart.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please add at least one item from Catalog.')),
                                    );
                                    return;
                                  }
                                  final defaultName = ExcelExportService.getDefaultFileName(orderProvider.salesOrder);
                                  final chosenName = await showExcelExportDialog(
                                    context,
                                    defaultFileName: defaultName,
                                  );
                                  if (chosenName == null || chosenName.trim().isEmpty) return;

                                  try {
                                    await orderProvider.downloadExcel(customFileName: chosenName);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Excel workbook "$chosenName.xlsx" exported successfully!'),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Excel export error: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.table_view_rounded, size: 18, color: Color(0xFF10B981)),
                                label: const Text('Export Excel', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF10B981)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await orderProvider.printSalesOrder();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF64748B)),
                                label: const Text('Print PDF', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: orderProvider.isSaving ? null : () async {
                                  await orderProvider.saveOrder(context: context);
                                  if (context.mounted) {
                                    context.read<OrderHistoryProvider>().loadHistory();
                                  }
                                },
                                icon: orderProvider.isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.bookmark_added_rounded, size: 18),
                                label: Text(orderProvider.isSaving ? 'Saving...' : 'Save Order History'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.orange,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                ),
                              ),
                              if (orderProvider.order.status == 'DRAFT' && orderProvider.cart.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: (orderProvider.isSaving || orderProvider.isPushingToBackOffice)
                                      ? null
                                      : () async {
                                          await orderProvider.pushToBackOffice(context: context);
                                          if (context.mounted) {
                                            context.read<OrderHistoryProvider>().loadHistory();
                                          }
                                        },
                                  icon: orderProvider.isPushingToBackOffice
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.rocket_launch_rounded, size: 18),
                                  label: Text(orderProvider.isPushingToBackOffice ? 'Pushing...' : 'Push to Back Office'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  ),
                                ),
                              ],
                              if (orderProvider.order.status == 'REVERTED') ...[
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: (orderProvider.isSaving || orderProvider.isRepushing) ? null : () async {
                                    await orderProvider.repushOrder(context: context);
                                    if (context.mounted) {
                                      context.read<OrderHistoryProvider>().loadHistory();
                                    }
                                  },
                                  icon: orderProvider.isRepushing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.send_rounded, size: 18),
                                  label: Text(orderProvider.isRepushing ? 'Re-Pushing...' : 'Re-Push to Back Office'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildClearCartButton(BuildContext context, SalesOrderProvider orderProvider) {
    return OutlinedButton.icon(
      onPressed: orderProvider.isClearing ? null : () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear Cart?'),
            content: const Text('Are you sure you want to remove all items from your cart?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  orderProvider.clearCart(context: context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
                child: const Text('Clear All'),
              ),
            ],
          ),
        );
      },
      icon: orderProvider.isClearing
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.red))
          : const Icon(Icons.delete_sweep_rounded, size: 16, color: AppTheme.red),
      label: Text(orderProvider.isClearing ? 'Clearing...' : 'Clear Cart', style: const TextStyle(color: AppTheme.red, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.redBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
