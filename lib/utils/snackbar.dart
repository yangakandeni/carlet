import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Helper to show consistent toast notifications using toastification.
class AppToast {
  static void showSuccess(BuildContext context, String message,
      {String? title}) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(title ?? 'Success'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  static void showError(BuildContext context, String message,
      {String? title}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: Text(title ?? 'Error'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  static void showInfo(BuildContext context, String message,
      {String? title}) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: Text(title ?? 'Info'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }
}

// Backwards compatibility alias
class AppSnackbar {
  static void showSuccess(BuildContext context, String message,
      {String? title}) {
    AppToast.showSuccess(context, message, title: title);
  }

  static void showError(BuildContext context, String message,
      {String? title}) {
    AppToast.showError(context, message, title: title);
  }

  static void showInfo(BuildContext context, String message,
      {String? title}) {
    AppToast.showInfo(context, message, title: title);
  }
}
