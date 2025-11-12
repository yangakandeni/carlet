import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:carlet/screens/profile/profile_screen.dart';
import 'package:carlet/screens/auth/login_screen.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:carlet/models/user_model.dart';

/// Minimal test double for AuthService that avoids Firebase initialization.
class TestAuthService extends AuthService {
  AppUser? _user;
  bool signOutCalled = false;

  TestAuthService(this._user) : super.noInit();

  @override
  AppUser? get currentUser => _user;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<AppUser> updateProfile({String? name, String? email, String? photoUrl}) async {
    // update in-memory user
    _user = AppUser(
      id: _user!.id,
      name: name ?? _user!.name,
      email: email ?? _user!.email,
      phoneNumber: _user!.phoneNumber,
      carPlate: _user!.carPlate,
      carModel: _user!.carModel,
      carMake: _user!.carMake,
      photoUrl: photoUrl ?? _user!.photoUrl,
      deviceToken: _user!.deviceToken,
      onboardingComplete: _user!.onboardingComplete,
    );
    return _user!;
  }
}

void main() {
  testWidgets('sign out flow from profile screen', (WidgetTester tester) async {
    const testUser = AppUser(
      id: 'u1',
      name: 'Test User',
      email: 'test@example.com',
      carPlate: 'ABC123',
      carModel: 'Model',
      carMake: 'Make',
      onboardingComplete: true,
    );

    final auth = TestAuthService(testUser);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: auth,
        child: MaterialApp(
          routes: {
            LoginScreen.routeName: (_) => const Scaffold(body: Center(child: Text('LOGIN'))),
          },
          home: const ProfileScreen(),
        ),
      ),
    );

  // Ensure Profile UI rendered (check for name field instead of AppBar title)
  expect(find.widgetWithText(TextField, 'Full name'), findsOneWidget);
    expect(find.text('Sign out'), findsWidgets);

  // Tap the Sign out button (the one in the profile UI)
  await tester.tap(find.text('Sign out').first);
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('Are you sure you want to sign out?'), findsOneWidget);

    // Confirm sign out via dialog button
    final signOutDialogButton = find.widgetWithText(TextButton, 'Sign out');
    expect(signOutDialogButton, findsWidgets);
    // The dialog button should be the last matching TextButton
    await tester.tap(signOutDialogButton.last);
    await tester.pumpAndSettle();

    // Auth signOut should have been called and navigation to login should occur
    expect(auth.signOutCalled, isTrue);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
