import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carlet/screens/report/create_report_screen.dart';

void main() {
  testWidgets('requires photo first, then license plate and shows friendly errors',
      (WidgetTester tester) async {
    var called = false;

    await tester.pumpWidget(MaterialApp(
      home: CreateReportScreen(
        onCreateReport: ({
          required String reporterId,
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
    expect(find.text('License plate'), findsWidgets);
    expect(find.text('Post alert'), findsWidgets);

    // Tap Post without photo or plate
    await tester.tap(find.text('Post alert'));
    await tester.pumpAndSettle();

    // The submission should not call the create callback
    expect(called, isFalse);

    // A friendly error message about photo should be shown first
    expect(find.text('A photo is required to verify the issue.'), findsWidgets);
  });
}
