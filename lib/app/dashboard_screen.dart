// File: lib/app/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/sales_order_provider.dart';
import '../theme/app_theme.dart';
import '../shared/widgets/app_header.dart';
import '../shared/widgets/cart_sidebar.dart';
import '../widgets/views/order_details_view.dart';
import '../widgets/views/catalog_view.dart';
import '../widgets/views/cart_summary_view.dart';
import '../widgets/views/order_history_view.dart';
import '../widgets/views/admin_dashboard_view.dart';
import '../widgets/views/dispatch_dashboard_view.dart';
import '../widgets/views/backoffice_dashboard_view.dart';
import '../services/auth_role_helper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<SalesOrderProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1050;
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = AuthRoleHelper.isAdmin(user?.email);
    final isBackOffice = AuthRoleHelper.isBackOffice(user?.email);
    final isDispatch = AuthRoleHelper.isDispatch(user?.email);

    // BackOffice-only users get a dedicated Back Office Review view
    if (isBackOffice && !isAdmin) {
      return Scaffold(
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1540),
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD9E4F2)),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Tab Header
                        Container(
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: AppTheme.line)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  border: Border(
                                    bottom: BorderSide(color: AppTheme.blue, width: 3),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.business_center, size: 16, color: AppTheme.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      '🏢 Back Office Review',
                                      style: TextStyle(
                                        color: AppTheme.blue,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Back Office View
                        const Expanded(child: BackOfficeDashboardView()),
                        // Footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFCFF),
                            border: Border(top: BorderSide(color: Color(0xFFE2EBF6))),
                          ),
                          child: const Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                '© 2026 Huliot Pipes & Fittings Pvt. Ltd. All rights reserved.',
                                style: TextStyle(color: Color(0xFF6A7890), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'v12.0 • Back Office Portal',
                                style: TextStyle(color: Color(0xFF6A7890), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Dispatch-only users get a simplified view
    if (isDispatch && !isAdmin) {
      return Scaffold(
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1540),
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD9E4F2)),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Single Tab Header
                        Container(
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: AppTheme.line)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0FDF4),
                                  border: Border(
                                    bottom: BorderSide(color: Color(0xFF059669), width: 3),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.local_shipping_rounded, size: 16, color: Color(0xFF059669)),
                                    SizedBox(width: 8),
                                    Text(
                                      '📦 Dispatch Dashboard',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Dispatch View
                        const Expanded(child: DispatchDashboardView()),
                        // Footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFCFF),
                            border: Border(top: BorderSide(color: Color(0xFFE2EBF6))),
                          ),
                          child: const Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                '© 2026 Huliot Pipes & Fittings Pvt. Ltd. All rights reserved.',
                                style: TextStyle(color: Color(0xFF6A7890), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'v12.0 • Dispatch Portal',
                                style: TextStyle(color: Color(0xFF6A7890), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // 1. Top Header
          const AppHeader(),

          // 2. Main Content Area + Sidebar
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1540),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Main Container
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFD9E4F2)),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Tab Navigation Header
                                Container(
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    border: Border(bottom: BorderSide(color: AppTheme.line)),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildTabItem(context, 0, 'Order Details', Icons.edit_note_rounded, null, orderProvider),
                                        _buildTabItem(context, 1, 'Catalog', Icons.inventory_2_outlined, null, orderProvider),
                                        _buildTabItem(
                                          context,
                                          2,
                                          'Cart Summary',
                                          Icons.shopping_cart_outlined,
                                          orderProvider.cartCount > 0 ? '${orderProvider.cartCount}' : null,
                                          orderProvider,
                                        ),
                                        _buildTabItem(context, 3, 'Order History', Icons.history_rounded, null, orderProvider),
                                        if (isAdmin)
                                          _buildTabItem(
                                            context,
                                            4,
                                            '🏢 Back Office',
                                            Icons.business_center,
                                            null,
                                            orderProvider,
                                          ),
                                        if (isAdmin)
                                          _buildTabItem(
                                            context,
                                            5,
                                            '📦 Dispatch',
                                            Icons.local_shipping_rounded,
                                            null,
                                            orderProvider,
                                          ),
                                        if (isAdmin)
                                          _buildTabItem(
                                            context,
                                            6,
                                            '👑 Admin (Observer)',
                                            Icons.admin_panel_settings_rounded,
                                            'ALL SO',
                                            orderProvider,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Active View Content
                                Expanded(
                                  child: IndexedStack(
                                    index: orderProvider.currentTabIndex.clamp(0, isAdmin ? 6 : 3),
                                    children: [
                                      const OrderDetailsView(),
                                      const CatalogView(),
                                      const CartSummaryView(),
                                      const OrderHistoryView(),
                                      if (isAdmin) const BackOfficeDashboardView(),
                                      if (isAdmin) const DispatchDashboardView(),
                                      if (isAdmin) const AdminDashboardView(),
                                    ],
                                  ),
                                ),

                                // Footer
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFAFCFF),
                                    border: Border(top: BorderSide(color: Color(0xFFE2EBF6))),
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: const [
                                      Text(
                                        '© 2026 Huliot Pipes & Fittings Pvt. Ltd. All rights reserved.',
                                        style: TextStyle(color: Color(0xFF6A7890), fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'v12.0 • Standalone Flutter Edition',
                                        style: TextStyle(color: Color(0xFF6A7890), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Sidebar (Desktop layout)
                        if (isDesktop && orderProvider.isSidebarVisible) ...[
                          const SizedBox(width: 16),
                          const CartSidebar(),
                        ],
                      ],
                    ),
                  ),
                ),

                // Floating Cart Summary Button (when sidebar is hidden or on smaller screens)
                if (!orderProvider.isSidebarVisible || !isDesktop)
                  Positioned(
                    right: 20,
                    top: 20,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!isDesktop) {
                          // Open modal drawer on mobile
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (ctx) => Container(
                              height: MediaQuery.of(context).size.height * 0.85,
                              padding: const EdgeInsets.all(12),
                              child: const CartSidebar(),
                            ),
                          );
                        } else {
                          orderProvider.setSidebarVisible(true);
                        }
                      },
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: AppTheme.orange),
                      label: Text(
                        '🛒 Cart Summary (${orderProvider.cartCount})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dark,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.orange, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, String title, IconData icon, String? badge, SalesOrderProvider provider) {
    final isActive = provider.currentTabIndex == index;
    return InkWell(
      onTap: () => provider.setTabIndex(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF8FBFF) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.blue : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? AppTheme.blue : const Color(0xFF536079),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

