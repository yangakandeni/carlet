import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carlet/screens/report/create_report_screen.dart';

void main() {
  testWidgets('requires license plate and shows friendly error',
      (WidgetTester tester) async {
    var called = false;

    await tester.pumpWidget(MaterialApp(
      home: CreateReportScreen(
        onCreateReport: ({
          required String reporterId,
          required double lat,
          required double lng,
          String? licensePlate,
          String? message,
          File? photoFile,
          bool anonymous = false,
        }) async {
          called = true;
          return 'ok';
        },
      ),
    ));

    // Ensure initial UI exists
    expect(find.text('License plate'), findsOneWidget);
    expect(find.text('Post alert'), findsOneWidget);

    // Tap Post without entering a plate
    await tester.tap(find.text('Post alert'));
    await tester.pumpAndSettle();

    // The submission should not call the create callback
    expect(called, isFalse);

    // A friendly error message should be shown in the UI
    expect(find.text('Please enter the vehicle license plate to post an alert.'), findsOneWidget);
  });
}
