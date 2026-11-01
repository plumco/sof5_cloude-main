// File: lib/shared/widgets/cart_sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_order_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/excel_export_service.dart';
import '../../widgets/common/kpi_card.dart';
import '../../widgets/excel_download_dialog.dart';

class CartSidebar extends StatelessWidget {
  const CartSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<SalesOrderProvider>();
    final cart = orderProvider.cart;
    final totalListPrice = cart.fold(0.0, (sum, it) => sum + (it.listPrice * it.qty));
    final totalSavings = totalListPrice - orderProvider.subtotal;
    final effectiveDiscountPct = totalListPrice > 0 ? (totalSavings / totalListPrice * 100) : 52.0;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: AppTheme.dark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: AppTheme.sidebarShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sidebar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: AppTheme.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Cart Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white70, size: 18),
                  tooltip: 'Hide Cart Panel',
                  onPressed: () => orderProvider.setSidebarVisible(false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // KPIs Grid (Products, Total Quantity, Total Value)
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    icon: '📦',
                    label: 'Products',
                    value: '${orderProvider.cartCount}',
                    unit: 'items',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KpiCard(
                    icon: '🔢',
                    label: 'Total Qty',
                    value: '${orderProvider.totalQty}',
                    unit: 'pcs',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KpiCard(
                    icon: '💰',
                    label: 'Total Value',
                    value: AppTheme.formatINR(orderProvider.subtotal, removeDecimals: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cart items preview section
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cart Items (${orderProvider.cartCount})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if (cart.isNotEmpty)
                    InkWell(
                      onTap: () => orderProvider.setTabIndex(2),
                      child: const Text(
                        'View all ▾',
                        style: TextStyle(color: Color(0xFF5BA0FF), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Mini items list (up to 5 items)
            if (cart.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Icon(Icons.add_shopping_cart_rounded, size: 28, color: Color(0xFF64748B)),
                    SizedBox(height: 8),
                    Text(
                      'No items in cart yet.\nSelect items from Catalog tab.',
                      style: TextStyle(color: Color(0xFFAEBBD0), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              ...cart.take(5).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: Color(0xFFAEBBD0),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.qty} pcs',
                          style: const TextStyle(color: Color(0xFFAEBBD0), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTheme.formatINR(item.amount, removeDecimals: true),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => orderProvider.setTabIndex(2), // Switch to Cart Summary tab
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2446),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF15365F)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'View & edit all items in cart ▾',
                    style: TextStyle(
                      color: Color(0xFF5BA0FF),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Totals and actions
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
              ),
              child: Column(
                children: [
                  _totalRow('Subtotal', AppTheme.formatINR(orderProvider.subtotal)),
                  _totalRow(
                    'Total Discount',
                    totalSavings > 0
                        ? '- ${AppTheme.formatINR(totalSavings, removeDecimals: true)} (${effectiveDiscountPct.toStringAsFixed(0)}%)'
                        : '52% applied',
                    isHighlight: true,
                  ),
                  _totalRow('VAT / GST (18%)', AppTheme.formatINR(orderProvider.gst)),
                  const Divider(color: Colors.white24, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      Text(
                        AppTheme.formatINR(orderProvider.grandTotal),
                        style: const TextStyle(
                          color: AppTheme.orange,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () async {
                if (cart.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cart is empty. Add items from Catalog first.')),
                  );
                  return;
                }
                try {
                  await orderProvider.printSalesOrder();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Print error: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Print Sales Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                            SnackBar(content: Text('Excel export error: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.table_chart_outlined, size: 14),
                    label: const Text('⬇ Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B274D),
                      side: const BorderSide(color: AppTheme.orange),
                      foregroundColor: const Color(0xFFFFBD76),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await orderProvider.saveDraft();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Draft saved locally on this device!'),
                            backgroundColor: AppTheme.nav,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined, size: 14),
                    label: const Text('💾 Save Draft', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B274D),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      foregroundColor: const Color(0xFF93C5FD),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFD7E0EE), fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppTheme.green : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

