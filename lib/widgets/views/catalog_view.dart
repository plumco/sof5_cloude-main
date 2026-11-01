import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/sales_order_provider.dart';
import '../../theme/app_theme.dart';
import '../editable_quantity_stepper.dart';

class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, double> _rowDiscounts = {};
  final Map<String, int> _rowQuantities = {};
  bool _isTableView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final orderProvider = context.read<SalesOrderProvider>();
    final products = catalog.filteredProducts;
    final totalCount = products.length;
    final displayedProducts = products.take(100).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP FILTER CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group / Family Category Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CatalogProvider.groupList.map((g) {
                      final isActive = catalog.selectedGroup == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => catalog.setGroup(g),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              g,
                              style: TextStyle(
                                color: isActive ? Colors.white : const Color(0xFF475569),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 24),

                // SELECT SIZE (DN) Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SELECT SIZE (DN)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '${catalog.sortedDnList.length} sizes available',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Size Cards Row (Vertical Box Layout matching reference UI)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // ALL button
                      _buildSizeCard(
                        label: 'ALL',
                        count: '${catalog.allProducts.where((p) => catalog.selectedGroup == 'All' || p.family == catalog.selectedGroup).length}',
                        isActive: catalog.selectedDn == 'All',
                        onTap: () => catalog.setDn('All'),
                      ),
                      ...catalog.sortedDnList.map((entry) {
                        final isActive = catalog.selectedDn == entry.key;
                        return _buildSizeCard(
                          label: 'DN${entry.key}',
                          count: '${entry.value}',
                          isActive: isActive,
                          onTap: () => catalog.setDn(entry.key),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Sub-group Type Chips with vibrant pastel styling
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CatalogProvider.allTypesList.where((t) {
                      if (t == 'All') return true;
                      return (catalog.typeCounts[t] ?? 0) > 0;
                    }).map((t) {
                      final isActive = catalog.selectedType == t;
                      final count = t == 'All' ? totalCount : (catalog.typeCounts[t] ?? 0);
                      return _buildTypeChip(
                        type: t,
                        count: count,
                        isActive: isActive,
                        onTap: () => catalog.setType(t),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Search Box
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Search item code, description, size...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                catalog.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) => catalog.setSearchQuery(val),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Counter & View Switcher Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$totalCount items',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        if (_searchController.text.isNotEmpty ||
                            catalog.selectedDn != 'All' ||
                            catalog.selectedType != 'All' ||
                            catalog.selectedGroup != 'All')
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              catalog.setGroup('All');
                              catalog.setDn('All');
                              catalog.setType('All');
                              catalog.setSearchQuery('');
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 14),
                              child: Text(
                                'Reset Filters',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // View Mode Toggle (Cards vs Table)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildViewToggleButton(
                                icon: Icons.view_agenda_rounded,
                                label: 'Cards',
                                isSelected: !_isTableView,
                                onTap: () => setState(() => _isTableView = false),
                              ),
                              _buildViewToggleButton(
                                icon: Icons.table_chart_rounded,
                                label: 'Table',
                                isSelected: _isTableView,
                                onTap: () => setState(() => _isTableView = true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. PRODUCTS DISPLAY CONTAINER
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppTheme.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: catalog.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : displayedProducts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(60),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFF94A3B8)),
                              SizedBox(height: 12),
                              Text(
                                'No items found matching your filters.',
                                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _isTableView
                        ? _buildTableView(context, displayedProducts, orderProvider)
                        : _buildCardsView(context, displayedProducts, orderProvider, totalCount),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CARDS VIEW (1-TO-1 MATCH WITH REFERENCE IMAGE)
  // -------------------------------------------------------------
  Widget _buildCardsView(
    BuildContext context,
    List<Product> displayedProducts,
    SalesOrderProvider orderProvider,
    int totalCount,
  ) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedProducts.length,
          separatorBuilder: (context, index) => const Divider(
            color: Color(0xFFF1F5F9),
            height: 1,
            thickness: 1,
          ),
          itemBuilder: (context, index) {
            final p = displayedProducts[index];
            return _buildProductCardRow(context, p, orderProvider);
          },
        ),
        if (totalCount > 100)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Showing 100 of $totalCount items. Refine size or search to see more.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductCardRow(
    BuildContext context,
    Product p,
    SalesOrderProvider orderProvider,
  ) {
    final disc = _rowDiscounts[p.itemCode] ?? 52.0;
    final qty = _rowQuantities[p.itemCode] ?? 1;
    final net = p.calculateNetPrice(disc);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Column: Item Code, Description, Tag Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Code (grey, clickable to copy)
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: p.itemCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied ${p.itemCode} to clipboard'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.itemCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 10, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // Description (Bold Dark Text)
                Text(
                  p.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 6),

                // Badges Row: DN badge + Type badge + Sub-group / Spec
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (p.dn != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          'DN${p.dn}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    if (p.type.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          p.type,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    if (p.subGroup.isNotEmpty)
                      Text(
                        p.subGroup,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Column: Price at top, Quantity Stepper & Add Button below
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Net Price (Large Bold Currency)
              Text(
                AppTheme.formatINR(net, removeDecimals: true),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Quantity Stepper & + Add Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Editable Quantity Stepper (Supports direct typing or +/- buttons)
                  EditableQuantityStepper(
                    value: qty,
                    onChanged: (newQty) {
                      setState(() {
                        _rowQuantities[p.itemCode] = newQty;
                      });
                    },
                  ),
                  const SizedBox(width: 8),

                  // + Add Button (Navy Blue matching reference UI)
                  ElevatedButton(
                    onPressed: () {
                      final currentQty = _rowQuantities[p.itemCode] ?? 1;
                      final currentDisc = _rowDiscounts[p.itemCode] ?? 52.0;
                      final bool added = orderProvider.addItemFromCatalog(p, currentQty, currentDisc);

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (!added) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Cannot edit Dispatched order. Contact Admin'),
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${p.itemCode} ($currentQty pcs) to cart'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF0F172A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text(
                      '+ Add',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // DATA TABLE VIEW (CLEAN DATA GRID WITH MATCHING COLORS)
  // -------------------------------------------------------------
  Widget _buildTableView(
    BuildContext context,
    List<Product> displayedProducts,
    SalesOrderProvider orderProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final descWidth = (constraints.maxWidth - 580).clamp(240.0, 650.0);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              dataRowMinHeight: 54,
              dataRowMaxHeight: 62,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingTextStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.4,
              ),
              dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
              columnSpacing: 20,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Text('ITEM CODE')),
                DataColumn(label: Text('DESCRIPTION')),
                DataColumn(label: Text('DN')),
                DataColumn(label: Text('MOQ')),
                DataColumn(label: Text('LIST PRICE')),
                DataColumn(label: Text('DISC %')),
                DataColumn(label: Text('NET PRICE')),
                DataColumn(label: Text('ACTION')),
              ],
              rows: displayedProducts.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final disc = _rowDiscounts[p.itemCode] ?? 52.0;
                final qty = _rowQuantities[p.itemCode] ?? 1;
                final net = p.calculateNetPrice(disc);

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) {
                      return const Color(0xFFF1F5F9);
                    }
                    return idx % 2 == 0 ? Colors.white : const Color(0xFFFAFCFF);
                  }),
                  cells: [
                    // Item Code with copy action
                    DataCell(
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: p.itemCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied ${p.itemCode} to clipboard'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.itemCode,
                              style: const TextStyle(
                                color: Color(0xFF1F61B7),
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 12, color: Color(0xFFA0AEC0)),
                          ],
                        ),
                      ),
                    ),
                    // Description (with Image 1 badge box)
                    DataCell(
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: descWidth),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 5,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Green DN pill badge (Image 1)
                                  if (p.dn != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: Text(
                                        'DN${p.dn}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                  // Blue Type / Category pill badge (Image 1)
                                  if (p.type.isNotEmpty && p.type != 'All')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(
                                        p.type,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    )
                                  else if (p.category.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(
                                        p.category,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  // Sub-group specification grey text (Image 1)
                                  if (p.subGroup.isNotEmpty)
                                    Text(
                                      p.subGroup.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // DN Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          p.dn != null ? 'DN${p.dn}' : '-',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669), fontSize: 11),
                        ),
                      ),
                    ),
                    // MOQ
                    DataCell(Text('${p.moq}')),
                    // List Price
                    DataCell(
                      Text(
                        AppTheme.formatINR(p.listPrice, removeDecimals: true),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ),
                    // Discount % Input
                    DataCell(
                      SizedBox(
                        width: 72,
                        height: 34,
                        child: TextFormField(
                          initialValue: disc.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            suffixText: '%',
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 52.0;
                            setState(() {
                              _rowDiscounts[p.itemCode] = parsed;
                            });
                          },
                        ),
                      ),
                    ),
                    // Net Price
                    DataCell(
                      Text(
                        AppTheme.formatINR(net, removeDecimals: true),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 13),
                      ),
                    ),
                    // Quantity Stepper & Add Button
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Editable Quantity Stepper (Supports direct typing or +/- buttons)
                          EditableQuantityStepper(
                            value: qty,
                            onChanged: (newQty) {
                              setState(() {
                                _rowQuantities[p.itemCode] = newQty;
                              });
                            },
                          ),
                          const SizedBox(width: 8),

                          ElevatedButton.icon(
                            onPressed: () {
                              final currentQty = _rowQuantities[p.itemCode] ?? 1;
                              final currentDisc = _rowDiscounts[p.itemCode] ?? 52.0;
                              final bool added = orderProvider.addItemFromCatalog(p, currentQty, currentDisc);

                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              if (!added) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('❌ Cannot edit Dispatched order. Contact Admin'),
                                    duration: Duration(seconds: 3),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${p.itemCode} ($currentQty pcs) to cart'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: const Color(0xFF0F172A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 13),
                            label: const Text('+ Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF334155),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
    );
  }

  // -------------------------------------------------------------
  // SIZE CARD WIDGET (VERTICAL BOX MATCHING REFERENCE UI)
  // -------------------------------------------------------------
  Widget _buildSizeCard({
    required String label,
    required String count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 54,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE2E8F0) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
              width: isActive ? 1.8 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.02),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count,
                style: TextStyle(
                  color: isActive ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SUB-GROUP TYPE CHIP (PASTEL PILLS MATCHING REFERENCE UI)
  // -------------------------------------------------------------
  Widget _buildTypeChip({
    required String type,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final style = _typeStyles[type] ??
        const _TypeChipStyle(
          bg: Color(0xFFF8FAFC),
          border: Color(0xFFCBD5E1),
          text: Color(0xFF334155),
          activeBg: Color(0xFF0F172A),
          iconSymbol: '•',
        );

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? style.activeBg : style.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? style.activeBg : style.border,
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: style.activeBg.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (style.iconSymbol.isNotEmpty) ...[
                Text(
                  style.iconSymbol,
                  style: TextStyle(
                    color: isActive ? Colors.white : style.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                type == 'All' ? 'All' : type,
                style: TextStyle(
                  color: isActive ? Colors.white : style.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.22)
                      : style.border.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? Colors.white : style.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // VIEW TOGGLE BUTTON
  // -------------------------------------------------------------
  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, _TypeChipStyle> _typeStyles = {
    'All': _TypeChipStyle(
      bg: Color(0xFFF1F5F9),
      border: Color(0xFFCBD5E1),
      text: Color(0xFF0F172A),
      activeBg: Color(0xFF071A34),
      iconSymbol: '•',
    ),
    'Pipe': _TypeChipStyle(
      bg: Color(0xFFF0F9FF),
      border: Color(0xFF7DD3FC),
      text: Color(0xFF0284C7),
      activeBg: Color(0xFF0284C7),
      iconSymbol: '—',
    ),
    'Bend': _TypeChipStyle(
      bg: Color(0xFFFFF7ED),
      border: Color(0xFFFDBA74),
      text: Color(0xFFEA580C),
      activeBg: Color(0xFFEA580C),
      iconSymbol: '↩',
    ),
    'Tee': _TypeChipStyle(
      bg: Color(0xFFF0FDF4),
      border: Color(0xFF86EFAC),
      text: Color(0xFF16A34A),
      activeBg: Color(0xFF16A34A),
      iconSymbol: 'v',
    ),
    'Branch': _TypeChipStyle(
      bg: Color(0xFFF0FDF4),
      border: Color(0xFF86EFAC),
      text: Color(0xFF16A34A),
      activeBg: Color(0xFF16A34A),
      iconSymbol: 'v',
    ),
    'Trap': _TypeChipStyle(
      bg: Color(0xFFFAF5FF),
      border: Color(0xFFD8B4FE),
      text: Color(0xFF9333EA),
      activeBg: Color(0xFF9333EA),
      iconSymbol: 'U',
    ),
    'Coupler': _TypeChipStyle(
      bg: Color(0xFFECFEFF),
      border: Color(0xFF67E8F9),
      text: Color(0xFF0891B2),
      activeBg: Color(0xFF0891B2),
      iconSymbol: '○',
    ),
    'Reducer': _TypeChipStyle(
      bg: Color(0xFFFFF1F2),
      border: Color(0xFFFDA4AF),
      text: Color(0xFFE11D48),
      activeBg: Color(0xFFE11D48),
      iconSymbol: '<',
    ),
    'Inspection': _TypeChipStyle(
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFCD34D),
      text: Color(0xFFD97706),
      activeBg: Color(0xFFD97706),
      iconSymbol: '◎',
    ),
    'Clamp': _TypeChipStyle(
      bg: Color(0xFFFEF2F2),
      border: Color(0xFFFCA5A5),
      text: Color(0xFFDC2626),
      activeBg: Color(0xFFDC2626),
      iconSymbol: '∩',
    ),
    'Flange': _TypeChipStyle(
      bg: Color(0xFFF8FAFC),
      border: Color(0xFF94A3B8),
      text: Color(0xFF475569),
      activeBg: Color(0xFF475569),
      iconSymbol: '⊚',
    ),
    'End Cap': _TypeChipStyle(
      bg: Color(0xFFF1F5F9),
      border: Color(0xFF94A3B8),
      text: Color(0xFF334155),
      activeBg: Color(0xFF334155),
      iconSymbol: '⊣',
    ),
    'Valve': _TypeChipStyle(
      bg: Color(0xFFF5F3FF),
      border: Color(0xFFC4B5FD),
      text: Color(0xFF7C3AED),
      activeBg: Color(0xFF7C3AED),
      iconSymbol: '⧓',
    ),
    'Fitting': _TypeChipStyle(
      bg: Color(0xFFEEF2FF),
      border: Color(0xFFA5B4FC),
      text: Color(0xFF4F46E5),
      activeBg: Color(0xFF4F46E5),
      iconSymbol: '⚙',
    ),
    'Tools': _TypeChipStyle(
      bg: Color(0xFFF0FDFA),
      border: Color(0xFF5EEAD4),
      text: Color(0xFF0D9488),
      activeBg: Color(0xFF0D9488),
      iconSymbol: '★',
    ),
    'Accessory': _TypeChipStyle(
      bg: Color(0xFFF0FDFA),
      border: Color(0xFF5EEAD4),
      text: Color(0xFF0D9488),
      activeBg: Color(0xFF0D9488),
      iconSymbol: '★',
    ),
  };
}

class _TypeChipStyle {
  final Color bg;
  final Color border;
  final Color text;
  final Color activeBg;
  final String iconSymbol;

  const _TypeChipStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.activeBg,
    this.iconSymbol = '',
  });
}
