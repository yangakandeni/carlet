# Location and Maps Removal Refactor

## Overview
This document describes the comprehensive refactoring to remove all location and maps-related functionality from the Carlet app. The decision was made after removing location/distance display from report cards, making the GPS and mapping features unnecessary.

## Rationale
- Location features were no longer being used in the UI
- Report cards now only show: image, license plate, status, and message
- Users should know where they parked, eliminating the need for GPS tracking
- Removing location simplifies the app and eliminates the need for location permissions
- Reduces app size and dependency count

## Changes Made

### 1. **Deleted Files**
- ❌ `lib/services/location_service.dart` - GPS and location permission service
- ❌ `lib/screens/map/map_screen.dart` - Google Maps screen for viewing reports
- ❌ `lib/screens/map/` - Empty directory removed

### 2. **Model Updates**

#### Report Model (`lib/models/report_model.dart`)
**Removed fields:**
- `double lat` - Latitude coordinate
- `double lng` - Longitude coordinate

**Updated methods:**
- `fromMap()` - Removed location parsing logic
- `toMap()` - Removed location serialization

**Before:**
```dart
final double lat;
final double lng;

factory Report.fromMap(String id, Map<String, dynamic> map) {
  final loc = map['location'] as Map<String, dynamic>?;
  return Report(
    lat: (loc?['lat'] as num).toDouble(),
    lng: (loc?['lng'] as num).toDouble(),
    // ...
  );
}

Map<String, dynamic> toMap() => {
  'location': {'lat': lat, 'lng': lng},
  // ...
};
```

**After:**
```dart
// lat and lng fields removed entirely
factory Report.fromMap(String id, Map<String, dynamic> map) {
  return Report(
    // no location parsing
  );
}

Map<String, dynamic> toMap() => {
  // no location field
};
```

#### User Model (`lib/models/user_model.dart`)
**Removed fields:**
- `double? lastLat` - User's last known latitude
- `double? lastLng` - User's last known longitude

**Updated methods:**
- `fromMap()` - Removed lastLat/lastLng parsing
- `toMap()` - Removed lastLat/lastLng serialization

### 3. **Service Layer Updates**

#### ReportService (`lib/services/report_service.dart`)
**Removed parameters from `createReport()`:**
- `required double lat`
- `required double lng`

**Before:**
```dart
Future<String> createReport({
  required String reporterId,
  required double lat,
  required double lng,
  // ...
}) async {
  final data = Report(
    lat: lat,
    lng: lng,
    // ...
  ).toMap();
}
```

**After:**
```dart
Future<String> createReport({
  required String reporterId,
  // lat/lng removed
  // ...
}) async {
  final data = Report(
    // no location
  ).toMap();
}
```

### 4. **Screen Updates**

#### CreateReportScreen (`lib/screens/report/create_report_screen.dart`)
**Removed:**
- `LocationService` import and usage
- Location permission checking
- GPS position fetching
- lat/lng parameters from onCreateReport callback

**Before:**
```dart
import 'package:carlet/services/location_service.dart';

final locationService = context.read<LocationService>();
final permissionResult = await locationService.checkPermission();
final loc = await locationService.getCurrentPosition();

await ReportService().createReport(
  reporterId: auth.currentUser!.id,
  lat: loc.latitude,
  lng: loc.longitude,
  // ...
);
```

**After:**
```dart
// No location imports or logic
await ReportService().createReport(
  reporterId: auth.currentUser!.id,
  // No lat/lng
  // ...
);
```

#### SplashScreen (`lib/screens/splash_screen.dart`)
**Removed:**
- `LocationService` import
- `updateUserLocation()` call during bootstrap

### 5. **Main App (`lib/main.dart`)**
**Removed:**
- `LocationService` import
- `LocationService` from MultiProvider

**Before:**
```dart
import 'package:carlet/services/location_service.dart';

MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    Provider(create: (_) => MessagingService()),
    Provider(create: (_) => LocationService()),
  ],
  // ...
)
```

**After:**
```dart
// No LocationService import

MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    Provider(create: (_) => MessagingService()),
    // LocationService removed
  ],
  // ...
)
```

