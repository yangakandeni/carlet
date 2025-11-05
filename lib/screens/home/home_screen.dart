import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${notif.title ?? 'New alert'}: ${notif.body ?? ''}')),
        );
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
        onPressed: () =>
            Navigator.pushNamed(context, CreateReportScreen.routeName),
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
