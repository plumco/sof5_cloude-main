// File: lib/main.dart
import 'package:flutter/material.dart';
import 'core/services/firebase_init_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitService.init();
  runApp(const HuliotSalesOrderApp());
}
