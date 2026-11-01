// File: lib/core/services/firebase_init_service.dart
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseInitService {
  static Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
}

