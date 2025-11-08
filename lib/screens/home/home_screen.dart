import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:carlet/utils/snackbar.dart';

import 'package:carlet/screens/feed/feed_screen.dart';
import 'package:carlet/screens/map/map_screen.dart';
import 'package:carlet/screens/report/create_report_screen.dart';
import 'package:carlet/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

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
    final tabs = [
      const FeedScreen(),
      const MapScreen(),
    ];
    final titles = ['Alerts', 'Map'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: tabs[_tab],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Capture the navigator synchronously so we don't reference
          // `context` across an `await` which trips analyzer lint.
          final navigator = Navigator.of(context);
          final result = await navigator.pushNamed(
            CreateReportScreen.routeName,
          );
          // Ensure widget still mounted before using context after an await.
          if (!mounted) return;
          // If the create screen signalled success, show feedback now
          if (result == true) {
            // Safe here because we validated `mounted` above; suppress
            // the lint about using BuildContext across async gaps.
            // ignore: use_build_context_synchronously
            AppSnackbar.showSuccess(context, 'Report posted.');
          }
        },
        icon: const Icon(Icons.report),
        label: const Text('Report car'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
        ],
        onDestinationSelected: (i) => setState(() => _tab = i),
      ),
    );
  }
}
