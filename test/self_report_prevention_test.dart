import 'dart:io';

import 'package:carlet/models/user_model.dart' as model;
import 'package:carlet/screens/report/create_report_screen.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Self-Report Prevention', () {
    testWidgets('User cannot report their own car - exact match',
        (WidgetTester tester) async {
      final authService = MockAuthService();
      String? createdLicensePlate;
      bool createReportCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: CreateReportScreen(
              onCreateReport: ({
                required String reporterId,
                String? licensePlate,
                String? message,
                File? photoFile,
                bool anonymous = false,
              }) async {
                createReportCalled = true;
                createdLicensePlate = licensePlate;
                return 'test-report-id';
              },
            ),
          ),
        ),
      );

      // Enter user's own license plate
      await tester.enterText(
          find.widgetWithText(TextField, 'License plate'), 'ABC123');
      await tester.pumpAndSettle();

      // Try to submit
      await tester.tap(find.text('Post alert'));
      await tester.pumpAndSettle();

      // Report should not be created
      expect(createReportCalled, isFalse);
      expect(createdLicensePlate, isNull);

      // Error message should be shown
      expect(find.text('You cannot report your own vehicle.'), findsOneWidget);
    });

    testWidgets(
        'User cannot report their own car - case insensitive and space handling',
        (WidgetTester tester) async {
      final authService = MockAuthService();
      String? createdLicensePlate;
      bool createReportCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: CreateReportScreen(
              onCreateReport: ({
                required String reporterId,
                String? licensePlate,
                String? message,
                File? photoFile,
                bool anonymous = false,
              }) async {
                createReportCalled = true;
                createdLicensePlate = licensePlate;
                return 'test-report-id';
              },
            ),
          ),
        ),
      );

      // Enter user's own license plate (with different casing & space)
      await tester.enterText(
          find.widgetWithText(TextField, 'License plate'), 'abc 123');
      await tester.pumpAndSettle();

      // Try to submit
      await tester.tap(find.text('Post alert'));
      await tester.pumpAndSettle();

      // Report should not be created
      expect(createReportCalled, isFalse);
      expect(createdLicensePlate, isNull);

      // Error message should be shown
      expect(find.text('You cannot report your own vehicle.'), findsOneWidget);
    });

    testWidgets('User can report a different car', (WidgetTester tester) async {
      final authService = MockAuthService();
      String? createdLicensePlate;
      bool createReportCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: CreateReportScreen(
              onCreateReport: ({
                required String reporterId,
                String? licensePlate,
                String? message,
                File? photoFile,
                bool anonymous = false,
              }) async {
                createReportCalled = true;
                createdLicensePlate = licensePlate;
                return 'test-report-id';
              },
            ),
          ),
        ),
      );

      // Enter different license plate
      await tester.enterText(
          find.widgetWithText(TextField, 'License plate'), 'XYZ789');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Post alert'));
      await tester.pumpAndSettle();

      // Report should be created
      expect(createReportCalled, isTrue);
      expect(createdLicensePlate, 'XYZ789');

      // No error message
      expect(
          find.text('You cannot report your own vehicle.'), findsNothing);
    });

    testWidgets('User without car plate can report any car',
        (WidgetTester tester) async {
      final authService = MockAuthService(hasCarPlate: false);
      String? createdLicensePlate;
      bool createReportCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthService>.value(
            value: authService,
            child: CreateReportScreen(
              onCreateReport: ({
                required String reporterId,
                String? licensePlate,
                String? message,
                File? photoFile,
                bool anonymous = false,
              }) async {
                createReportCalled = true;
                createdLicensePlate = licensePlate;
                return 'test-report-id';
              },
            ),
          ),
        ),
      );

      // Enter any license plate
      await tester.enterText(
          find.widgetWithText(TextField, 'License plate'), 'ABC123');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Post alert'));
      await tester.pumpAndSettle();

      // Report should be created (user has no car plate to compare)
      expect(createReportCalled, isTrue);
      expect(createdLicensePlate, 'ABC123');
    });
  });
}

class MockAuthService extends AuthService {
  final bool hasCarPlate;
  
  MockAuthService({this.hasCarPlate = true}) : super.noInit();

  @override
  model.AppUser? get currentUser => model.AppUser(
        id: 'user-123',
        name: 'Test User',
        email: 'test@example.com',
        photoUrl: null,
        onboardingComplete: true,
        carMake: 'Toyota',
        carModel: 'Camry',
        carPlate: hasCarPlate ? 'ABC123' : null,
        phoneNumber: '+1234567890',
      );
}
