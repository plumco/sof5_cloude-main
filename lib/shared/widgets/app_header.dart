// File: lib/shared/widgets/app_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/sales_order_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_role_helper.dart';
import '../../services/notification_service.dart';
import '../../features/orders/models/app_notification.dart';
import 'package:intl/intl.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<SalesOrderProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isWide = screenWidth >= 1100;
    final showProfile = screenWidth >= 900;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.nav, AppTheme.nav2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo Badge + Title (Flexible)
          Expanded(
            child: InkWell(
              onTap: () => orderProvider.setTabIndex(0),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9E1B), AppTheme.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(255, 138, 0, 0.35),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'HPF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      isMobile ? 'Huliot SO' : 'Huliot Pipes & Fittings - Sales Order',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Search button (wide screens)
          if (isWide) ...[
            InkWell(
              onTap: () => orderProvider.setTabIndex(1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.white70, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Search catalog...',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Live Targeted Notification Center
          Builder(builder: (context) {
            final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
            return StreamBuilder<List<AppNotification>>(
              stream: NotificationService.streamUserNotifications(userEmail),
              builder: (context, snapshot) {
                final notifs = snapshot.data ?? [];
                final unreadCount = notifs.where((n) => !n.isRead).length;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        unreadCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                        color: unreadCount > 0 ? AppTheme.orange : Colors.white70,
                        size: 20,
                      ),
                      tooltip: unreadCount > 0 ? '$unreadCount unread notifications' : 'Notifications',
                      onPressed: () => _showNotificationCenter(context, userEmail, notifs),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          }),
          const SizedBox(width: 6),

          // Cart Button with Dynamic Badge
          InkWell(
            onTap: () => orderProvider.toggleSidebar(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: orderProvider.isSidebarVisible
                    ? AppTheme.orange.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: orderProvider.isSidebarVisible ? AppTheme.orange : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: orderProvider.isSidebarVisible ? AppTheme.orange : Colors.white,
                    size: 18,
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Cart',
                      style: TextStyle(
                        color: orderProvider.isSidebarVisible ? AppTheme.orange : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${orderProvider.cartCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Profile Pill with Sign Out (reactive via StreamBuilder)
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final email = user?.email ?? '';
              final initials = email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'U';
              final isAdmin = AuthRoleHelper.isAdmin(email);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAdmin ? const Color(0xFFF59E0B).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAdmin ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAdmin
                              ? [const Color(0xFFF59E0B), const Color(0xFFB45309)]
                              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (showProfile) ...[
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Builder(builder: (_) {
                            final isBackOffice = AuthRoleHelper.isBackOffice(email);
                            final isDispatch = AuthRoleHelper.isDispatch(email);

                            String roleLabel = 'Sales Rep';
                            Color roleColor = const Color(0xFF94A3B8);
                            Color roleBg = Colors.white.withValues(alpha: 0.06);

                            if (isAdmin) {
                              roleLabel = '👑 ADMIN (Observer)';
                              roleColor = const Color(0xFFFBBF24);
                              roleBg = const Color(0xFFF59E0B).withValues(alpha: 0.2);
                            } else if (isBackOffice) {
                              roleLabel = '🏢 BACK OFFICE';
                              roleColor = const Color(0xFF60A5FA);
                              roleBg = const Color(0xFF2563EB).withValues(alpha: 0.2);
                            } else if (isDispatch) {
                              roleLabel = '📦 DISPATCH';
                              roleColor = const Color(0xFF34D399);
                              roleBg = const Color(0xFF059669).withValues(alpha: 0.2);
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleLabel,
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 9,
                                  fontWeight: (isAdmin || isBackOffice || isDispatch)
                                      ? FontWeight.w800
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(width: 4),
                    ],
                    // Sign Out Button
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 16),
                      tooltip: 'Sign Out',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseAuth.instance.signOut();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationCenter(
    BuildContext context,
    String userEmail,
    List<AppNotification> notifs,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications, color: AppTheme.orange, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              if (notifs.any((n) => !n.isRead))
                TextButton(
                  onPressed: () async {
                    await NotificationService.markAllAsRead(userEmail);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          content: SizedBox(
            width: 480,
            height: 420,
            child: notifs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You will receive alerts when your orders are dispatched or updated.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final n = notifs[i];
                      IconData icon;
                      Color iconColor;

                      if (n.type == 'DISPATCH') {
                        icon = Icons.local_shipping;
                        iconColor = Colors.green;
                      } else if (n.type == 'REVERT') {
                        icon = Icons.warning_amber_rounded;
                        iconColor = Colors.red;
                      } else if (n.type == 'READY_FOR_DISPATCH') {
                        icon = Icons.inventory_2_outlined;
                        iconColor = AppTheme.blue;
                      } else {
                        icon = Icons.info_outline;
                        iconColor = AppTheme.orange;
                      }

                      return Container(
                        color: n.isRead ? Colors.transparent : Colors.amber.withValues(alpha: 0.05),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: iconColor.withValues(alpha: 0.15),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 13,
                              color: n.isRead ? Colors.black87 : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(n.message, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(n.timestamp),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (!n.isRead) {
                              await NotificationService.markAsRead(n.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