### 6. **Dependencies (`pubspec.yaml`)**
**Removed packages:**
```yaml
# Removed from dependencies:
google_maps_flutter: ^2.7.0
geolocator: ^14.0.2
```

### 7. **Test Files Updated**

#### `test/profile_signout_test.dart`
- Removed `lastLat` and `lastLng` from AppUser construction in mock

#### `test/onboarding_widget_test.dart`
- Removed `lastLat` and `lastLng` from AppUser construction in mock
- Added `phoneNumber` field

#### `test/create_report_screen_test.dart`
- Removed `lat` and `lng` parameters from onCreateReport callback
- Updated error message assertion

#### `test/create_report_flow_test.dart`
- Removed `geolocator` import
- Removed `MockLocationService` class entirely
- Removed `LocationService` from test providers
- Removed `lat` and `lng` from onCreateReport callback
- Updated field finder from "License plate (optional)" to "License plate"

### 8. **Script Updates**

#### `tools/scripts/insert_report.sh`
**Removed:**
- `LAT` and `LNG` variables
- `--lat` and `--lng` CLI arguments (now ignored for backward compatibility)
- Location map from Firestore payload

**Before:**
```bash
LAT="37.4219983"
LNG="-122.084"

"location": {
  "mapValue": {
    "fields": {
      "lat": {"doubleValue": ${LAT}},
      "lng": {"doubleValue": ${LNG}}
    }
  }
},
```

**After:**
```bash
# LAT/LNG removed
# --lat and --lng flags ignored if provided (backward compatibility)

# No location field in payload
```

## Migration Notes

### Firestore Data
**Existing reports in Firestore may still have location data.** This is fine because:
- The app no longer reads or displays location fields
- Old reports will continue to work (location fields are simply ignored)
- New reports will be created without location data
- No data migration is required

### Backward Compatibility
- The insert_report.sh script still accepts `--lat` and `--lng` flags but ignores them
- This prevents breaking existing scripts or workflows

## Testing
All tests pass after refactoring:
```bash
flutter test
# 00:23 +19: All tests passed!
```

Static analysis is clean (only 4 pre-existing info-level lints):
```bash
flutter analyze
# 4 issues found (all info-level, unrelated to refactor)
```

## Benefits

### Performance
- ✅ Smaller app size (removed google_maps_flutter and geolocator packages)
- ✅ No GPS permission requests or checks
- ✅ No location tracking overhead
- ✅ Faster report creation (no waiting for GPS lock)

### User Experience
- ✅ Simplified report creation flow
- ✅ No location permission prompts
- ✅ Works in areas with poor GPS signal
- ✅ Cleaner, focused UI

### Maintenance
- ✅ Less code to maintain
- ✅ Fewer dependencies to update
- ✅ Simpler data model
- ✅ No map-related bugs or issues

## Files Modified Summary
**Total: 14 files modified + 3 files deleted**

**Deleted:**
1. lib/services/location_service.dart
2. lib/screens/map/map_screen.dart
3. lib/screens/map/ (directory)

**Modified:**
1. lib/models/report_model.dart
2. lib/models/user_model.dart
3. lib/services/report_service.dart
4. lib/screens/report/create_report_screen.dart
5. lib/screens/splash_screen.dart
6. lib/main.dart
7. pubspec.yaml
8. tools/scripts/insert_report.sh
9. test/profile_signout_test.dart
10. test/onboarding_widget_test.dart
11. test/create_report_screen_test.dart
12. test/create_report_flow_test.dart

**Created:**
1. docs/LOCATION_REMOVAL_REFACTOR.md (this document)

## Future Considerations

### If Location Becomes Needed Again
If location features need to be re-added in the future:
1. Add back dependencies in pubspec.yaml
2. Restore location fields in models (with optional/nullable types)
3. Add location service for permission and GPS
4. Update report creation to capture location
5. Update UI to display location/maps as needed

### Alternative Approaches
If partial location features are needed:
- Could store location server-side without exposing in app
- Could use IP-based geolocation instead of GPS
- Could let users manually enter location/parking spot

## Conclusion
The location and maps refactor successfully removes all GPS and mapping functionality while maintaining full app functionality. The app is now simpler, smaller, and more focused on the core feature: notifying car owners about their vehicles.
