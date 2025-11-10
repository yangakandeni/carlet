import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:carlet/screens/auth/onboarding_screen.dart';
import 'package:carlet/models/user_model.dart';
import 'package:carlet/services/auth_service.dart';

// A small mock AuthService that extends AuthService but uses the noInit
// constructor to avoid Firebase. We override only the members used by the
// onboarding screen: `currentUser` and `completeOnboarding`.
class MockAuthService extends AuthService {
  MockAuthService() : super.noInit();

  AppUser? _fakeUser;
  bool completeCalled = false;
  bool simulateFailure = false;

  set fakeUser(AppUser? u) {
    _fakeUser = u;
    notifyListeners();
  }

  @override
  AppUser? get currentUser => _fakeUser;

  @override
  Future<void> completeOnboarding({
    required String name,
    required String carMake,
    required String carModel,
    required String carColor,
    required String carPlate,
  }) async {
    // Optionally simulate a write failure for testing the error UI
    if (simulateFailure) {
      await Future.delayed(const Duration(milliseconds: 10));
      throw Exception('Simulated write failure');
    }
    // Simulate async write and set onboardingComplete
    completeCalled = true;
    _fakeUser = AppUser(
      id: _fakeUser?.id ?? 'test',
      name: name,
      email: _fakeUser?.email,
      phoneNumber: _fakeUser?.phoneNumber,
      carPlate: carPlate,
      carModel: carModel,
      photoUrl: _fakeUser?.photoUrl,
      deviceToken: _fakeUser?.deviceToken,
      carMake: carMake,
      carColor: carColor,
      onboardingComplete: true,
    );
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen', () {
    testWidgets('happy path: submits and navigates to home',
        (WidgetTester tester) async {
      final mockAuth = MockAuthService();
      mockAuth.fakeUser = const AppUser(id: 'u1', onboardingComplete: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: mockAuth,
          child: MaterialApp(
            routes: {
              '/': (_) => const OnboardingScreen(),
              '/home': (_) => const Scaffold(body: Center(child: Text('Home'))),
            },
            initialRoute: '/',
          ),
        ),
      );

  // Ensure fields are present (name, make, model, color, plate)
  expect(find.byType(TextFormField), findsNWidgets(5));

      // Fill fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Alice');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vehicle make'), 'Toyota');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vehicle model'), 'Corolla');
      await tester.enterText(find.widgetWithText(TextFormField, 'Color'), 'Blue');
      await tester.enterText(find.widgetWithText(TextFormField, 'License plate number'), 'ABC123');

      await tester.tap(find.text('Finish and continue'));

      // Allow async navigation and any state changes to settle
      await tester.pumpAndSettle();

      // Auth method should have been called and navigation to Home should occur
      expect(mockAuth.completeCalled, isTrue);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('blocked case: already onboarded redirects to home',
        (WidgetTester tester) async {
      final mockAuth = MockAuthService();
      mockAuth.fakeUser = const AppUser(id: 'u2', onboardingComplete: true);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: mockAuth,
          child: MaterialApp(
            routes: {
              '/': (_) => const OnboardingScreen(),
              '/home': (_) => const Scaffold(body: Center(child: Text('Home'))),
            },
            initialRoute: '/',
          ),
        ),
      );

      // The OnboardingScreen should immediately navigate to home in initState.
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      // The onboarding form should not be visible
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('error path: shows error when write fails', (WidgetTester tester) async {
      final mockAuth = MockAuthService();
      mockAuth.fakeUser = const AppUser(id: 'u3', onboardingComplete: false);
      mockAuth.simulateFailure = true;

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: mockAuth,
          child: MaterialApp(
            routes: {
              '/': (_) => const OnboardingScreen(),
              '/home': (_) => const Scaffold(body: Center(child: Text('Home'))),
            },
            initialRoute: '/',
          ),
        ),
      );

      // Fill fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Bob');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vehicle make'), 'Honda');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vehicle model'), 'Civic');
      await tester.enterText(find.widgetWithText(TextFormField, 'Color'), 'Red');
      await tester.enterText(find.widgetWithText(TextFormField, 'License plate number'), 'XYZ789');

      await tester.tap(find.text('Finish and continue'));

      // Allow async error to propagate and UI to update
      await tester.pumpAndSettle();

      // Should not navigate to home and should show error container
      expect(find.text('Home'), findsNothing);
  expect(find.textContaining('Unable to save your details'), findsOneWidget);
    });
  });
}
