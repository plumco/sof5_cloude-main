// File: test/unit/app_router_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:huliot_so_flutter/app/router.dart';
import 'package:huliot_so_flutter/widgets/views/login_screen.dart';
import 'package:huliot_so_flutter/app/auth_gate.dart';

void main() {
  group('AppRouter - Role Based Route Generation & Protection Tests', () {
    test('Email role router resolves admin route correctly', () {
      expect(AppRouter.getRouteForEmail('admin@gmail.com'), equals(AppRouter.admin));
      expect(AppRouter.getRouteForEmail('admin@so.com'), equals(AppRouter.admin));
      expect(AppRouter.getRouteForEmail('admin@huliot.com'), equals(AppRouter.admin));
    });

    test('Email role router resolves backoffice route correctly', () {
      expect(AppRouter.getRouteForEmail('backoffice@gmail.com'), equals(AppRouter.backoffice));
      expect(AppRouter.getRouteForEmail('backoffice@so.com'), equals(AppRouter.backoffice));
    });

    test('Email role router resolves dispatch route correctly', () {
      expect(AppRouter.getRouteForEmail('dispatch@gmail.com'), equals(AppRouter.dispatch));
      expect(AppRouter.getRouteForEmail('dispatch@huliot.com'), equals(AppRouter.dispatch));
    });

    test('Email role router resolves sales rep route to /dashboard', () {
      expect(AppRouter.getRouteForEmail('giriraj@huliot.com'), equals(AppRouter.dashboard));
      expect(AppRouter.getRouteForEmail('rep123@gmail.com'), equals(AppRouter.dashboard));
    });

    test('Null or empty email routes to /login safely', () {
      expect(AppRouter.getRouteForEmail(null), equals(AppRouter.login));
      expect(AppRouter.getRouteForEmail(''), equals(AppRouter.login));
      expect(AppRouter.getRouteForEmail('   '), equals(AppRouter.login));
    });

    test('onGenerateRoute creates valid routes for root and login', () {
      final rootRoute = AppRouter.onGenerateRoute(const RouteSettings(name: AppRouter.root)) as MaterialPageRoute;
      final rootWidget = rootRoute.builder(MockBuildContext());
      expect(rootWidget, isA<AuthGate>());

      final loginRoute = AppRouter.onGenerateRoute(const RouteSettings(name: AppRouter.login)) as MaterialPageRoute;
      final loginWidget = loginRoute.builder(MockBuildContext());
      expect(loginWidget, isA<LoginScreen>());
    });

    test('Unknown route gracefully falls back to AuthGate', () {
      final unknownRoute = AppRouter.onGenerateRoute(const RouteSettings(name: '/some_unknown_path')) as MaterialPageRoute;
      final widget = unknownRoute.builder(MockBuildContext());
      expect(widget, isA<AuthGate>());
    });
  });
}

class MockBuildContext extends Fake implements BuildContext {}

