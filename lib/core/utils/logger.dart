// File: lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String msg) {
    if (kDebugMode) {
      debugPrint('[APP] $msg');
    }
  }

  static void error(String msg, dynamic e) {
    if (kDebugMode) {
      debugPrint('[ERROR] $msg: $e');
    }
  }
}

