// File: lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/sales_order_provider.dart';
import '../providers/order_history_provider.dart';
import '../theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import 'router.dart';

class HuliotSalesOrderApp extends StatelessWidget {
  const HuliotSalesOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => SalesOrderProvider()),
        ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: AppRouter.root,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
