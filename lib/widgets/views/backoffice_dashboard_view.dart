import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sales_order.dart';
import '../../services/cloud_order_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import '../../theme/app_theme.dart';
import '../excel_download_dialog.dart';

class BackOfficeDashboardView extends StatefulWidget {
  const BackOfficeDashboardView({super.key});

  @override
  State<BackOfficeDashboardView> createState() => _BackOfficeDashboardViewState();
}

class _BackOfficeDashboardViewState extends State<BackOfficeDashboardView> {
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String _selectedMonth = 'ALL';
  String _dateFilterMode = 'ALL';
  DateTimeRange? _customDateRange;
  String _sortBy = 'NEWEST';
  String _selectedStatus = 'ALL'; // 'ALL', 'PUSHED', 'REVERTED', 'READY_FOR_DISPATCH', 'DISPATCHED'
  String _selectedRep = 'ALL';

  bool _isLoading = false;
  List<SalesOrder> _orders = [];

  final DateFormat _dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final allOrders = await CloudOrderService.fetchAllOrders();
    if (mounted) {
      setState(() {
        _orders = allOrders;
        _isLoading = false;
      });
    }
  }

  Map<String, String> _getUniqueMonths() {
    final map = <String, String>{};
    for (var o in _orders) {
      final date = o.savedAt ?? o.orderDate;
      final key = DateFormat('yyyy-MM').format(date);
      final label = DateFormat('MMMM yyyy').format(date);
      map[key] = label;
    }
    return map;
  }

  List<String> _getUniqueReps() {
    final set = <String>{};
    for (var o in _orders) {
      final rep = o.createdByEmail.isNotEmpty ? o.createdByEmail : o.salesPerson;
      if (rep.isNotEmpty) set.add(rep);
    }
    return set.toList()..sort();
  }

  List<SalesOrder> _getFilteredOrders() {
    return _orders.where((order) {
      // 1. Search Query
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchNo = order.salesOrderNo.toLowerCase().contains(query);
        final matchCustomer = order.customerName.toLowerCase().contains(query);
        final matchRep = order.createdByEmail.toLowerCase().contains(query) ||
            order.salesPerson.toLowerCase().contains(query);
        if (!matchNo && !matchCustomer && !matchRep) return false;
      }

      // 2. Status Filter
      if (_selectedStatus != 'ALL' && order.status != _selectedStatus) {
        return false;
      }

      // 3. Sales Rep Filter
      if (_selectedRep != 'ALL') {
        final rep = order.createdByEmail.isNotEmpty ? order.createdByEmail : order.salesPerson;
        if (rep != _selectedRep) return false;
      }

      // 4. Month Filter
      final orderDate = order.savedAt ?? order.orderDate;
      if (_selectedMonth != 'ALL') {
        final orderMonth = DateFormat('yyyy-MM').format(orderDate);
        if (orderMonth != _selectedMonth) return false;
      }

      // 5. Date Filter
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final itemDay = DateTime(orderDate.year, orderDate.month, orderDate.day);

      if (_dateFilterMode == 'TODAY') {
        if (!itemDay.isAtSameMomentAs(today)) return false;
      } else if (_dateFilterMode == 'YESTERDAY') {
        final yest = today.subtract(const Duration(days: 1));
        if (!itemDay.isAtSameMomentAs(yest)) return false;
      } else if (_dateFilterMode == 'LAST_7_DAYS') {
        if (itemDay.isBefore(today.subtract(const Duration(days: 7)))) return false;
      } else if (_dateFilterMode == 'CUSTOM' && _customDateRange != null) {
        if (itemDay.isBefore(_customDateRange!.start) ||
            itemDay.isAfter(_customDateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final aDate = a.savedAt ?? a.orderDate;
        final bDate = b.savedAt ?? b.orderDate;
        if (_sortBy == 'NEWEST') return bDate.compareTo(aDate);
        if (_sortBy == 'OLDEST') return aDate.compareTo(bDate);
        if (_sortBy == 'AMOUNT_HIGH') return b.grandTotal.compareTo(a.grandTotal);
        if (_sortBy == 'AMOUNT_LOW') return a.grandTotal.compareTo(b.grandTotal);
        return 0;
      });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedMonth = 'ALL';
      _dateFilterMode = 'ALL';
      _customDateRange = null;
      _sortBy = 'NEWEST';
      _selectedStatus = 'ALL';
      _selectedRep = 'ALL';
    });
  }

  // --- ACTIONS ---

  Future<void> _pushToDispatch(SalesOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: AppTheme.blue),
            SizedBox(width: 8),
            Text('Push to Dispatch Team?'),
          ],
        ),
        content: Text(
          'Are you sure you want to approve SO "${order.salesOrderNo}" and send it to the Dispatch Team (dispatch@gmail.com)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Push', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await CloudOrderService.pushToDispatchTeam(order);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✓ Order "${order.salesOrderNo}" pushed to Dispatch Team!'
                  : 'Failed to push order.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _revertOrder(SalesOrder order) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.undo, color: Colors.amber),
            SizedBox(width: 8),
            Text('Revert Order to Sales Rep'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reverting SO "${order.salesOrderNo}" to ${order.createdByEmail.isNotEmpty ? order.createdByEmail : order.salesPerson}.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Correction Reason *',
                hintText: 'e.g. Incomplete site address or wrong payment term',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Revert Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      final success = await CloudOrderService.revertOrderToRep(
        order,
        reasonController.text.trim(),
      );
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Order "${order.salesOrderNo}" reverted. Notification sent to sales rep!'
                  : 'Failed to revert order.',
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderItemsModal(SalesOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppTheme.blue),
                  const SizedBox(width: 10),
                  Text(
                    'Order Details: ${order.salesOrderNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // Info Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Sales Rep: ${order.createdByEmail.isNotEmpty ? order.createdByEmail : order.salesPerson}'),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Grand Total: ₹ ${order.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 4),
                      Text('Items: ${order.items.length}'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Items List
            Expanded(
              child: ListView.separated(
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final it = order.items[i];
                  return ListTile(
                    title: Text(it.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('Code: ${it.itemCode} | Qty: ${it.qty} | List: ₹${it.listPrice}'),
                    trailing: Text('₹ ${it.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredOrders();
    final pendingCount = _orders.where((o) => o.status == 'PUSHED').length;
    final readyCount = _orders.where((o) => o.status == 'READY_FOR_DISPATCH').length;
    final revertedCount = _orders.where((o) => o.status == 'REVERTED').length;
    final dispatchedCount = _orders.where((o) => o.status == 'DISPATCHED').length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Banner
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business_center, color: AppTheme.blue, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Back Office Review Dashboard',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.dark),
                      ),
                      Text(
                        'Review incoming sales orders, verify pricing/credit, and push to dispatch',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Orders',
                    onPressed: _loadOrders,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI Row
              Row(
                children: [
                  Expanded(child: _buildKpiCard('Pending Review', '$pendingCount', Colors.amber.shade700, Icons.hourglass_top)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard('Ready for Dispatch', '$readyCount', AppTheme.blue, Icons.local_shipping_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard('Dispatched', '$dispatchedCount', Colors.green, Icons.check_circle_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard('Reverted', '$revertedCount', Colors.red, Icons.undo)),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Bar
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Search Box
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search SO#, Customer, Sales Rep...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Status Filter
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              isDense: true,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                                DropdownMenuItem(value: 'PUSHED', child: Text('Pending Review (Pushed)')),
                                DropdownMenuItem(value: 'READY_FOR_DISPATCH', child: Text('Ready for Dispatch')),
                                DropdownMenuItem(value: 'DISPATCHED', child: Text('Dispatched')),
                                DropdownMenuItem(value: 'REVERTED', child: Text('Reverted')),
                              ],
                              onChanged: (val) => setState(() => _selectedStatus = val ?? 'ALL'),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Sales Rep Filter
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedRep,
                              isDense: true,
                              decoration: InputDecoration(
                                labelText: 'Sales Rep',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: [
                                const DropdownMenuItem(value: 'ALL', child: Text('All Sales Reps')),
                                ..._getUniqueReps().map((rep) => DropdownMenuItem(value: rep, child: Text(rep, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (val) => setState(() => _selectedRep = val ?? 'ALL'),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Reset Button
                          OutlinedButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Orders Table
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Orders (${filtered.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (filtered.isNotEmpty)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.file_download, size: 18),
                              label: const Text('Export Excel'),
                              onPressed: () async {
                                final order = filtered.first;
                                final fileName = await showExcelExportDialog(
                                  context,
                                  defaultFileName: ExcelExportService.getDefaultFileName(order),
                                );
                                if (fileName != null && context.mounted) {
                                  await ExcelExportService.generateAndDownloadExcel(order, customFileName: fileName);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                      else if (filtered.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('No orders match the selected filters.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final o = filtered[i];
                            return _buildOrderRow(o);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(SalesOrder order) {
    final isPushed = order.status == 'PUSHED';
    final isReady = order.status == 'READY_FOR_DISPATCH';
    final isDispatched = order.status == 'DISPATCHED';
    final isReverted = order.status == 'REVERTED';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // SO Number & Date
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.salesOrderNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.blue)),
                const SizedBox(height: 2),
                Text(
                  order.savedAt != null ? _dateFormat.format(order.savedAt!) : 'N/A',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Customer & Rep
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'Rep: ${order.createdByEmail.isNotEmpty ? order.createdByEmail : order.salesPerson}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount & Items
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹ ${order.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${order.items.length} items', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(order.status),
            ),
          ),

          // Action Buttons
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Push to Dispatch Button (Only if PUSHED)
                if (isPushed)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.local_shipping, size: 15, color: Colors.white),
                    label: const Text('Push to Dispatch', style: TextStyle(fontSize: 11, color: Colors.white)),
                    onPressed: () => _pushToDispatch(order),
                  ),

                // 2. Revert Button (Only if PUSHED)
                if (isPushed) ...[
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade900,
                      side: BorderSide(color: Colors.amber.shade700),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.undo, size: 14),
                    label: const Text('Revert', style: TextStyle(fontSize: 11)),
                    onPressed: () => _revertOrder(order),
                  ),
                ],

                // 3. View Items
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  tooltip: 'View Items',
                  onPressed: () => _showOrderItemsModal(order),
                ),

                // 4. Print / PDF
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  tooltip: 'Download PDF',
                  onPressed: () => PdfExportService.printOrExportSalesOrder(order),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'PUSHED':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        label = 'Pending Review';
        break;
      case 'READY_FOR_DISPATCH':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Ready for Dispatch';
        break;
      case 'DISPATCHED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Dispatched ✓';
        break;
      case 'REVERTED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Reverted';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
