import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
// ignore: depend_on_referenced_packages
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/utils/phone_utils.dart';
import 'package:carlet/utils/ui_constants.dart';

/// A dialog that allows users to update their phone number with OTP verification.
class PhoneUpdateDialog extends StatefulWidget {
  final AuthService authService;
  final String? currentPhone;

  const PhoneUpdateDialog({
    super.key,
    required this.authService,
    this.currentPhone,
  });

  @override
  State<PhoneUpdateDialog> createState() => _PhoneUpdateDialogState();
}

class _PhoneUpdateDialogState extends State<PhoneUpdateDialog> {
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

  Future<void> _sendCode() async {
    final raw = (_phoneController.text.trim().isNotEmpty)
        ? _phoneController.text.trim()
        : _completePhoneNumber;
    final normalized = normalizePhone(raw);
    if (normalized == null) {
      setState(() => _error = 'Please enter a valid phone number');
      return;
    }

    // Check if it's the same as current phone
    if (normalized == widget.currentPhone) {
      setState(() => _error = 'This is already your current phone number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _completePhoneNumber = normalized;
      final id = await widget.authService.updatePhoneNumber(_completePhoneNumber);
      setState(() {
        _verificationId = id;
        _codeSent = true;
      });
      _startResendCountdown();
    } catch (e) {
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
      await widget.authService.confirmPhoneUpdate(
        _verificationId!,
        code,
        _completePhoneNumber,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true); // Return success
    } catch (e) {
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

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _codeSent ? 'Verify new phone' : 'Update phone number',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_codeSent) ...[
              if (widget.currentPhone != null) ...[
                Text(
                  'Current: ${widget.currentPhone}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Enter your new phone number. We\'ll send you a verification code.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              IntlPhoneField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'New Phone Number',
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
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (phone) {
                  _completePhoneNumber = phone.completeNumber;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _sendCode,
                style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(UIConstants.kButtonMinHeight)),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send verification code'),
              ),
            ] else ...[
              Text(
                'We sent a code to $_completePhoneNumber',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _codeSent = false;
                          _verificationId = null;
                          _pinController.clear();
                          _error = null;
                          _countdownTimer?.cancel();
                          _resendCountdown = 0;
                        });
                      },
                      child: const Text('Change number'),
                    ),
                    TextButton.icon(
                      onPressed: _resendCountdown > 0 ? null : _sendCode,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        _resendCountdown > 0
                            ? 'Resend (${_resendCountdown}s)'
                            : 'Resend',
                      ),
                    ),
                  ],
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
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 13,
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
    );
  }
}
