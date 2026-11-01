import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_role_helper.dart';
import '../../models/sales_order.dart';
import '../../providers/sales_order_provider.dart';
import '../../services/cloud_order_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';
import '../../theme/app_theme.dart';
import '../excel_download_dialog.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String _selectedRep = 'ALL';
  String _selectedMonth = 'ALL'; // 'ALL' or 'yyyy-MM'
  String _dateFilterMode = 'ALL'; // 'ALL', 'TODAY', 'YESTERDAY', 'THIS_WEEK', 'THIS_MONTH', 'CUSTOM'
  DateTimeRange? _customDateRange;
  String _sortBy = 'NEWEST';
  String _selectedStatus = 'ALL'; // 'ALL', 'PUSHED', 'REVERTED', 'DISPATCHED', 'DRAFT'

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
    final list = await CloudOrderService.fetchAllOrders();
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    }
  }

  Map<String, String> _getUniqueMonths() {
    final map = <String, String>{};
    for (var o in _orders) {
      final dt = o.savedAt ?? o.orderDate;
      final key = DateFormat('yyyy-MM').format(dt);
      final label = DateFormat('MMMM yyyy').format(dt);
      map[key] = label;
    }
    // Ensure current month is present
    final now = DateTime.now();
    final nowKey = DateFormat('yyyy-MM').format(now);
    final nowLabel = DateFormat('MMMM yyyy').format(now);
    map[nowKey] = nowLabel;

    return map;
  }

  List<String> _getUniqueSalesReps(List<SalesOrder> sourceOrders) {
    final set = <String>{};
    for (var o in sourceOrders) {
      final rep = o.createdByEmail.isNotEmpty ? o.createdByEmail : (o.salesPerson.isNotEmpty ? o.salesPerson : 'Unknown Rep');
      set.add(rep);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// Returns orders filtered by Month and Date range
  List<SalesOrder> _getDateFilteredOrders() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _orders.where((o) {
      final orderDate = o.savedAt ?? o.orderDate;

      // 1. Month-wise filter
      if (_selectedMonth != 'ALL') {
        final orderMonthKey = DateFormat('yyyy-MM').format(orderDate);
        if (orderMonthKey != _selectedMonth) {
          return false;
        }
      }

      // 2. Date-wise filter
      if (_dateFilterMode == 'TODAY') {
        if (orderDate.isBefore(todayStart) || orderDate.isAfter(todayEnd)) {
          return false;
        }
      } else if (_dateFilterMode == 'YESTERDAY') {
        final yestStart = todayStart.subtract(const Duration(days: 1));
        final yestEnd = DateTime(yestStart.year, yestStart.month, yestStart.day, 23, 59, 59);
        if (orderDate.isBefore(yestStart) || orderDate.isAfter(yestEnd)) {
          return false;
        }
      } else if (_dateFilterMode == 'THIS_WEEK') {
        final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        if (orderDate.isBefore(weekStart) || orderDate.isAfter(todayEnd)) {
          return false;
        }
      } else if (_dateFilterMode == 'THIS_MONTH') {
        final monthStart = DateTime(now.year, now.month, 1);
        if (orderDate.isBefore(monthStart) || orderDate.isAfter(todayEnd)) {
          return false;
        }
      } else if (_dateFilterMode == 'CUSTOM' && _customDateRange != null) {
        final rangeStart = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final rangeEnd = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        if (orderDate.isBefore(rangeStart) || orderDate.isAfter(rangeEnd)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Final list also filtered by Rep and Search query, with sorting applied
  List<SalesOrder> _getFilteredOrders() {
    final dateFiltered = _getDateFilteredOrders();
    final query = _searchController.text.trim().toLowerCase();

    final filtered = dateFiltered.where((o) {
      final rep = o.createdByEmail.isNotEmpty ? o.createdByEmail : o.salesPerson;
      if (_selectedRep != 'ALL' && rep.toLowerCase() != _selectedRep.toLowerCase()) {
        return false;
      }
      if (_selectedStatus != 'ALL') {
        final st = o.status.isEmpty ? 'DRAFT' : o.status;
        if (st != _selectedStatus) return false;
      }
      if (query.isNotEmpty) {
        final matchesSo = o.salesOrderNo.toLowerCase().contains(query);
        final matchesCust = o.customerName.toLowerCase().contains(query);
        final matchesProj = o.projectName.toLowerCase().contains(query);
        final matchesRep = rep.toLowerCase().contains(query);
        if (!matchesSo && !matchesCust && !matchesProj && !matchesRep) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case 'OLDEST':
        filtered.sort((a, b) => (a.savedAt ?? DateTime(1970)).compareTo(b.savedAt ?? DateTime(1970)));
        break;
      case 'HIGHEST_VAL':
        filtered.sort((a, b) => b.grandTotal.compareTo(a.grandTotal));
        break;
      case 'LOWEST_VAL':
        filtered.sort((a, b) => a.grandTotal.compareTo(b.grandTotal));
        break;
      case 'NEWEST':
      default:
        filtered.sort((a, b) => (b.savedAt ?? DateTime(1970)).compareTo(a.savedAt ?? DateTime(1970)));
        break;
    }

    return filtered;
  }

  String _getActivePeriodTitle() {
    final monthsMap = _getUniqueMonths();
    if (_selectedMonth != 'ALL') {
      return monthsMap[_selectedMonth] ?? _selectedMonth;
    }
    switch (_dateFilterMode) {
      case 'TODAY':
        return 'Today';
      case 'YESTERDAY':
        return 'Yesterday';
      case 'THIS_WEEK':
        return 'This Week';
      case 'THIS_MONTH':
        return 'This Month';
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
        _selectedRep != 'ALL' ||
        _selectedStatus != 'ALL' ||
        _searchController.text.trim().isNotEmpty;
  }

  void _resetAllFilters() {
    setState(() {
      _selectedMonth = 'ALL';
      _dateFilterMode = 'ALL';
      _customDateRange = null;
      _selectedRep = 'ALL';
      _selectedStatus = 'ALL';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.read<SalesOrderProvider>();
    final filteredOrders = _getFilteredOrders();
    final dateFilteredOrders = _getDateFilteredOrders();
    final periodTitle = _getActivePeriodTitle();

    // Period-aware metrics
    final totalRevenue = filteredOrders.fold(0.0, (sum, o) => sum + o.grandTotal);
    final totalOrdersCount = filteredOrders.length;
    final uniqueRepsCount = _getUniqueSalesReps(filteredOrders).length;
    final aov = totalOrdersCount > 0 ? (totalRevenue / totalOrdersCount) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Executive Summary Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 750;
              final isMedium = constraints.maxWidth < 1100;
              final double cardWidth = isSmall
                  ? constraints.maxWidth
                  : isMedium
                      ? (constraints.maxWidth - 16) / 2
                      : (constraints.maxWidth - 48) / 4;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Total Revenue',
                      value: AppTheme.formatINR(totalRevenue),
                      subtitle: '$totalOrdersCount SOs • $periodTitle',
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFF059669),
                      bgGradient: [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Total Orders',
                      value: '$totalOrdersCount',
                      subtitle: 'Period: $periodTitle',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF1E6FBF),
                      bgGradient: [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Active Sales Reps',
                      value: '$uniqueRepsCount',
                      subtitle: 'Active in $periodTitle',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF7C3AED),
                      bgGradient: [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      title: 'Average Order Value',
                      value: AppTheme.formatINR(aov),
                      subtitle: 'Mean value in $periodTitle',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFD97706),
                      bgGradient: [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 2. Sales Rep Breakdown Chips
          if (_orders.isNotEmpty) ...[
            _buildRepBreakdownCard(dateFilteredOrders, periodTitle),
            const SizedBox(height: 20),
          ],

          // 3. Master All Users' Orders Table Card
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
                // Header with Month, Date, Rep, and Search Filters
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
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showProvisionUserDialog(context),
                                  icon: const Icon(Icons.person_add_rounded, size: 14),
                                  label: const Text('Provision User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E6FBF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                if (_isAnyFilterActive()) ...[
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: _resetAllFilters,
                                    icon: const Icon(Icons.clear_all_rounded, size: 14, color: Color(0xFFDC2626)),
                                    label: const Text('Reset All Filters', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ],
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
                      child: CircularProgressIndicator(color: Color(0xFF1E6FBF)),
                    ),
                  )
                else if (filteredOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No sales orders match your selected month, date, or filter.',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _orders.isEmpty
                                ? 'No orders have been submitted yet by any sales rep.'
                                : 'Try changing the Month or Date filter, or click "Reset All Filters".',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                          if (_isAnyFilterActive()) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _resetAllFilters,
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text('Show All Orders'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E6FBF),
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
                            columns: const [
                              DataColumn(label: Text('DATE & TIME')),
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
                              final dateStr = h.savedAt != null ? _dateFormat.format(h.savedAt!) : '-';
                              final repEmail = h.createdByEmail.isNotEmpty
                                  ? h.createdByEmail
                                  : (h.salesPerson.isNotEmpty ? h.salesPerson : 'Unknown');
                              final isPushed = h.status == 'PUSHED';
                              final isReverted = h.status == 'REVERTED';

                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>((states) {
                                  if (isReverted) return const Color(0xFFFFFBEB);
                                  if (isPushed) return const Color(0xFFF0FDF4);
                                  return idx % 2 == 0 ? Colors.white : const Color(0xFFFAFCFF);
                                }),
                                cells: [
                                  // Date
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
                                            color: const Color(0xFF7C3AED).withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            repEmail.length >= 2 ? repEmail.substring(0, 2).toUpperCase() : 'U',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          repEmail,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Customer
                                  DataCell(
                                    Text(
                                      h.customerName.isEmpty ? 'N/A' : h.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  // Project
                                  DataCell(Text(h.projectName.isEmpty ? '—' : h.projectName, style: const TextStyle(color: Color(0xFF64748B)))),
                                  // Items count
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
                                  // Status Column
                                  DataCell(_buildAdminStatusBadge(h)),
                                  // Actions
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 1. REVERT BUTTON (Prominent for Admin to revert if problem found)
                                        ElevatedButton.icon(
                                          onPressed: () => _showAdminRevertDialog(h),
                                          icon: const Icon(Icons.undo_rounded, size: 12),
                                          label: const Text('Revert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFD97706),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 4),

                                        // 2. PUSH TO DISPATCH BUTTON (If order is pushed/ready for admin review)
                                        if (isPushed) ...[
                                          ElevatedButton.icon(
                                            onPressed: () => _confirmPushToDispatch(h),
                                            icon: const Icon(Icons.local_shipping_rounded, size: 12),
                                            label: const Text('Push to Dispatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF059669),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],

                                        // Load
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            orderProvider.loadOrder(h);
                                            orderProvider.setTabIndex(0);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Loaded ${h.salesOrderNo} into active form'),
                                                backgroundColor: AppTheme.nav,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.upload_file_rounded, size: 12),
                                          label: const Text('Load', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
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
                                        // Delete
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                                          tooltip: 'Delete Order',
                                          onPressed: () => _confirmDeleteOrder(h, idx),
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
            color: const Color(0xFF7C3AED).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: Color(0xFF7C3AED)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Master Order History ($count)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    periodTitle,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
            const Text(
              'Executive Observer View • All users\' Sales Orders across the organization',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    final reps = _getUniqueSalesReps(_orders);
    final monthsMap = _getUniqueMonths();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. Search Field
        SizedBox(
          width: 175,
          height: 34,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search SO, customer, rep...',
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

        // 2. Month-Wise Selector
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _selectedMonth != 'ALL' ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedMonth != 'ALL' ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
              width: _selectedMonth != 'ALL' ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMonth,
              style: TextStyle(
                fontSize: 12,
                color: _selectedMonth != 'ALL' ? const Color(0xFF6B21A8) : const Color(0xFF1E293B),
                fontWeight: _selectedMonth != 'ALL' ? FontWeight.w800 : FontWeight.w600,
              ),
              icon: Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: _selectedMonth != 'ALL' ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedMonth = val;
                    if (val != 'ALL') {
                      // Reset date filter when selecting specific month
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

        // 3. Date-Wise Selector (Presets + Custom Range)
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
                          primary: Color(0xFF1E6FBF),
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
                    if (val != 'ALL') {
                      _selectedMonth = 'ALL';
                    }
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

        // 4. Sales Rep Dropdown
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _selectedRep != 'ALL' ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedRep != 'ALL' ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
              width: _selectedRep != 'ALL' ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRep,
              style: TextStyle(
                fontSize: 12,
                color: _selectedRep != 'ALL' ? const Color(0xFF92400E) : const Color(0xFF1E293B),
                fontWeight: _selectedRep != 'ALL' ? FontWeight.w800 : FontWeight.w600,
              ),
              icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRep = val);
              },
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('👤 All Sales Reps')),
                ...reps.map((r) => DropdownMenuItem(value: r, child: Text(r))),
              ],
            ),
          ),
        ),

        // 5. Workflow Status Dropdown
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
                DropdownMenuItem(value: 'ALL', child: Text('⚡ All Statuses')),
                DropdownMenuItem(value: 'PUSHED', child: Text('🚀 Pushed (Pending Review)')),
                DropdownMenuItem(value: 'REVERTED', child: Text('⚠️ Reverted')),
                DropdownMenuItem(value: 'READY_FOR_DISPATCH', child: Text('📦 Sent to Dispatch')),
                DropdownMenuItem(value: 'DISPATCHED', child: Text('✓ Dispatched')),
                DropdownMenuItem(value: 'DRAFT', child: Text('📝 Drafts')),
              ],
            ),
          ),
        ),

        // 6. Sort Dropdown
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

        // 6. Refresh Button
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
          tooltip: 'Refresh All Orders',
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepBreakdownCard(List<SalesOrder> sourceOrders, String periodTitle) {
    final Map<String, List<SalesOrder>> byRep = {};
    for (var o in sourceOrders) {
      final rep = o.createdByEmail.isNotEmpty ? o.createdByEmail : (o.salesPerson.isNotEmpty ? o.salesPerson : 'Unknown');
      byRep.putIfAbsent(rep, () => []).add(o);
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              const Icon(Icons.pie_chart_outline_rounded, size: 16, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(
                'Sales Rep Performance ($periodTitle)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              if (_selectedRep != 'ALL')
                InkWell(
                  onTap: () => setState(() => _selectedRep = 'ALL'),
                  child: const Text('Show All Reps', style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (byRep.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No orders recorded in this period.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: byRep.entries.map((entry) {
                final repName = entry.key;
                final repOrders = entry.value;
                final repTotal = repOrders.fold(0.0, (sum, o) => sum + o.grandTotal);
                final isSelected = _selectedRep.toLowerCase() == repName.toLowerCase();

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRep = isSelected ? 'ALL' : repName;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C3AED).withOpacity(0.08) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            repName.length >= 2 ? repName.substring(0, 2).toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${repOrders.length} orders • ${AppTheme.formatINR(repTotal)}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _confirmDeleteOrder(SalesOrder order, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sales Order?'),
        content: Text('Are you sure you want to delete order "${order.salesOrderNo}" submitted by ${order.createdByEmail.isNotEmpty ? order.createdByEmail : "Sales Rep"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CloudOrderService.deleteOrder(order, index);
              await _loadOrders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted order ${order.salesOrderNo}'),
                    backgroundColor: AppTheme.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatusBadge(SalesOrder h) {
    if (h.status == 'PUSHED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF93C5FD)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch_rounded, size: 12, color: Color(0xFF1D4ED8)),
            SizedBox(width: 4),
            Text(
              'Ready for Dispatch',
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
                Icon(Icons.undo_rounded, size: 12, color: Color(0xFFB45309)),
                SizedBox(width: 4),
                Text(
                  'Reverted / Revision',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          if (h.revertReason.isNotEmpty) ...[
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
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
    } else if (h.status == 'READY_FOR_DISPATCH') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_rounded, size: 12, color: Color(0xFF047857)),
            SizedBox(width: 4),
            Text(
              'Sent to Dispatch',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
            ),
          ],
        ),
      );
    } else if (h.status == 'DISPATCHED') {
      return Container(
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

  void _showAdminRevertDialog(SalesOrder order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.undo_rounded, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Revert Order to Sales Rep?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order: ${order.salesOrderNo} • Rep: ${order.createdByEmail.isNotEmpty ? order.createdByEmail : "Sales Rep"}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Specify the issue or correction required so the sales person can edit and re-push the order:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Please correct DN110 quantity from 10 to 5 or change discount to 45%...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a problem description or correction note for the sales person.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await CloudOrderService.revertOrderToRep(order, reason);
              await _loadOrders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.salesOrderNo} reverted to sales rep with note.'),
                    backgroundColor: const Color(0xFFD97706),
                  ),
                );
              }
            },
            icon: const Icon(Icons.undo_rounded, size: 16),
            label: const Text('Revert to Sales Rep'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPushToDispatch(SalesOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: Color(0xFF059669), size: 22),
            SizedBox(width: 8),
            Text('Push to Dispatch Team?'),
          ],
        ),
        content: Text('Send order "${order.salesOrderNo}" to the Dispatch Team for processing and shipment?\n\nThe dispatch team (dispatch@gmail.com) will see this order and can mark it as dispatched.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await CloudOrderService.pushToDispatchTeam(order);
              await _loadOrders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.salesOrderNo} pushed to Dispatch Team! 📦'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Push to Dispatch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showProvisionUserDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Sales Rep';
    String? localError;
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.person_add_rounded, color: Color(0xFF1E6FBF)),
                SizedBox(width: 8),
                Text('Provision Company User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Company accounts must be provisioned by Master Admin or via Firebase Console.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Employee Email (@so.com, @huliot.com)',
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Initial Password (min 6 characters)',
                      prefixIcon: Icon(Icons.lock_outline, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Role',
                      prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Sales Rep', child: Text('Sales Representative')),
                      DropdownMenuItem(value: 'Back Office', child: Text('Commercial Back Office')),
                      DropdownMenuItem(value: 'Dispatch', child: Text('Warehouse Dispatch')),
                      DropdownMenuItem(value: 'Admin', child: Text('Master Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedRole = val);
                    },
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Text(localError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                onPressed: isCreating
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        final pass = passCtrl.text.trim();
                        if (!AuthRoleHelper.isAllowedCompanyDomain(email)) {
                          setDlgState(() => localError = 'Must use an authorized domain (@so.com, @huliot.com)');
                          return;
                        }
                        if (pass.length < 6) {
                          setDlgState(() => localError = 'Password must be at least 6 characters');
                          return;
                        }
                        setDlgState(() {
                          isCreating = true;
                          localError = null;
                        });

                        try {
                          if (Firebase.apps.isNotEmpty) {
                            await FirebaseFirestore.instance.collection('company_users').doc(email.toLowerCase()).set({
                              'email': email.toLowerCase(),
                              'role': selectedRole,
                              'provisionedBy': FirebaseAuth.instance.currentUser?.email ?? 'admin@so.com',
                              'provisionedAt': DateTime.now().toIso8601String(),
                              'status': 'ACTIVE',
                            }, SetOptions(merge: true));
                          }
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Successfully provisioned $email as $selectedRole'),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          }
                        } catch (e) {
                          setDlgState(() {
                            isCreating = false;
                            localError = 'Failed: $e';
                          });
                        }
                      },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Provision User'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6FBF), foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}
