import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar_helper.dart';

/// Small helper to show consistent, aesthetic snackbars (flushbars).
/// Wraps `another_flushbar` convenience methods.
class AppSnackbar {
  static void showSuccess(BuildContext context, String message,
      {String? title}) {
    final f = FlushbarHelper.createSuccess(
      title: title ?? 'Success',
      message: message,
      duration: const Duration(seconds: 3),
    );
    // show() returns a Future but we intentionally do not await it here to
    // avoid holding up UI logic. The flushbar will still display.
    f.show(context);
  }

  static void showError(BuildContext context, String message,
      {String? title}) {
    final f = FlushbarHelper.createError(
      title: title ?? 'Error',
      message: message,
      duration: const Duration(seconds: 4),
    );
    f.show(context);
  }

  static void showInfo(BuildContext context, String message,
      {String? title}) {
    final f = FlushbarHelper.createInformation(
      title: title ?? 'Info',
      message: message,
      duration: const Duration(seconds: 3),
    );
    f.show(context);
  }
}
