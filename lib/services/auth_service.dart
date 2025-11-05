import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import 'package:carlet/models/user_model.dart';

class AuthService extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  StreamSubscription<fb.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  AuthService() {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

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
    }, SetOptions(merge: true));
    final doc = await ref.get();
    final appUser = AppUser.fromMap(doc.id, doc.data());
    _currentUser = appUser;
    notifyListeners();
    return appUser;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}

// No Google Sign-In; phone authentication only.
