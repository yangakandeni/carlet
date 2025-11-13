import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
// intl_phone_field is no longer used in this screen (LoginScreen supplies the phone).
import 'package:pinput/pinput.dart';
// ignore: depend_on_referenced_packages
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:carlet/utils/ui_constants.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/widgets/invisible_app_bar.dart';
import 'package:carlet/screens/home/home_screen.dart';
import 'package:carlet/screens/auth/onboarding_screen.dart';
import 'package:carlet/utils/phone_utils.dart';

class PhoneVerificationScreen extends StatefulWidget {
  // Optional initial phone number. If provided the screen will prefill and
  // automatically start verification; otherwise the user may enter a number.
  final String? initialPhone;

  const PhoneVerificationScreen({super.key, this.initialPhone});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  @override
  void initState() {
    super.initState();
    // If a test or caller provided an initial phone, prefill the controller
    // and the internal complete number so tests can avoid typing into the
    // IntlPhoneField.
    // If an initial phone was provided, prefill and send the code automatically.
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _phoneController.text = widget.initialPhone!;
      // Try to pre-normalize the provided phone for display and ease of
      // testing. Fall back to the raw value if normalization fails.
      _completePhoneNumber = normalizePhone(widget.initialPhone!) ?? widget.initialPhone!;
      // Automatically send the verification code so the user lands
      // directly on the OTP entry UI.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Only attempt to send if we haven't already sent a code.
        if (!_codeSent) {
          _sendCode();
        }
      });
    }
  }

  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  String? _verificationId;
  String? _error;
  bool _loading = false;
  bool _codeSent = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  String _completePhoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    // In tests, avoid starting a periodic timer (pumpAndSettle can hang).
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      setState(() => _resendCountdown = 0);
      return;
    }

    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // Phone normalization moved to lib/utils/phone_utils.dart

  Future<void> _sendCode() async {
    // Prefer the controller text if user typed/pasted a number; fall back to
    // the intl_phone_field's completeNumber. Normalize inputs like:
    //  - 072145778
    //  - 27721457788
    //  - 721457788
    // into E.164 (+27...) for Firebase.
    final raw = (_phoneController.text.trim().isNotEmpty)
        ? _phoneController.text.trim()
        : _completePhoneNumber;
  final normalized = normalizePhone(raw);
    if (normalized == null) {
      setState(() => _error = 'Please enter a valid phone number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // store normalized number for later display
      _completePhoneNumber = normalized;
      debugPrint('PhoneVerification: sending code to $_completePhoneNumber');
      final id = await context.read<AuthService>().startPhoneVerification(
            _completePhoneNumber,
          );
      debugPrint('PhoneVerification: startPhoneVerification returned id=$id');
      setState(() {
        _verificationId = id;
        _codeSent = true;
      });
      _startResendCountdown();
    } catch (e) {
      // Present a friendly message to the user instead of raw exception text
      String friendly;
      if (e is fb.FirebaseAuthException) {
        friendly = 'Could not send verification code. Please check the phone number and try again.';
      } else {
        friendly = 'Could not send verification code. Please check your internet connection and try again.';
      }
      setState(() => _error = friendly);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode(String code) async {
    if (_verificationId == null || code.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appUser = await context
          .read<AuthService>()
          .confirmSmsCode(_verificationId!, code);
      if (!mounted) return;
      // If onboarding not completed, navigate to onboarding screen first
      if (appUser == null || appUser.onboardingComplete != true) {
        Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
      } else {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } catch (e) {
      // Map FirebaseAuthException codes to user-friendly messages when
      // verification fails (e.g. wrong OTP).
      String friendly;
      if (e is fb.FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
          case 'invalid-verification-id':
          case 'session-expired':
            friendly = 'The code you entered is invalid or expired. Please check the 6-digit code and try again.';
            break;
          case 'too-many-requests':
            friendly = 'Too many attempts. Please wait a moment and try again.';
            break;
          default:
            friendly = 'Unable to verify code. Please try again.';
        }
      } else {
        friendly = 'Unable to verify code. Please check your connection and try again.';
      }
      setState(() => _error = friendly);
      _pinController.clear();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: theme.colorScheme.primary, width: 2),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        border: Border.all(color: theme.colorScheme.primary),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: theme.colorScheme.error, width: 2),
    );

    return Scaffold(
      appBar: InvisibleAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 24),
                if (!_codeSent) ...[
                  Text(
                    'Login or Signup',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll send you an OTP to verify it\'s you',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  IntlPhoneField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                      contentPadding: UIConstants.kInputContentPadding,
                    ),
                    initialCountryCode: 'ZA',
                    disableLengthCheck: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      // Allow either local 10-digit numbers (starting with 0) or
                      // international without plus (e.g. 277...) which is 11 digits
                      LengthLimitingTextInputFormatter(11),
                    ],
                    onChanged: (phone) {
                      // Store complete number for Firebase (without modifying controller)
                      _completePhoneNumber = phone.completeNumber;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _sendCode,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_loading ? 'Sending...' : 'Get OTP', style: theme.textTheme.bodyMedium),
                    style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(UIConstants.kButtonMinHeight)),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  Text(
                    'Enter verification code',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a code to $_completePhoneNumber',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Pinput(
                    controller: _pinController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    errorPinTheme: errorPinTheme,
                    forceErrorState: _error != null,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    onCompleted: _verifyCode,
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    TextButton.icon(
                      onPressed: _resendCountdown > 0 ? null : _sendCode,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _resendCountdown > 0
                            ? 'Resend code in ${_resendCountdown}s'
                            : 'Resend code',
                      ),
                    ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
