import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sales_order.dart';
import '../../services/cloud_order_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import '../../theme/app_theme.dart';
import '../excel_download_dialog.dart';

class DispatchDashboardView extends StatefulWidget {
  const DispatchDashboardView({super.key});

  @override
  State<DispatchDashboardView> createState() => _DispatchDashboardViewState();
}

class _DispatchDashboardViewState extends State<DispatchDashboardView> {
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String _selectedMonth = 'ALL';
  String _dateFilterMode = 'ALL';
  DateTimeRange? _customDateRange;
  String _sortBy = 'NEWEST';
  String _selectedStatus = 'ALL'; // 'ALL', 'READY_FOR_DISPATCH', 'DISPATCHED'

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
        // Only show orders that are READY_FOR_DISPATCH or DISPATCHED
        _orders = allOrders
            .where((o) => o.status == 'READY_FOR_DISPATCH' || o.status == 'DISPATCHED')
            .toList();
        _isLoading = false;
      });
    }
  }

  Map<String, String> _getUniqueMonths() {
    final map = <String, String>{};
    for (var o in _orders) {
      final dt = o.dispatchPushedAt ?? o.savedAt ?? o.orderDate;
      final key = DateFormat('yyyy-MM').format(dt);
      final label = DateFormat('MMMM yyyy').format(dt);
      map[key] = label;
    }
    final now = DateTime.now();
    final nowKey = DateFormat('yyyy-MM').format(now);
    final nowLabel = DateFormat('MMMM yyyy').format(now);
    map[nowKey] = nowLabel;
    return map;
  }

  List<SalesOrder> _getDateFilteredOrders() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _orders.where((o) {
      final orderDate = o.dispatchPushedAt ?? o.savedAt ?? o.orderDate;

      if (_selectedMonth != 'ALL') {
        final orderMonthKey = DateFormat('yyyy-MM').format(orderDate);
        if (orderMonthKey != _selectedMonth) return false;
      }

      if (_dateFilterMode == 'TODAY') {
        if (orderDate.isBefore(todayStart) || orderDate.isAfter(todayEnd)) return false;
      } else if (_dateFilterMode == 'YESTERDAY') {
        final yestStart = todayStart.subtract(const Duration(days: 1));
        final yestEnd = DateTime(yestStart.year, yestStart.month, yestStart.day, 23, 59, 59);
        if (orderDate.isBefore(yestStart) || orderDate.isAfter(yestEnd)) return false;
      } else if (_dateFilterMode == 'THIS_WEEK') {
        final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        if (orderDate.isBefore(weekStart) || orderDate.isAfter(todayEnd)) return false;
      } else if (_dateFilterMode == 'THIS_MONTH') {
        final monthStart = DateTime(now.year, now.month, 1);
        if (orderDate.isBefore(monthStart) || orderDate.isAfter(todayEnd)) return false;
      } else if (_dateFilterMode == 'CUSTOM' && _customDateRange != null) {
        final rangeStart = DateTime(
          _customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day,
        );
        final rangeEnd = DateTime(
          _customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59,
        );
        if (orderDate.isBefore(rangeStart) || orderDate.isAfter(rangeEnd)) return false;
      }

      return true;
    }).toList();
  }

  List<SalesOrder> _getFilteredOrders() {
    final dateFiltered = _getDateFilteredOrders();
    final query = _searchController.text.trim().toLowerCase();

    final filtered = dateFiltered.where((o) {
      if (_selectedStatus != 'ALL') {
        if (o.status != _selectedStatus) return false;
      }
      if (query.isNotEmpty) {
        final matchesSo = o.salesOrderNo.toLowerCase().contains(query);
        final matchesCust = o.customerName.toLowerCase().contains(query);
        final matchesProj = o.projectName.toLowerCase().contains(query);
        final matchesRep = o.createdByEmail.toLowerCase().contains(query);
        if (!matchesSo && !matchesCust && !matchesProj && !matchesRep) return false;
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'OLDEST':
        filtered.sort((a, b) => (a.dispatchPushedAt ?? a.savedAt ?? DateTime(1970)).compareTo(b.dispatchPushedAt ?? b.savedAt ?? DateTime(1970)));
        break;
      case 'HIGHEST_VAL':
        filtered.sort((a, b) => b.grandTotal.compareTo(a.grandTotal));
        break;
      case 'LOWEST_VAL':
        filtered.sort((a, b) => a.grandTotal.compareTo(b.grandTotal));
        break;
      case 'NEWEST':
      default:
        filtered.sort((a, b) => (b.dispatchPushedAt ?? b.savedAt ?? DateTime(1970)).compareTo(a.dispatchPushedAt ?? a.savedAt ?? DateTime(1970)));
        break;
    }

    return filtered;
  }

  String _getActivePeriodTitle() {
    final monthsMap = _getUniqueMonths();
    if (_selectedMonth != 'ALL') return monthsMap[_selectedMonth] ?? _selectedMonth;
    switch (_dateFilterMode) {
      case 'TODAY': return 'Today';
      case 'YESTERDAY': return 'Yesterday';
      case 'THIS_WEEK': return 'This Week';
      case 'THIS_MONTH': return 'This Month';
      case 'CUSTOM':
        if (_customDateRange != null) {
          return '${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}';
        }
        return 'Custom Range';
      case 'ALL':
      default:
        return 'All Time';
    }
  }

  bool _isAnyFilterActive() {
    return _selectedMonth != 'ALL' ||
        _dateFilterMode != 'ALL' ||
        _selectedStatus != 'ALL' ||
        _searchController.text.trim().isNotEmpty;
  }

  void _resetAllFilters() {
    setState(() {
      _selectedMonth = 'ALL';
      _dateFilterMode = 'ALL';
      _customDateRange = null;
      _selectedStatus = 'ALL';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();
    final periodTitle = _getActivePeriodTitle();

    final pendingCount = filteredOrders.where((o) => o.status == 'READY_FOR_DISPATCH').length;
    final dispatchedCount = filteredOrders.where((o) => o.status == 'DISPATCHED').length;
    final totalValue = filteredOrders.fold(0.0, (sum, o) => sum + o.grandTotal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📦 Dispatch Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Process and ship orders sent by Admin',
                        style: TextStyle(fontSize: 12, color: Color(0xFFD1FAE5)),
                      ),
                    ],
                  ),
                ),
                // Refresh
                IconButton(
                  onPressed: _loadOrders,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  tooltip: 'Refresh Orders',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              final double cardWidth = isSmall
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 32) / 3;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Pending Dispatch',
                      value: '$pendingCount',
                      subtitle: 'Orders awaiting shipment',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFD97706),
                      bgGradient: [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Dispatched',
                      value: '$dispatchedCount',
                      subtitle: 'Orders shipped • $periodTitle',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF059669),
                      bgGradient: [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Total Value',
                      value: AppTheme.formatINR(totalValue),
                      subtitle: '${filteredOrders.length} orders • $periodTitle',
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFF1E6FBF),
                      bgGradient: [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Orders Table
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
                // Header Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 900;
                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleRow(periodTitle, filteredOrders.length),
                          const SizedBox(height: 14),
                          _buildFilterControls(),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTitleRow(periodTitle, filteredOrders.length),
                            if (_isAnyFilterActive())
                              OutlinedButton.icon(
                                onPressed: _resetAllFilters,
                                icon: const Icon(Icons.clear_all_rounded, size: 14, color: Color(0xFFDC2626)),
                                label: const Text('Reset Filters', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildFilterControls(),
                      ],
                    );
                  },
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 28),

                // Table Content
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF059669)),
                    ),
                  )
                else if (filteredOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _orders.isEmpty
                                ? 'No orders have been pushed to dispatch yet.'
                                : 'No orders match your current filters.',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Orders will appear here once the Admin pushes them for dispatch.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                          if (_isAnyFilterActive()) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _resetAllFilters,
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text('Show All Orders'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
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
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF0FDF4)),
                            headingTextStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                              letterSpacing: 0.3,
                            ),
                            dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                            columnSpacing: 20,
                            horizontalMargin: 16,
                            columns: const [
                              DataColumn(label: Text('PUSHED TO DISPATCH')),
                              DataColumn(label: Text('SO NUMBER')),
                              DataColumn(label: Text('SALES REP')),
                              DataColumn(label: Text('CUSTOMER')),
                              DataColumn(label: Text('PROJECT')),
                              DataColumn(label: Text('ITEMS')),
                              DataColumn(label: Text('GRAND TOTAL')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('ACTIONS')),
                            ],
                            rows: filteredOrders.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final h = entry.value;
                              final pushDate = h.dispatchPushedAt ?? h.savedAt;
                              final dateStr = pushDate != null ? _dateFormat.format(pushDate) : '-';
                              final repEmail = h.createdByEmail.isNotEmpty
                                  ? h.createdByEmail
                                  : (h.salesPerson.isNotEmpty ? h.salesPerson : 'Unknown');
                              final isReady = h.status == 'READY_FOR_DISPATCH';

                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>((states) {
                                  if (isReady) return const Color(0xFFFFFBEB);
                                  return idx % 2 == 0 ? Colors.white : const Color(0xFFF0FDF4);
                                }),
                                cells: [
                                  // Date pushed to dispatch
                                  DataCell(Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11))),
                                  // SO Number
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF5FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        h.salesOrderNo,
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F61B7), fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  // Sales Rep
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            repEmail.length >= 2 ? repEmail.substring(0, 2).toUpperCase() : 'U',
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(repEmail, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  // Customer
                                  DataCell(Text(
                                    h.customerName.isEmpty ? 'N/A' : h.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  )),
                                  // Project
                                  DataCell(Text(h.projectName.isEmpty ? '—' : h.projectName, style: const TextStyle(color: Color(0xFF64748B)))),
                                  // Items
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
                                  // Grand Total
                                  DataCell(
                                    Text(
                                      AppTheme.formatINR(h.grandTotal),
                                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 13),
                                    ),
                                  ),
                                  // Status Badge
                                  DataCell(_buildDispatchStatusBadge(h)),
                                  // Actions
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Mark Dispatched button (only for READY_FOR_DISPATCH)
                                        if (isReady) ...[
                                          ElevatedButton.icon(
                                            onPressed: () => _confirmMarkDispatched(h),
                                            icon: const Icon(Icons.check_circle_rounded, size: 13),
                                            label: const Text('Mark Dispatched', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                        // PDF
                                        IconButton(
                                          icon: const Icon(Icons.print_rounded, size: 17, color: Color(0xFF64748B)),
                                          tooltip: 'Print PDF',
                                          onPressed: () async {
                                            try {
                                              await PdfExportService.printOrExportSalesOrder(h);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        // Excel
                                        IconButton(
                                          icon: const Icon(Icons.table_view_rounded, size: 17, color: Color(0xFF10B981)),
                                          tooltip: 'Export Excel',
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
                                                    content: Text('Downloaded $chosenName.xlsx'),
                                                    backgroundColor: const Color(0xFF10B981),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Excel error: $e'), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          },
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
        ],
      ),
    );
  }

  Widget _buildTitleRow(String periodTitle, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.local_shipping_rounded, size: 18, color: Color(0xFF059669)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Dispatch Queue ($count)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    periodTitle,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                  ),
                ),
              ],
            ),
            const Text(
              'Orders pushed by Admin for processing & shipment',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    final monthsMap = _getUniqueMonths();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search
        SizedBox(
          width: 175,
          height: 34,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search SO, customer...',
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 15, color: Color(0xFF64748B)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
        ),

        // Month selector
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _selectedMonth != 'ALL' ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedMonth != 'ALL' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
              width: _selectedMonth != 'ALL' ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMonth,
              style: TextStyle(
                fontSize: 12,
                color: _selectedMonth != 'ALL' ? const Color(0xFF047857) : const Color(0xFF1E293B),
                fontWeight: _selectedMonth != 'ALL' ? FontWeight.w800 : FontWeight.w600,
              ),
              icon: Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: _selectedMonth != 'ALL' ? const Color(0xFF059669) : const Color(0xFF64748B),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedMonth = val;
                    if (val != 'ALL') {
                      _dateFilterMode = 'ALL';
                      _customDateRange = null;
                    }
                  });
                }
              },
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('🗓️ All Months')),
                ...monthsMap.entries.map((m) => DropdownMenuItem(value: m.key, child: Text(m.value))),
              ],
            ),
          ),
        ),

        // Date filter
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _dateFilterMode != 'ALL' ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _dateFilterMode != 'ALL' ? const Color(0xFF1E6FBF) : const Color(0xFFE2E8F0),
              width: _dateFilterMode != 'ALL' ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _dateFilterMode,
              style: TextStyle(
                fontSize: 12,
                color: _dateFilterMode != 'ALL' ? const Color(0xFF1E40AF) : const Color(0xFF1E293B),
                fontWeight: _dateFilterMode != 'ALL' ? FontWeight.w800 : FontWeight.w600,
              ),
              icon: Icon(
                Icons.date_range_rounded,
                size: 16,
                color: _dateFilterMode != 'ALL' ? const Color(0xFF1E6FBF) : const Color(0xFF64748B),
              ),
              onChanged: (val) async {
                if (val == 'CUSTOM') {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2030),
                    initialDateRange: _customDateRange ??
                        DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 7)),
                          end: DateTime.now(),
                        ),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF059669),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateFilterMode = 'CUSTOM';
                      _customDateRange = picked;
                      _selectedMonth = 'ALL';
                    });
                  }
                } else if (val != null) {
                  setState(() {
                    _dateFilterMode = val;
                    _customDateRange = null;
                    if (val != 'ALL') _selectedMonth = 'ALL';
                  });
                }
              },
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('📅 All Dates')),
                const DropdownMenuItem(value: 'TODAY', child: Text('Today')),
                const DropdownMenuItem(value: 'YESTERDAY', child: Text('Yesterday')),
                const DropdownMenuItem(value: 'THIS_WEEK', child: Text('This Week')),
                const DropdownMenuItem(value: 'THIS_MONTH', child: Text('This Month')),
                DropdownMenuItem(
                  value: 'CUSTOM',
                  child: Text(
                    _customDateRange != null
                        ? '${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}'
                        : 'Custom Date Range...',
                  ),
                ),
              ],
            ),
          ),
        ),

        // Status filter
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _selectedStatus != 'ALL' ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedStatus != 'ALL' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
              width: _selectedStatus != 'ALL' ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              style: TextStyle(
                fontSize: 12,
                color: _selectedStatus != 'ALL' ? const Color(0xFF047857) : const Color(0xFF1E293B),
                fontWeight: _selectedStatus != 'ALL' ? FontWeight.w800 : FontWeight.w600,
              ),
              icon: Icon(
                Icons.alt_route_rounded,
                size: 16,
                color: _selectedStatus != 'ALL' ? const Color(0xFF059669) : const Color(0xFF64748B),
              ),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('⚡ All')),
                DropdownMenuItem(value: 'READY_FOR_DISPATCH', child: Text('📦 Pending Dispatch')),
                DropdownMenuItem(value: 'DISPATCHED', child: Text('✓ Dispatched')),
              ],
            ),
          ),
        ),

        // Sort
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
              icon: const Icon(Icons.sort_rounded, size: 16),
              onChanged: (val) {
                if (val != null) setState(() => _sortBy = val);
              },
              items: const [
                DropdownMenuItem(value: 'NEWEST', child: Text('Newest First')),
                DropdownMenuItem(value: 'OLDEST', child: Text('Oldest First')),
                DropdownMenuItem(value: 'HIGHEST_VAL', child: Text('Highest Value')),
                DropdownMenuItem(value: 'LOWEST_VAL', child: Text('Lowest Value')),
              ],
            ),
          ),
        ),

        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
          tooltip: 'Refresh',
          onPressed: _loadOrders,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: bgGradient),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchStatusBadge(SalesOrder h) {
    if (h.status == 'READY_FOR_DISPATCH') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending_actions_rounded, size: 12, color: Color(0xFFB45309)),
            SizedBox(width: 4),
            Text(
              'Pending Dispatch',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
            ),
          ],
        ),
      );
    } else if (h.status == 'DISPATCHED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF047857)),
                SizedBox(width: 4),
                Text(
                  'Dispatched ✓',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          if (h.dispatchedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Shipped: ${_dateFormat.format(h.dispatchedAt!)}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _confirmMarkDispatched(SalesOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
            SizedBox(width: 8),
            Text('Mark as Dispatched?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order: ${order.salesOrderNo}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Customer: ${order.customerName.isNotEmpty ? order.customerName : "N/A"}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Confirm that this order has been processed, packed, and shipped from the warehouse?',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await CloudOrderService.markOrderDispatched(order);
              await _loadOrders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.salesOrderNo} marked as Dispatched! ✓'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('Confirm Dispatched'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
