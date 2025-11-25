import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/utils/snackbar.dart';
import 'package:carlet/utils/plate_utils.dart';
import 'package:carlet/screens/home/home_screen.dart';
import 'package:carlet/widgets/carlet_button.dart';
import 'package:carlet/widgets/invisible_app_bar.dart';
import 'package:carlet/utils/ui_constants.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    // If onboarding already completed, redirect to home immediately
    if (user?.onboardingComplete == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        }
      });
    } else {
      // Pre-fill name if available
      if (user?.name != null) _nameCtrl.text = user!.name!;
    }
    // Add listeners for real-time validation
    _nameCtrl.addListener(_validateForm);
    _makeCtrl.addListener(_validateForm);
    _modelCtrl.addListener(_validateForm);
    _plateCtrl.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _validateForm() {
    final nameValid = _nameCtrl.text.trim().isNotEmpty;
    final makeValid = _makeCtrl.text.trim().isNotEmpty;
    final modelValid = _modelCtrl.text.trim().isNotEmpty;
    final plateValid = _validatePlate(_plateCtrl.text) == null;
    final newValid = nameValid && makeValid && modelValid && plateValid;
    if (newValid != _isFormValid) {
      setState(() => _isFormValid = newValid);
    }
  }

  String? _validatePlate(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Please enter the license plate';
    }

    // Validate South African license plate format
    if (!isValidSouthAfricanPlate(v.trim())) {
      return getPlateValidationError();
    }

    return null;
  }

  Future<void> _submit() async {
    if (_loading) return; // Prevent double-tap

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().completeOnboarding(
            name: _nameCtrl.text.trim(),
            carMake: _makeCtrl.text.trim(),
            carModel: _modelCtrl.text.trim(),
            carPlate: _plateCtrl.text.trim().toUpperCase().replaceAll(' ', ''),
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (e) {
      // Check if this is a duplicate plate error
      final errorMsg = e.toString();
      final friendly = errorMsg.contains('already registered')
          ? 'This license plate is already registered. Please verify your plate number.'
          : 'Unable to save your details. Please try again.';

      // show prominent feedback and also keep inline error area populated
      if (mounted) AppSnackbar.showError(context, friendly);
      setState(() => _error = friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceReduced = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      appBar: const InvisibleAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Welcome',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Full name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding:
                                      UIConstants.kInputContentPadding,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Please enter your name'
                                        : null,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _makeCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Vehicle make',
                                  hintText: 'e.g., Toyota',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding:
                                      UIConstants.kInputContentPadding,
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Please enter the vehicle make'
                                        : null,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _modelCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Vehicle model',
                                  hintText: 'e.g., Corolla',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding:
                                      UIConstants.kInputContentPadding,
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Please enter the vehicle model'
                                        : null,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _plateCtrl,
                                decoration: InputDecoration(
                                  labelText: 'License plate number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding:
                                      UIConstants.kInputContentPadding,
                                ),
                                inputFormatters: const [
                                  UpperCaseTextFormatter(),
                                ],
                                validator: _validatePlate,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _isFormValid ? _submit() : null,
                              ),
                              const SizedBox(height: 20),
                              if (_error != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FaIcon(FontAwesomeIcons.circleExclamation,
                                          color: theme.colorScheme.error,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom section pinned to bottom
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CarletButton.primary(
                          text: 'Finish and continue',
                          onPressed: _submit,
                          showLoading: _loading,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Note: vehicle details cannot be changed after completing onboarding.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: onSurfaceReduced),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Input formatter to convert text to uppercase as user types
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
