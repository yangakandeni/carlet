import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class MessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  Future<String?> ensurePermissionAndToken(String userId) async {
    if (Platform.isIOS) {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
    }
    await _fcm.setAutoInitEnabled(true);
    final token = await _fcm.getToken();
    if (token != null) {
      await _db.collection('users').doc(userId).set(
        {'deviceToken': token},
        SetOptions(merge: true),
      );
    }
    return token;
  }

  void setupForegroundHandler(GlobalKey<ScaffoldMessengerState> messengerKey) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${notif.title ?? 'New alert'}: ${notif.body ?? ''}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }
}
