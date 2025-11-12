// Small helpers & common component styles to be imported by widgets.
// Keep lightweight to avoid breaking existing code.
import 'package:flutter/material.dart';

class AppComponents {
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12));
  static const double buttonHeight = 48;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  // Example helper: badge colors
  static Color openBadgeBackground(BuildContext context) => Theme.of(context).colorScheme.error.withValues(alpha: 0.12);
  static Color openBadgeText(BuildContext context) => Theme.of(context).colorScheme.error;
}
