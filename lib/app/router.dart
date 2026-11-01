// File: lib/app/router.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_role_helper.dart';
import '../widgets/views/login_screen.dart';
import '../widgets/views/admin_dashboard_view.dart';
import '../widgets/views/dispatch_dashboard_view.dart';
import '../widgets/views/backoffice_dashboard_view.dart';
import '../shared/widgets/app_header.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'auth_gate.dart';

class AppRouter {
  static const String root = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String admin = '/admin';
  static const String dispatch = '/dispatch';
  static const String backoffice = '/backoffice';

  /// Determines target route based on user email role
  static String getRouteForEmail(String? email) {
    if (email == null || email.trim().isEmpty) return login;
    if (AuthRoleHelper.isAdmin(email)) return admin;
    if (AuthRoleHelper.isBackOffice(email)) return backoffice;
    if (AuthRoleHelper.isDispatch(email)) return dispatch;
    return dashboard;
  }

  /// Master route generator with role guards
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}
    final email = user?.email;

    switch (settings.name) {
      case root:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGate(),
        );

      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => user == null ? const LoginScreen() : const DashboardScreen(),
        );

      case admin:
        if (user == null) {
          return MaterialPageRoute(settings: settings, builder: (_) => const LoginScreen());
        }
        if (!AuthRoleHelper.isAdmin(email)) {
          return MaterialPageRoute(settings: settings, builder: (_) => const DashboardScreen());
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _RolePageScaffold(
            title: '👑 Admin Master Oversight',
            portalLabel: 'Admin Oversight Portal',
            badgeColor: Color(0xFFF59E0B),
            child: AdminDashboardView(),
          ),
        );

      case dispatch:
        if (user == null) {
          return MaterialPageRoute(settings: settings, builder: (_) => const LoginScreen());
        }
        if (!AuthRoleHelper.isDispatch(email) && !AuthRoleHelper.isAdmin(email)) {
          return MaterialPageRoute(settings: settings, builder: (_) => const DashboardScreen());
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _RolePageScaffold(
            title: '📦 Dispatch Operations',
            portalLabel: 'Dispatch Portal',
            badgeColor: Color(0xFF059669),
            child: DispatchDashboardView(),
          ),
        );

      case backoffice:
        if (user == null) {
          return MaterialPageRoute(settings: settings, builder: (_) => const LoginScreen());
        }
        if (!AuthRoleHelper.isBackOffice(email) && !AuthRoleHelper.isAdmin(email)) {
          return MaterialPageRoute(settings: settings, builder: (_) => const DashboardScreen());
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _RolePageScaffold(
            title: '🏢 Back Office Review',
            portalLabel: 'Back Office Portal',
            badgeColor: AppTheme.blue,
            child: BackOfficeDashboardView(),
          ),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGate(),
        );
    }
  }

  /// Programmatic navigation helper
  static Future<T?> navigateTo<T>(BuildContext context, String routeName) {
    return Navigator.pushNamed<T>(context, routeName);
  }

  /// Navigate according to current authenticated role
  static void navigateRoleHome(BuildContext context) {
    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}
    final target = getRouteForEmail(user?.email);
    Navigator.pushReplacementNamed(context, target);
  }
}

/// Standalone scaffold wrapper with AppHeader and container styling for direct routes
class _RolePageScaffold extends StatelessWidget {
  final String title;
  final String portalLabel;
  final Color badgeColor;
  final Widget child;

  const _RolePageScaffold({
    required this.title,
    required this.portalLabel,
    required this.badgeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
                      // Header Tab Bar
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
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.08),
                                border: Border(
                                  bottom: BorderSide(color: badgeColor, width: 3),
                                ),
                              ),
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Role Content View
                      Expanded(child: child),
                      // Standard Footer
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
                          children: [
                            const Text(
                              '© 2026 Huliot Pipes & Fittings Pvt. Ltd. All rights reserved.',
                              style: TextStyle(color: Color(0xFF6A7890), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'v12.0 • $portalLabel',
                              style: const TextStyle(color: Color(0xFF6A7890), fontSize: 11),
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
}
