// File: lib/app/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import '../core/constants/app_constants.dart';
import '../widgets/views/login_screen.dart';
import 'dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _ensureFirebase();
  }

  Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppConstants.bgDark,
            body: Center(
              child: CircularProgressIndicator(color: AppConstants.primaryBlue),
            ),
          );
        }
        if (initSnapshot.hasError || Firebase.apps.isEmpty) {
          return const LoginScreen();
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppConstants.bgDark,
                body: Center(
                  child: CircularProgressIndicator(color: AppConstants.primaryBlue),
                ),
              );
            }
            if (snapshot.hasData) {
              return const DashboardScreen();
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}

