import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huliot_so_flutter/widgets/views/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders header title and sign in button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Verify presence of title & inputs
    expect(find.textContaining('Huliot'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
    expect(find.byType(ElevatedButton), findsWidgets); // Sign in button
  });

  testWidgets('SECURITY CHECK: LoginScreen blocks unauthorized domains without auto-registering', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Enter unauthorized external email
    final emailField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).last;
    final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');

    await tester.enterText(emailField, 'hacker@evil.com');
    await tester.enterText(passwordField, 'password123');
    await tester.tap(signInBtn);
    await tester.pump();

    // Verify rejection error appears
    expect(find.textContaining('Only authorized company domains'), findsOneWidget);
  });
}
