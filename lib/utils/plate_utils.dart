// Utility helpers for South African license plate validation.

/// Validates if a string matches South African license plate formats.
/// 
/// Valid formats include:
/// 1. Old format (pre-1994): e.g., "TN 12345", "ABC 123 GP"
/// 2. New format (post-1994): e.g., "CA 123-456", "ABC 123 GP"
/// 3. Personalized plates: e.g., "CARLET", "COOL 1"
/// 
/// Returns true if the plate is valid, false otherwise.
bool isValidSouthAfricanPlate(String plate) {
  if (plate.isEmpty) return false;
  
  // Remove spaces and hyphens for validation, convert to uppercase
  final normalized = plate.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
  
  // Format 1: New standard format - 2-3 letters + 2-3 digits + 2 letters (province code)
  // e.g., CA123GP, ABC456GP
  final newFormat = RegExp(r'^[A-Z]{2,3}\d{2,3}[A-Z]{2}$');
  if (newFormat.hasMatch(normalized)) return true;
  
  // Format 2: Old standard format - 1-3 letters + 3-6 digits
  // e.g., TN12345, ABC123456
  final oldFormat = RegExp(r'^[A-Z]{1,3}\d{3,6}$');
  if (oldFormat.hasMatch(normalized)) return true;
  
  // Format 3: Personalized/vanity plates - 3-7 alphanumeric characters
  // Must contain at least one letter (minimum 3 chars for personalized plates)
  final personalizedFormat = RegExp(r'^(?=.*[A-Z])[A-Z0-9]{3,7}$');
  if (personalizedFormat.hasMatch(normalized)) return true;
  
  return false;
}

/// Formats a license plate string for display.
/// Converts to uppercase and standardizes spacing.
String formatPlateForDisplay(String plate) {
  final trimmed = plate.trim().toUpperCase();
  
  // Remove existing spaces and hyphens
  final normalized = trimmed.replaceAll(RegExp(r'[\s\-]'), '');
  
  // Try to detect format and add spacing
  // New format: CA123GP -> CA 123-GP or CA 123 GP
  final newFormatMatch = RegExp(r'^([A-Z]{2,3})(\d{2,3})([A-Z]{2})$').firstMatch(normalized);
  if (newFormatMatch != null) {
    return '${newFormatMatch.group(1)} ${newFormatMatch.group(2)}-${newFormatMatch.group(3)}';
  }
  
  // Old format: TN12345 -> TN 12345
  final oldFormatMatch = RegExp(r'^([A-Z]{1,3})(\d{3,6})$').firstMatch(normalized);
  if (oldFormatMatch != null) {
    return '${oldFormatMatch.group(1)} ${oldFormatMatch.group(2)}';
  }
  
  // For personalized plates or unrecognized formats, just return uppercase
  return normalized;
}

/// Gets a user-friendly error message for invalid plates.
String getPlateValidationError() {
  return 'Please enter a valid South African license plate';
}
