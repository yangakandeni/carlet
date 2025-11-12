import 'package:carlet/screens/auth/login_screen.dart';
import 'package:carlet/screens/auth/phone_verification_screen.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:carlet/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeAuthService extends AuthService {
  String? lastPhone;

  FakeAuthService() : super.noInit();

  @override
  Future<String> startPhoneVerification(String phoneNumber) async {
    lastPhone = phoneNumber;
    return 'fake-ver-id';
  }

  @override
  Future<AppUser?> confirmSmsCode(String verificationId, String smsCode) async {
    return null;
  }

  @override
  Future<void> signOut() async {}

  @override
  AppUser? get currentUser => null;
}

void main() {
  testWidgets('Login -> Get OTP navigates to PhoneVerification and shows OTP entry',
      (WidgetTester tester) async {
    final fake = FakeAuthService();

    await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: fake,
      child: const MaterialApp(home: LoginScreen()),
    ));
    await tester.pumpAndSettle();

    // Enter phone into the editable field inside IntlPhoneField
    final editable = find.byType(EditableText);
    expect(editable, findsOneWidget);
    await tester.enterText(editable, '0721457788');
    await tester.pumpAndSettle();

    // Tap Get OTP and await navigation
    final getOtp = find.text('Get OTP');
    expect(getOtp, findsOneWidget);
    await tester.tap(getOtp);
    await tester.pumpAndSettle();

    // The PhoneVerificationScreen should auto-send and show the PIN input (Pinput)
    final pinput = find.byType(PhoneVerificationScreen);
    expect(pinput, findsOneWidget);
    // Also ensure the fake auth service received a normalized phone
    expect(fake.lastPhone, isNotNull);
  expect(fake.lastPhone, matches(r'^\+27\d{7,12}$'));
  });
}
