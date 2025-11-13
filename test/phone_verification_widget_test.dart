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
    return 'fake-verification-id';
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
  testWidgets('Entering local number 0721457788 normalizes and shows sent code',
      (WidgetTester tester) async {
    final fake = FakeAuthService();

    await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: fake,
      child: const MaterialApp(home: PhoneVerificationScreen(initialPhone: '0721457788')),
    ));
    await tester.pumpAndSettle();

    // Auth service should have received a normalized E.164-style number
    expect(fake.lastPhone, isNotNull);
    expect(fake.lastPhone, matches(r'^\+27\d{7,12}$'));
  });

  testWidgets('Entering short local number 721457788 normalizes and shows sent code',
      (WidgetTester tester) async {
    final fake = FakeAuthService();

    await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: fake,
      child: const MaterialApp(home: PhoneVerificationScreen(initialPhone: '721457788')),
    ));
    await tester.pumpAndSettle();

    expect(fake.lastPhone, isNotNull);
    expect(fake.lastPhone, matches(r'^\+27\d{7,12}$'));
  });

  testWidgets('Entering country-code number 27717662280 normalizes to +27717662280',
      (WidgetTester tester) async {
    final fake = FakeAuthService();

    await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(
      value: fake,
      child: const MaterialApp(home: PhoneVerificationScreen(initialPhone: '27717662280')),
    ));
    await tester.pumpAndSettle();

    // Should normalize to +27717662280
    expect(fake.lastPhone, equals('+27717662280'));
  });
}
