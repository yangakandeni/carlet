import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

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

  void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        // Show toast notification for foreground messages
        // Using toastification without context since we have ToastificationWrapper
        toastification.show(
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          title: Text(notif.title ?? 'New alert'),
          description: Text(notif.body ?? ''),
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 3),
          showProgressBar: true,
          closeButtonShowType: CloseButtonShowType.onHover,
          closeOnClick: true,
          pauseOnHover: true,
          dragToClose: true,
        );
      }
    });
  }
}
