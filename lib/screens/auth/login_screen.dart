import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:carlet/screens/auth/phone_verification_screen.dart';
import 'package:carlet/widgets/carlet_button.dart';
import 'package:carlet/utils/phone_utils.dart';
import 'package:carlet/utils/ui_constants.dart';

/// Phase 1 (Phone Number Input) of the Login flow, styled with Carlet design system.
/// On submit, navigates to PhoneVerificationScreen for OTP (Phase 2).
class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  String _completePhoneNumber = '';
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() async {
    FocusScope.of(context).unfocus();
    final raw = (_controller.text.trim().isNotEmpty)
        ? _controller.text.trim()
        : _completePhoneNumber;
    final normalized = normalizePhone(raw);
    if (normalized == null) {
      setState(() => _error = 'Please enter a valid phone number');
      return;
    }

    // Validate that it's a South African phone number
    if (!isValidSouthAfricanPhone(raw)) {
      setState(() => _error = getPhoneValidationError());
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    // We intentionally do not send the code here to keep logic centralized
    // in PhoneVerificationScreen. We pass the normalized phone to prefill.
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneVerificationScreen(initialPhone: normalized),
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface60 = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final inputDecoration = InputDecoration(
      labelText: 'Phone Number',
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: UIConstants.kInputContentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
    );

    return Scaffold(
      // No app bar; system back still works.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Login or Signup',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We\'ll send you an OTP to verify it\'s you.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: onSurface60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  IntlPhoneField(
                    controller: _controller,
                    decoration: inputDecoration,
                    initialCountryCode: 'ZA',
                    disableLengthCheck: true,
                    showDropdownIcon: true,
                    // Keep flag+code inside field; don't add extra prefix icon.
                    onChanged: (phone) => _completePhoneNumber = phone.completeNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Show error (if any) above the CTA so the user sees validation
                  // feedback before interacting with the action button.
                  if (_error != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // CTA (rounded, blue background with white text)
                  Theme(
                    data: Theme.of(context).copyWith(
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all<OutlinedBorder>(
                            const StadiumBorder(),
                          ),
                          backgroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
                          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
                        ),
                      ),
                    ),
                    child: CarletButton.primary(
                      text: _loading ? 'Sending...' : 'Get OTP',
                      icon: _loading
                          ? const SizedBox(
                              width: 0,
                              height: 0,
                            )
                          : const Icon(Icons.send),
                      onPressed: _loading ? () {} : _continue,
                      showLoading: _loading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
