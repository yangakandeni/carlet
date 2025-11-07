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
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto-resolve on Android; sign-in directly
        await _auth.signInWithCredential(credential);
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

  Future<AppUser?> confirmSmsCode(String verificationId, String smsCode) async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await _auth.signInWithCredential(credential);
    return _ensureUserDoc(cred.user!);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser> _ensureUserDoc(fb.User user) async {
    final ref = _db.collection('users').doc(user.uid);
    await ref.set({
      'name': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      // Ensure onboardingComplete flag exists (defaults to false)
      'onboardingComplete': false,
    }, SetOptions(merge: true));
    final doc = await ref.get();
    final appUser = AppUser.fromMap(doc.id, doc.data());
    _currentUser = appUser;
    notifyListeners();
    return appUser;
  }

  /// Complete the onboarding flow by writing the provided fields to the
  /// user's document and setting `onboardingComplete` to true.
  /// If onboarding is already completed, this will do nothing and return.
  Future<void> completeOnboarding({
    required String name,
    required String carMake,
    required String carModel,
    required String carColor,
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
    await ref.set({
      'name': name,
      'carMake': carMake,
      'carModel': carModel,
      'carColor': carColor,
      'carPlate': carPlate,
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
