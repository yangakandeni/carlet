import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:carlet/utils/snackbar.dart';

import 'package:carlet/screens/feed/feed_screen.dart';
import 'package:carlet/screens/profile/profile_screen.dart';
import 'package:carlet/services/auth_service.dart';
import 'package:carlet/widgets/invisible_app_bar.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: InvisibleAppBar(
        automaticallyImplyLeading: false,
        // Create Report button on the left as a rounded button without icon
        // leading: Padding(
        //   padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
        //   child: IntrinsicWidth(
        //     child: ElevatedButton(
        //       onPressed: () async {
        //         final navigator = Navigator.of(context);
        //         final result = await navigator.pushNamed(
        //           CreateReportScreen.routeName,
        //         );
        //         if (!mounted) return;
        //         if (result == true) {
        //           AppSnackbar.showSuccess(context, 'Report posted.');
        //         }
        //       },
        //       style: ElevatedButton.styleFrom(
        //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //         elevation: 1,
        //         shape: const StadiumBorder(),
        //         minimumSize: const Size(0, 40),
        //       ),
        //       child: Text('Create Report'),
        //     ),
        //   ),
        // ),
        leadingWidth: 80,
        centerTitle: true,
        // Profile avatar on the right (32dp diameter = 16dp radius)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user != null && user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: (user == null || user.photoUrl == null || user.photoUrl!.isEmpty)
                    ? Text(
                        (user?.name != null && user!.name!.trim().isNotEmpty)
                            ? user.name!
                                .trim()
                                .split(' ')
                                .map((s) => s.isNotEmpty ? s[0] : '')
                                .take(2)
                                .join()
                                .toUpperCase()
                            : '?',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: const FeedScreen(),
    );
  }
}
