import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionResult {
  final bool granted;
  final String? message;

  LocationPermissionResult({required this.granted, this.message});
}

class LocationService {
  Future<LocationPermissionResult> ensurePermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionResult(
        granted: false,
        message:
            'Location services are disabled. Please enable them in settings.',
      );
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionResult(
          granted: false,
          message:
              'Location permission denied. Please grant permission to continue.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult(
        granted: false,
        message:
            'Location permission permanently denied. Please enable it in app settings.',
      );
    }

    return LocationPermissionResult(granted: true);
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final permissionResult = await ensurePermission();
      if (!permissionResult.granted) {
        // Return null if permission not granted
        // The calling code can check for null and show the message
        return null;
      }

      // Use timeout to prevent hanging
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy
                .medium, // Changed from high to medium for better emulator support
            timeLimit: Duration(seconds: 10), // Add timeout
          ),
        ).timeout(const Duration(seconds: 15));
        return position;
      } on TimeoutException {
        // If timeout, try to get last known position
        return await Geolocator.getLastKnownPosition();
      }
    } catch (e) {
      // If any error occurs, try to get last known position
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  Future<LocationPermissionResult> checkPermission() async {
    return await ensurePermission();
  }

  Future<void> updateUserLocation(String userId) async {
    final pos = await getCurrentPosition();
    if (pos == null) return;
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {
        'lastLat': pos.latitude,
        'lastLng': pos.longitude,
      },
      SetOptions(merge: true),
    );
  }
}
