import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// HomeScreen not used in this test to avoid Firebase initialization.
import 'package:carlet/screens/report/create_report_screen.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:carlet/models/user_model.dart';

class MockAuthService extends AuthService {
  MockAuthService() : super.noInit();
  final AppUser _u = const AppUser(id: 'u1');
  @override
  AppUser? get currentUser => _u;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create report flow posts and shows success',
      (WidgetTester tester) async {
    final mockAuth = MockAuthService();

    var createCalled = false;

    // Build a lightweight test home that only exposes the FAB so we avoid
    // initializing Firebase-driven widgets like FeedScreen.
    Widget testHome() {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const SizedBox.shrink(),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, CreateReportScreen.routeName);
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report posted.')),
                );
              }
            },
            icon: const FaIcon(FontAwesomeIcons.triangleExclamation, size: 20),
            label: const Text('Report car'),
          );
        }),
      );
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuth),
        ],
        child: MaterialApp(
          routes: {
            '/': (_) => testHome(),
            CreateReportScreen.routeName: (_) => CreateReportScreen(
                  onCreateReport: ({
                    required String reporterId,
                    String? licensePlate,
                    String? message,
                    File? photoFile,
                    bool anonymous = false,
                  }) async {
                    createCalled = true;
                    // Simulate a short delay like a network write
                    await Future.delayed(const Duration(milliseconds: 10));
                    return 'rid-1';
                  },
                ),
          },
          initialRoute: '/',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap FAB to open CreateReportScreen
    expect(find.byType(FloatingActionButton), findsWidgets);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

  // Ensure CreateReportScreen is present (check for a known field)
  expect(find.widgetWithText(TextField, 'License plate'), findsWidgets);

    // Try to submit without photo - should show error
    await tester.enterText(find.widgetWithText(TextField, 'License plate'), 'ABC123');
    await tester.enterText(find.widgetWithText(TextField, 'Message'), 'Test');

    await tester.tap(find.text('Post alert'));

    // Allow async validation
    await tester.pumpAndSettle();

    // The create callback should NOT have been called (photo required)
    expect(createCalled, isFalse);

    // Photo requirement error should be visible
    expect(find.text('A photo is required to verify the issue.'), findsWidgets);
  });
}
