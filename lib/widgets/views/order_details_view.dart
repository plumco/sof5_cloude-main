import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/sales_order_provider.dart';
import '../../theme/app_theme.dart';

class OrderDetailsView extends StatefulWidget {
  const OrderDetailsView({super.key});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<SalesOrderProvider>();
    final order = orderProvider.order;
    final lists = orderProvider.dropdownLists;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Sales Order Information
          _buildCard(
            title: 'Sales Order Information',
            subtitle: 'Primary order reference and execution schedule',
            dotIcon: Icons.receipt_long_rounded,
            iconColor: AppTheme.blue,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                return _buildGrid(
                  crossAxisCount: cols,
                  children: [
                    _buildTextField(
                      label: 'Sales Order No.',
                      prefixIcon: Icons.numbers_rounded,
                      initialValue: order.salesOrderNo,
                      onChanged: orderProvider.updateOrderNo,
                    ),
                    _buildDateField(
                      label: 'Order Date',
                      date: order.orderDate,
                      onSelect: orderProvider.updateOrderDate,
                      quickPresets: [
                        {'label': 'Today', 'days': 0},
                        {'label': 'Yesterday', 'days': -1},
                      ],
                    ),
                    _buildDateField(
                      label: 'Required Date',
                      date: order.requiredDate,
                      onSelect: orderProvider.updateRequiredDate,
                      quickPresets: [
                        {'label': '+7d', 'days': 7},
                        {'label': '+15d', 'days': 15},
                        {'label': '+30d', 'days': 30},
                      ],
                    ),
                    _buildTextField(
                      label: 'PO / Reference No.',
                      hint: 'PO / Ref reference',
                      prefixIcon: Icons.tag_rounded,
                      initialValue: order.poNo,
                      onChanged: orderProvider.updatePoNo,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Section 2: Customer + Bill To + Ship To Cards
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCustomerCard(orderProvider)),
                const SizedBox(width: 18),
                Expanded(child: _buildBillToCard(orderProvider)),
                const SizedBox(width: 18),
                Expanded(child: _buildShipToCard(orderProvider)),
              ],
            )
          else
            Column(
              children: [
                _buildCustomerCard(orderProvider),
                const SizedBox(height: 18),
                _buildBillToCard(orderProvider),
                const SizedBox(height: 18),
                _buildShipToCard(orderProvider),
              ],
            ),
          const SizedBox(height: 18),

          // Section 3: Additional Terms & Commercial Details
          _buildCard(
            title: 'Commercial & Delivery Terms',
            subtitle: 'Payment condition, logistics, and site engineer instructions',
            dotIcon: Icons.local_shipping_rounded,
            iconColor: const Color(0xFF10B981),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                    return _buildGrid(
                      crossAxisCount: cols,
                      children: [
                        _buildDropdownField(
                          label: 'Payment Terms',
                          value: order.paymentTerms,
                          items: lists.paymentTerms,
                          prefixIcon: Icons.account_balance_wallet_outlined,
                          onChanged: (val) => orderProvider.updatePaymentTerms(val ?? ''),
                        ),
                        _buildDropdownField(
                          label: 'Salesperson',
                          value: order.salesPerson.isEmpty ? (lists.salesPerson.isNotEmpty ? lists.salesPerson.first : '') : order.salesPerson,
                          items: lists.salesPerson,
                          prefixIcon: Icons.badge_outlined,
                          onChanged: (val) => orderProvider.updateSalesPerson(val ?? ''),
                        ),
                        _buildDropdownField(
                          label: 'Delivery Term',
                          value: order.deliveryTerm,
                          items: lists.freightTerms,
                          prefixIcon: Icons.flight_takeoff_rounded,
                          onChanged: (val) => orderProvider.updateDeliveryTerm(val ?? ''),
                        ),
                        _buildTextField(
                          label: 'Project / Job Name',
                          hint: 'Project or Site Name',
                          prefixIcon: Icons.business_outlined,
                          initialValue: order.projectName,
                          onChanged: orderProvider.updateProjectName,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  label: 'Remarks & Site Instructions',
                  initialValue: order.remarks,
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 3,
                  onChanged: orderProvider.updateRemarks,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(SalesOrderProvider p) {
    final order = p.order;
    return _buildCard(
      title: 'Customer Information',
      subtitle: 'Buyer contact and developer credentials',
      dotIcon: Icons.person_rounded,
      iconColor: AppTheme.blue,
      child: Column(
        children: [
          _buildTextField(
            label: 'Customer Code',
            hint: 'e.g. CUST-9021',
            prefixIcon: Icons.vpn_key_outlined,
            initialValue: order.customerCode,
            onChanged: p.updateCustomerCode,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Customer / Developer Name',
            hint: 'Company / Developer name',
            prefixIcon: Icons.corporate_fare_rounded,
            initialValue: order.customerName,
            onChanged: p.updateCustomerName,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Contact Person',
            hint: 'Primary contact name',
            prefixIcon: Icons.perm_identity_rounded,
            initialValue: order.contactPerson,
            onChanged: p.updateContactPerson,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Phone',
                  hint: 'Office phone',
                  prefixIcon: Icons.phone_outlined,
                  initialValue: order.phone,
                  onChanged: p.updatePhone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Mobile',
                  hint: 'Mobile contact',
                  prefixIcon: Icons.phone_android_rounded,
                  initialValue: order.mobile,
                  onChanged: p.updateMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillToCard(SalesOrderProvider p) {
    final order = p.order;
    return _buildCard(
      title: 'Bill To Address',
      subtitle: 'Official tax invoice billing destination',
      dotIcon: Icons.apartment_rounded,
      iconColor: const Color(0xFF6366F1),
      action: InkWell(
        onTap: () => p.setSameShip(!order.sameShip),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: order.sameShip ? const Color(0xFFEEF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: order.sameShip ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                order.sameShip ? Icons.check_circle : Icons.circle_outlined,
                size: 14,
                color: order.sameShip ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                'Same as Ship To',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: order.sameShip ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Address Line 1',
            hint: 'Premises, Floor, Building',
            prefixIcon: Icons.location_on_outlined,
            initialValue: order.bill1,
            onChanged: p.updateBill1,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Address Line 2',
            hint: 'Street, Industrial Area',
            prefixIcon: Icons.signpost_outlined,
            initialValue: order.bill2,
            onChanged: p.updateBill2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'City / Municipality',
            hint: 'City',
            prefixIcon: Icons.location_city_rounded,
            initialValue: order.billCity,
            onChanged: p.updateBillCity,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  label: 'Province / State',
                  hint: 'State',
                  prefixIcon: Icons.map_outlined,
                  initialValue: order.billProvince,
                  onChanged: p.updateBillProvince,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  label: 'Zip Code',
                  hint: 'PIN / Zip',
                  initialValue: order.billZip,
                  onChanged: p.updateBillZip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipToCard(SalesOrderProvider p) {
    final order = p.order;
    return _buildCard(
      title: 'Ship To Address',
      subtitle: 'Project site delivery location',
      dotIcon: Icons.local_shipping_outlined,
      iconColor: AppTheme.orange,
      action: InkWell(
        onTap: () => p.setSameBill(!order.sameBill),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: order.sameBill ? const Color(0xFFFFF7ED) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: order.sameBill ? AppTheme.orange : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                order.sameBill ? Icons.check_circle : Icons.circle_outlined,
                size: 14,
                color: order.sameBill ? AppTheme.orange : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                'Same as Bill To',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: order.sameBill ? AppTheme.orange : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Address Line 1',
            hint: 'Site address, Gate No.',
            prefixIcon: Icons.location_on_outlined,
            initialValue: order.ship1,
            onChanged: p.updateShip1,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Address Line 2',
            hint: 'Landmark / Project sector',
            prefixIcon: Icons.signpost_outlined,
            initialValue: order.ship2,
            onChanged: p.updateShip2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'City / Municipality',
            hint: 'City',
            prefixIcon: Icons.location_city_rounded,
            initialValue: order.shipCity,
            onChanged: p.updateShipCity,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  label: 'Province / State',
                  hint: 'State',
                  prefixIcon: Icons.map_outlined,
                  initialValue: order.shipProvince,
                  onChanged: p.updateShipProvince,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  label: 'Zip Code',
                  hint: 'PIN / Zip',
                  initialValue: order.shipZip,
                  onChanged: p.updateShipZip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    String? subtitle,
    required IconData dotIcon,
    required Color iconColor,
    Widget? action,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(2, 17, 37, 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(dotIcon, size: 16, color: iconColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: 0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
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
              ),
              if (action != null) action,
            ],
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 28),
          child,
        ],
      ),
    );
  }

  Widget _buildGrid({required int crossAxisCount, required List<Widget> children}) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: children.map((w) {
        return SizedBox(
          width: crossAxisCount == 1 ? double.infinity : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: crossAxisCount == 4
                    ? (MediaQuery.of(context).size.width - 480) / 4 - 18
                    : (crossAxisCount == 3
                        ? (MediaQuery.of(context).size.width - 480) / 3 - 18
                        : (crossAxisCount == 2 ? 320 : double.infinity)),
                child: w,
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required String label,
    String? hint,
    String? initialValue,
    IconData? prefixIcon,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: const Color(0xFF94A3B8)) : null,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onSelect,
    List<Map<String, dynamic>>? quickPresets,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            if (quickPresets != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: quickPresets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () {
                        final days = preset['days'] as int;
                        onSelect(DateTime.now().add(Duration(days: days)));
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          preset['label'] as String,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.blue),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              onSelect(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFDFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD8E2EF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text(
                      _dateFormat.format(date),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    IconData? prefixIcon,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: validValue,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: const Color(0xFF94A3B8)) : null,
          ),
          items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ],
    );
  }
}
