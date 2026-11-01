import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/sales_order.dart';
import '../../providers/order_history_provider.dart';
import '../../providers/sales_order_provider.dart';
import '../../services/excel_export_service.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/app_theme.dart';
import '../excel_download_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_role_helper.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  bool _isLoadingOrder = false;
  bool _isAdminDialogOpen = false;

  Future<void> _handleLoadOrder(
    BuildContext context,
    SalesOrder h,
    SalesOrderProvider orderProvider, {
    int targetTab = 0,
    String? customSuccessMessage,
    Color? customSnackBarColor,
  }) async {
    if (_isLoadingOrder) return;

    if (orderProvider.cart.isNotEmpty) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFD97706), size: 22),
              SizedBox(width: 8),
              Text('Overwrite Current Cart?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Current cart has ${orderProvider.cart.length} items. Clear and load ${h.salesOrderNo}?',
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear & Load'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _isLoadingOrder = true;
    });

    try {
      orderProvider.loadOrder(h);
      orderProvider.setTabIndex(targetTab);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customSuccessMessage ?? 'Loaded ${h.salesOrderNo} into active form'),
            backgroundColor: customSnackBarColor ?? AppTheme.nav,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<OrderHistoryProvider>();
    final orderProvider = context.read<SalesOrderProvider>();
    final history = historyProvider.history;
    final dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
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
                        color: AppTheme.blue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.history_rounded, size: 16, color: AppTheme.blue),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Order History (${history.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Text(
                          'Browse past quotes and reload items for recurring purchases',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
                if (history.isNotEmpty)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                        tooltip: 'Refresh History',
                        onPressed: () => historyProvider.loadHistory(),
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clear All History?'),
                              content: const Text('Are you sure you want to delete all saved orders? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    historyProvider.clearAll();
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: AppTheme.red),
                        label: const Text('Clear All', style: TextStyle(color: AppTheme.red, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.redBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 28),

            if (historyProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(50),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (history.isEmpty)
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
                        child: const Icon(Icons.history_toggle_off_rounded, size: 32, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No order history saved yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Use "Save Order History" from the Cart Summary tab to record completed orders.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                  dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  columns: const [
                    DataColumn(label: Text('DATE & TIME')),
                    DataColumn(label: Text('SO NUMBER')),
                    DataColumn(label: Text('CUSTOMER')),
                    DataColumn(label: Text('PROJECT')),
                    DataColumn(label: Text('ITEMS')),
                    DataColumn(label: Text('GRAND TOTAL')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: history.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final h = entry.value;
                    final dateStr = h.savedAt != null ? dateFormat.format(h.savedAt!) : '-';
                    final isPushed = h.status == 'PUSHED' ||
                        h.status == OrderStatus.pushedToBackOffice ||
                        h.status == OrderStatus.inReview ||
                        h.status == 'PUSHED_TO_BACKOFFICE' ||
                        h.status == 'IN_REVIEW';
                    final isReverted = h.status == 'REVERTED';
                    final isDispatched = h.status == 'DISPATCHED';
                    String? userEmail;
                    try {
                      userEmail = FirebaseAuth.instance.currentUser?.email;
                    } catch (_) {
                      userEmail = null;
                    }
                    final currentUserRole = AuthRoleHelper.isAdmin(userEmail)
                        ? 'admin'
                        : (AuthRoleHelper.isBackOffice(userEmail)
                            ? 'backoffice'
                            : (AuthRoleHelper.isDispatch(userEmail) ? 'dispatch' : 'sales'));
                    final isAdmin = currentUserRole == 'admin';
                    final canEdit = canEditOrder(h, currentUserRole);

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                        if (isReverted) return const Color(0xFFFFFBEB);
                        return idx % 2 == 0 ? Colors.white : const Color(0xFFFAFCFF);
                      }),
                      cells: [
                        DataCell(Text(dateStr, style: const TextStyle(color: Color(0xFF64748B)))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              h.salesOrderNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F61B7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(h.customerName.isEmpty ? 'N/A' : h.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(h.projectName.isEmpty ? '—' : h.projectName, style: const TextStyle(color: Color(0xFF64748B)))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${h.items.length} items',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            AppTheme.formatINR(h.grandTotal),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 13),
                          ),
                        ),
                        // STATUS COLUMN
                        DataCell(
                          _buildStatusBadge(h),
                        ),
                        // ACTIONS COLUMN
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Edit & Correct (If Reverted)
                              if (isReverted) ...[
                                ElevatedButton.icon(
                                  onPressed: _isLoadingOrder
                                      ? null
                                      : () => _handleLoadOrder(
                                            context,
                                            h,
                                            orderProvider,
                                            targetTab: 2,
                                            customSuccessMessage: 'Loaded ${h.salesOrderNo} for correction. Reason: ${h.revertReason}',
                                            customSnackBarColor: const Color(0xFFD97706),
                                          ),
                                  icon: const Icon(Icons.edit_note_rounded, size: 14),
                                  label: const Text('Edit & Correct', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton.icon(
                                  onPressed: () => _confirmPushOrder(context, h, historyProvider, isRepush: true),
                                  icon: const Icon(Icons.send_rounded, size: 13),
                                  label: const Text('Re-Push to Back Office', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ] else if (isDispatched) ...[
                                if (!canEdit) ...[
                                  Tooltip(
                                    message: 'Dispatched - view only, contact Admin',
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showReadOnlyOrderDialog(context, h),
                                      icon: const Icon(Icons.visibility_outlined, size: 13),
                                      label: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF475569),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ] else if (isAdmin) ...[
                                  ElevatedButton.icon(
                                    onPressed: _isAdminDialogOpen ? null : () => _showAdminReasonDialog(context, h, orderProvider),
                                    icon: const Icon(Icons.warning_amber_rounded, size: 14),
                                    label: const Text('Admin Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF97316),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ] else ...[
                                                                // Pushed to Back Office / In Review: Sales view-only, Back Office / Admin review
                                if (isPushed) ...[
                                  if (!canEdit) ...[
                                    Tooltip(
                                      message: 'Pushed to Back Office - in review (view only)',
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showReadOnlyOrderDialog(context, h),
                                        icon: const Icon(Icons.visibility_outlined, size: 13),
                                        label: const Text('View (In Review)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF475569),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ] else ...[
                                    ElevatedButton.icon(
                                      onPressed: _isLoadingOrder
                                          ? null
                                          : () => _handleLoadOrder(context, h, orderProvider),
                                      icon: _isLoadingOrder
                                          ? const SizedBox(
                                              width: 13,
                                              height: 13,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.rate_review_rounded, size: 13),
                                      label: const Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1D4ED8),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ] else ...[
                                  // Load (Draft / Normal)
                                  ElevatedButton.icon(
                                    onPressed: _isLoadingOrder
                                        ? null
                                        : () => _handleLoadOrder(context, h, orderProvider),
                                    icon: _isLoadingOrder
                                        ? const SizedBox(
                                            width: 13,
                                            height: 13,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.upload_file_rounded, size: 13),
                                    label: const Text('Load', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ],
// 2. Push to Back Office (If Draft)
                              if (!isPushed && !isReverted && !isDispatched) ...[
                                ElevatedButton.icon(
                                  onPressed: () => _confirmPushOrder(context, h, historyProvider, isRepush: false),
                                  icon: const Icon(Icons.rocket_launch_rounded, size: 13),
                                  label: const Text('Push to Back Office', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],

                              // Print PDF
                              IconButton(
                                icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF64748B)),
                                tooltip: 'Print PDF',
                                onPressed: () async {
                                  try {
                                    await PdfExportService.printOrExportSalesOrder(h);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('PDF export error: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                              ),
                              // Export Excel
                              IconButton(
                                icon: const Icon(Icons.table_view_rounded, size: 18, color: Color(0xFF10B981)),
                                tooltip: 'Export Excel (Original Format)',
                                onPressed: () async {
                                  final defaultName = ExcelExportService.getDefaultFileName(h);
                                  final chosenName = await showExcelExportDialog(
                                    context,
                                    defaultFileName: defaultName,
                                  );
                                  if (chosenName == null || chosenName.trim().isEmpty) return;

                                  try {
                                    await ExcelExportService.generateAndDownloadExcel(h, customFileName: chosenName);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Downloaded Excel: $chosenName.xlsx'),
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
                              ),

                              // Delete (Only allowed for DRAFT)
                              if (!isPushed && !isDispatched)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                  tooltip: 'Delete Order',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Saved Order?'),
                                        content: Text(
                                          'Are you sure you want to delete order "${h.salesOrderNo}" from history?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              historyProvider.deleteOrder(idx);
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Order ${h.salesOrderNo} deleted from history'),
                                                  backgroundColor: AppTheme.red,
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              else if (isPushed)
                                const Tooltip(
                                  message: 'Order is pushed to Back Office for review and locked. It cannot be deleted.',
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.lock_rounded, size: 18, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                            ],
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
    );
  }

  Widget _buildStatusBadge(SalesOrder h) {
    if (h.status == 'PUSHED' || h.status == OrderStatus.pushedToBackOffice || h.status == OrderStatus.inReview || h.status == 'PUSHED_TO_BACKOFFICE' || h.status == 'IN_REVIEW') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: Color(0xFF1D4ED8)),
            SizedBox(width: 4),
            Text(
              'Pushed to Back Office',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
            ),
          ],
        ),
      );
    } else if (h.status == 'REVERTED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFB45309)),
                SizedBox(width: 4),
                Text(
                  'Reverted by Admin',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          if (h.revertReason.isNotEmpty) ...[
            const SizedBox(height: 3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                'Note: "${h.revertReason}"',
                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF92400E)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      );
    } else if (h.status == 'DISPATCHED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF047857)),
            SizedBox(width: 4),
            Text(
              'Dispatched',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note_rounded, size: 12, color: Color(0xFF64748B)),
          SizedBox(width: 4),
          Text(
            'Draft',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _confirmPushOrder(BuildContext context, SalesOrder h, OrderHistoryProvider historyProvider, {required bool isRepush}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isRepush ? Icons.send_rounded : Icons.rocket_launch_rounded,
              color: const Color(0xFF059669),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(isRepush ? 'Re-Push Order to Back Office?' : 'Push Order to Back Office?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you ready to send order "${h.salesOrderNo}" to Back Office for review?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_rounded, size: 18, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once pushed, this order is locked for Back Office review. You will not be able to delete it.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final orderProvider = context.read<SalesOrderProvider>();
              final success = isRepush
                  ? await historyProvider.repushOrder(h)
                  : await historyProvider.pushOrder(h);
              h.status = OrderStatus.pushedToBackOffice;
              h.pushedAt = DateTime.now();
              if (orderProvider.order.salesOrderNo == h.salesOrderNo) {
                orderProvider.clearCart();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isRepush ? 'Order ${h.salesOrderNo} re-pushed to Back Office!' : 'Order ${h.salesOrderNo} pushed to Back Office for review!')
                          : 'Error pushing order',
                    ),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            child: Text(isRepush ? 'Re-Push Now' : 'Push to Back Office'),
          ),
        ],
      ),
    );
  }

  void _showReadOnlyOrderDialog(BuildContext context, SalesOrder h) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.visibility_rounded, color: Color(0xFF047857), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Order Details: ${h.salesOrderNo}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                h.status,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: ${h.customerName}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Contact: ${h.contactPerson}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Grand Total: ₹${h.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('${h.items.length} items (${h.totalQty} pcs)',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Items in Order:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: h.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = h.items[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.itemCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text(item.description, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text('${item.qty} pcs • ₹${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (h.status == OrderStatus.pushedToBackOffice || h.status == 'PUSHED' || h.status == OrderStatus.inReview || h.status == 'PUSHED_TO_BACKOFFICE' || h.status == 'IN_REVIEW')
                            ? 'Pushed to Back Office - in review (view only). Contact Back Office or Admin for revisions.'
                            : 'Dispatched - view only, contact Admin for revisions.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF475569)),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminReasonDialog(BuildContext context, SalesOrder h, SalesOrderProvider orderProvider) async {
    if (_isAdminDialogOpen) return;
    setState(() {
      _isAdminDialogOpen = true;
    });

    final reasonController = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final isProceedEnabled = reasonController.text.trim().isNotEmpty;

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 24),
                    SizedBox(width: 8),
                    Text('⚠️ Admin Edit - Dispatched Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${h.salesOrderNo} is Dispatched. Are you sure you want to edit?',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Editing a dispatched order will record an audit trail entry and allow modifications in the cart.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: reasonController,
                        autofocus: true,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Reason for edit (required)',
                          hintText: 'e.g., Customer requested urgent quantity increase before shipping',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                          ),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: isProceedEnabled
                        ? () {
                            final reason = reasonController.text.trim();
                            String? userEmail;
                            try {
                              userEmail = FirebaseAuth.instance.currentUser?.email;
                            } catch (_) {
                              userEmail = null;
                            }
                            final adminEmail = userEmail ?? 'admin@so.com';

                            h.recordAdminEdit(email: adminEmail, reason: reason);
                            orderProvider.loadAdminEditedDispatchedOrder(
                              h,
                              reason: reason,
                              adminEmail: adminEmail,
                            );
                            orderProvider.setTabIndex(2);
                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🔓 Admin Edit Mode activated for ${h.salesOrderNo}'),
                                backgroundColor: const Color(0xFFF97316),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Proceed with Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAdminDialogOpen = false;
        });
      }
    }
  }

}
