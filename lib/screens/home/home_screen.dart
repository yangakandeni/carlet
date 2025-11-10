import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:carlet/utils/snackbar.dart';

import 'package:carlet/screens/feed/feed_screen.dart';
import 'package:carlet/screens/report/create_report_screen.dart';
import 'package:carlet/screens/profile/profile_screen.dart';
import 'package:carlet/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif != null && mounted) {
        AppSnackbar.showInfo(
            context, '${notif.title ?? 'New alert'}: ${notif.body ?? ''}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        // Report button on the far left
        leading: IconButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final result = await navigator.pushNamed(
              CreateReportScreen.routeName,
            );
            if (!mounted) return;
            if (result == true) {
              // ignore: use_build_context_synchronously
              AppSnackbar.showSuccess(context, 'Report posted.');
            }
          },
          icon: const Icon(Icons.add_box_rounded),
          tooltip: 'Report issue',
        ),
        title: const Text('Alerts'),
        // Profile button on the far right
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, ProfileScreen.routeName),
            icon: user != null
                ? (user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? CircleAvatar(radius: 16, backgroundImage: NetworkImage(user.photoUrl!))
                    : CircleAvatar(
                        radius: 16,
                        child: Text(
                          (user.name != null && user.name!.trim().isNotEmpty)
                              ? user.name!.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
                              : '?',
                        ),
                      ))
                : const Icon(Icons.person_outline),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: const FeedScreen(),
    );
  }
}
