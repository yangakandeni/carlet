import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import 'package:carlet/models/user_model.dart';

class AuthService extends ChangeNotifier {
  late final fb.FirebaseAuth _auth;
  late final FirebaseFirestore _db;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  StreamSubscription<fb.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  AuthService() {
    _auth = fb.FirebaseAuth.instance;
    _db = FirebaseFirestore.instance;
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  // Named constructor for tests that avoids subscribing to Firebase auth
  // streams on construction and doesn't initialize Firebase instances.
  AuthService.noInit();

  Future<void> _onAuthChanged(fb.User? user) async {
    _userDocSub?.cancel();
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    final docRef = _db.collection('users').doc(user.uid);
    _userDocSub = docRef.snapshots().listen((doc) {
      _currentUser = AppUser.fromMap(doc.id, doc.data());
      notifyListeners();
    });
  }

  // Email and Google sign-in removed; phone authentication only.

  // Phone auth: start verification; return verificationId
  Future<String> startPhoneVerification(String phoneNumber) async {
    debugPrint('[AUTH] Starting phone verification for: $phoneNumber');

    // Use real Firebase Auth (no simulation) - works on all devices
    // Physical iOS devices will receive real SMS
    // iOS simulator may have issues, but physical devices work fine

    final completer = Completer<String>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          debugPrint('[AUTH] Auto-verification completed');
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            debugPrint('[AUTH] Auto sign-in failed: $e');
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          debugPrint('[AUTH] Verification failed: ${e.code} - ${e.message}');
          completer.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('[AUTH] Code sent, verificationId: $verificationId');
          completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint(
              '[AUTH] Auto-retrieval timeout, verificationId: $verificationId');
          if (!completer.isCompleted) completer.complete(verificationId);
        },
      );
    } catch (e) {
      debugPrint('[AUTH] Phone verification setup failed: $e');
      completer.completeError(e);
    }

    return completer.future;
  }

  Future<AppUser?> confirmSmsCode(String verificationId, String smsCode) async {
    debugPrint(
        '[AUTH] Confirming SMS code: $smsCode with verificationId: $verificationId');

    // Use real Firebase Auth credential verification
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final cred = await _auth.signInWithCredential(credential);
    debugPrint(
        '[AUTH] SMS verification successful for user: ${cred.user?.uid}');
    // Ensure the newly-signed-in user's ID token is minted and available to
    // other Firebase services (Firestore) before we attempt to write the
    // user's document. This avoids a race where the Firestore request
    // arrives without auth context and triggers rules evaluation errors.
    // Wait up to 3 seconds for the token to be available.
    for (var i = 0; i < 6; i++) {
      try {
        final token = await cred.user?.getIdToken(false);
        if (token != null && token.isNotEmpty) break;
      } catch (_) {
        // Token not ready yet
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return _ensureUserDoc(cred.user!);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update user profile fields that are allowed to change after onboarding.
  /// Vehicle fields (carMake/carModel/carPlate) must not be
  /// updated through this method to respect immutability rules.
  Future<AppUser> updateProfile(
      {String? name, String? email, String? photoUrl}) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Not signed in');
    final ref = _db.collection('users').doc(fbUser.uid);
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isEmpty) return currentUser!;
    await ref.set(data, SetOptions(merge: true));
    final doc = await ref.get();
    final appUser = AppUser.fromMap(doc.id, doc.data());
    _currentUser = appUser;
    notifyListeners();
    return appUser;
  }

  /// Start phone number update verification.
  /// Returns verificationId to be used with confirmPhoneUpdate.
  Future<String> updatePhoneNumber(String newPhoneNumber) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Not signed in');

    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: newPhoneNumber,
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto-resolve on Android
        await fbUser.updatePhoneNumber(credential);
        // Update Firestore document
        await _db.collection('users').doc(fbUser.uid).set({
          'phoneNumber': newPhoneNumber,
        }, SetOptions(merge: true));
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );
    return completer.future;
  }

  /// Confirm phone number update with SMS code.
  /// Updates both Firebase Auth and Firestore user document.
  Future<void> confirmPhoneUpdate(
      String verificationId, String smsCode, String newPhoneNumber) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Not signed in');

    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    // Update phone number in Firebase Auth
    await fbUser.updatePhoneNumber(credential);

    // Update Firestore user document
    await _db.collection('users').doc(fbUser.uid).set({
      'phoneNumber': newPhoneNumber,
    }, SetOptions(merge: true));

    // Refresh current user data
    final doc = await _db.collection('users').doc(fbUser.uid).get();
    _currentUser = AppUser.fromMap(doc.id, doc.data());
    notifyListeners();
  }

  Future<AppUser> _ensureUserDoc(fb.User user) async {
    final ref = _db.collection('users').doc(user.uid);

    // First check if the user document already exists
    final existingDoc = await ref.get();

    // For returning users, don't overwrite existing data
    // Just ensure the document exists and return it
    if (existingDoc.exists &&
        existingDoc.data()?['onboardingComplete'] == true) {
      // Returning user with completed onboarding - don't overwrite their data
      // Just update phone number if it changed
      if (user.phoneNumber != null) {
        await ref.set({
          'phoneNumber': user.phoneNumber,
        }, SetOptions(merge: true));
      }
      final doc = await ref.get();
      final appUser = AppUser.fromMap(doc.id, doc.data());
      _currentUser = appUser;
      notifyListeners();
      return appUser;
    }

    // For new users or users who haven't completed onboarding,
    // initialize/update their document with Firebase Auth data
    final data = <String, dynamic>{};

    // Only set fields if they have values (not null)
    if (user.displayName != null) data['name'] = user.displayName;
    if (user.email != null) data['email'] = user.email;
    if (user.phoneNumber != null) data['phoneNumber'] = user.phoneNumber;
    if (user.photoURL != null) data['photoUrl'] = user.photoURL;

    // Only set onboardingComplete to false if it doesn't exist
    // This prevents overwriting the flag for returning users
    if (!existingDoc.exists ||
        existingDoc.data()?['onboardingComplete'] == null) {
      data['onboardingComplete'] = false;
    }

    await ref.set(data, SetOptions(merge: true));
    final doc = await ref.get();
    final appUser = AppUser.fromMap(doc.id, doc.data());
    _currentUser = appUser;
    notifyListeners();
    return appUser;
  }

  /// Complete the onboarding flow by writing the provided fields to the
  /// user's document and setting `onboardingComplete` to true.
  /// If onboarding is already completed, this will do nothing and return.
  /// Throws an exception if the license plate is already registered to another user.
  Future<void> completeOnboarding({
    required String name,
    required String carMake,
    required String carModel,
    required String carPlate,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Not signed in');
    final ref = _db.collection('users').doc(fbUser.uid);
    final snapshot = await ref.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final already = data['onboardingComplete'] == true;
    if (already) {
      // No-op if onboarding already completed
      return;
    }

    // Normalize license plate to uppercase without spaces to match
    // how reports store licensePlate (normalized in ReportService).
    final normalizedPlate = carPlate.toUpperCase().replaceAll(' ', '');

    // Check if this license plate is already registered to another user
    final existingPlateQuery = await _db
        .collection('users')
        .where('carPlate', isEqualTo: normalizedPlate)
        .limit(1)
        .get();

    if (existingPlateQuery.docs.isNotEmpty) {
      final existingUserId = existingPlateQuery.docs.first.id;
      // Only throw if the plate belongs to a different user
      if (existingUserId != fbUser.uid) {
        throw Exception(
            'This license plate is already registered. Please verify your plate number.');
      }
    }

    await ref.set({
      'name': name,
      'carMake': carMake,
      'carModel': carModel,
      'carPlate': normalizedPlate,
      'onboardingComplete': true,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}

// No Google Sign-In; phone authentication only.
