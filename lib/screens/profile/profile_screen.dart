import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/models/user_model.dart';
import 'package:carlet/utils/snackbar.dart';
import 'package:carlet/screens/auth/login_screen.dart';
import 'package:carlet/widgets/phone_update_dialog.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      if (user.name != null) _nameCtrl.text = user.name!;
      if (user.email != null) _emailCtrl.text = user.email!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Profile updated');
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to update profile.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updatePhone() async {
    final auth = context.read<AuthService>();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PhoneUpdateDialog(
        authService: auth,
        currentPhone: auth.currentUser?.phoneNumber,
      ),
    );
    if (result == true && mounted) {
      AppSnackbar.showSuccess(context, 'Phone number updated successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final AppUser? user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user == null) const Text('Not signed in'),
            if (user != null) ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              // Phone number section with update button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone number',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.phoneNumber ?? '(not set)',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _updatePhone,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Update'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Vehicle (read-only)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Make: ${user.carMake ?? "-"}'),
              Text('Model: ${user.carModel ?? "-"}'),
              Text('Color: ${user.carColor ?? "-"}'),
              Text('Plate: ${user.carPlate ?? "-"}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading ? const CircularProgressIndicator() : const Text('Save'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final auth = context.read<AuthService>();
                  final doLogout = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sign out')),
                      ],
                    ),
                  );
                  if (doLogout != true) return;
                  try {
                    await auth.signOut();
                    if (!mounted) return;
                    // Navigate back to the login screen and clear history
                    navigator.pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
                  } catch (e) {
                    // Use navigator.context (captured) instead of original context.
                    // Guard with mounted to avoid using BuildContext across async gaps.
                    if (!mounted) return;
                    AppSnackbar.showError(navigator.context, 'Failed to sign out. Please try again.');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
