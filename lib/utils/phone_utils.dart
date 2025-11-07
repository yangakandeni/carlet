// Utility helpers for phone number normalization.

String? normalizePhone(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  // Remove common separators
  var s = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');

  // If starts with +, keep digits after plus
  if (s.startsWith('+')) {
    final rest = s.substring(1).replaceAll(RegExp(r'\D'), '');
    if (rest.length < 7) return null;
    return '+$rest';
  }

  // If starts with 00, convert to +
  if (s.startsWith('00')) {
    final rest = s.substring(2).replaceAll(RegExp(r'\D'), '');
    if (rest.isEmpty) return null;
    return '+$rest';
  }

  // Keep only digits for further processing
  final digits = s.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;

  // If user provided country code without plus (e.g., 277...), add +
  if (digits.startsWith('27')) {
    return '+$digits';
  }

  // If starts with 0 (local format), replace leading 0 with +27
  if (digits.startsWith('0')) {
    return '+27${digits.substring(1)}';
  }

  // If 9 digits (common when user omits leading 0), assume missing leading 0
  if (digits.length == 9) {
    return '+27$digits';
  }

  // Fallback: if plausible local length, prefix +27
  if (digits.length >= 7 && digits.length <= 12) {
    return '+27$digits';
  }

  return null;
}
