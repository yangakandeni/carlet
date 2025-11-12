import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/utils/snackbar.dart';
import 'package:carlet/utils/plate_utils.dart';
import 'package:carlet/screens/home/home_screen.dart';
import 'package:carlet/widgets/carlet_button.dart';
import 'package:carlet/widgets/invisible_app_bar.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
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
    _vehicleCtrl.addListener(_validateForm);
    _plateCtrl.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _validateForm() {
    final nameValid = _nameCtrl.text.trim().isNotEmpty;
    final vehicleValid = _validateVehicle(_vehicleCtrl.text) == null;
    final plateValid = _validatePlate(_plateCtrl.text) == null;
    final newValid = nameValid && vehicleValid && plateValid;
    if (newValid != _isFormValid) {
      setState(() => _isFormValid = newValid);
    }
  }

  String? _validateVehicle(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Please enter your vehicle (e.g., Toyota Corolla)';
    }
    final parts = v.trim().split(' ');
    if (parts.length < 2) {
      return 'Please enter both make and model (e.g., Toyota Corolla)';
    }
    return null;
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
      // Parse vehicle input into make and model
      final vehicleText = _vehicleCtrl.text.trim();
      final parts = vehicleText.split(' ');
      final carMake = parts.isNotEmpty ? parts[0] : '';
      final carModel = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      
      await context.read<AuthService>().completeOnboarding(
            name: _nameCtrl.text.trim(),
            carMake: carMake,
            carModel: carModel,
            carPlate: _plateCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (e) {
      final friendly = 'Unable to save your details. Please try again.';
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
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Please enter your name'
                                    : null,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _vehicleCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Vehicle',
                                  hintText: 'e.g., Toyota Corolla',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                ),
                                validator: _validateVehicle,
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
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                ),
                                inputFormatters: const [
                                  UpperCaseTextFormatter(),
                                ],
                                validator: _validatePlate,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _isFormValid ? _submit() : null,
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
                          style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceReduced),
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
