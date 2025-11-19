import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/services/report_service.dart';
import 'package:carlet/utils/snackbar.dart';
import 'package:carlet/utils/ui_constants.dart';
import 'package:carlet/widgets/carlet_button.dart';
import 'package:carlet/widgets/invisible_app_bar.dart';

class CreateReportScreen extends StatefulWidget {
  static const routeName = '/report';
  /// Optional callback used for creating a report. If not provided the
  /// default [ReportService.createReport] will be used. This is primarily
  /// here to make the screen testable without hitting Firebase.
  final Future<String> Function({
    required String reporterId,
    String? licensePlate,
    String? message,
    File? photoFile,
    bool anonymous,
  })? onCreateReport;

  const CreateReportScreen({super.key, this.onCreateReport});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _plate = TextEditingController();
  final _message = TextEditingController();
  final bool _anonymous = false;
  XFile? _photo;
  bool _loading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source, imageQuality: 80);
    if (img != null) setState(() => _photo = img);
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Validate license plate upfront
      final plateText = _plate.text.trim();
      if (plateText.isEmpty) {
        final friendly = 'Please enter the vehicle license plate.';
        AppSnackbar.showError(context, friendly);
        setState(() {
          _error = friendly;
          _loading = false;
        });
        return;
      }

      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      
      // Check if user is trying to report their own car
      if (user?.carPlate != null && user!.carPlate!.isNotEmpty) {
        final normalizedUserPlate = user.carPlate!.toUpperCase().replaceAll(' ', '');
        final normalizedInputPlate = plateText.toUpperCase().replaceAll(' ', '');
        
        if (normalizedUserPlate == normalizedInputPlate) {
          final friendly = 'You cannot report your own vehicle.';
          AppSnackbar.showError(context, friendly);
          setState(() {
            _error = friendly;
            _loading = false;
          });
          return;
        }
      }

      final file = _photo != null ? File(_photo!.path) : null;
      final createFn = widget.onCreateReport;
      if (createFn != null) {
        await createFn(
          reporterId: user!.id,
          licensePlate: _plate.text.trim(),
          message: _message.text.trim(),
          photoFile: file,
          anonymous: _anonymous,
        );
      } else {
        await ReportService().createReport(
          reporterId: user!.id,
          licensePlate: _plate.text.trim(),
          message: _message.text.trim(),
          photoFile: file,
          anonymous: _anonymous,
        );
      }
      if (!mounted) return;
  // Close the screen and signal success to the caller so it can show
  // feedback when it's safe to modify the navigator.
  Navigator.pop(context, true);
    } catch (e) {
      final friendly = 'Unable to post your report. Please try again.';
      AppSnackbar.showError(context, friendly);
      setState(() => _error = friendly);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: const InvisibleAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Upload photo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_photo!.path),
                    height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _plate,
              decoration: InputDecoration(
                labelText: 'License plate',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: UIConstants.kInputContentPadding,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'e.g. Your headlights are on',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: UIConstants.kInputContentPadding,
              ),
              maxLength: 120,
              maxLines: 2,
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
              const SizedBox(height: 16),
            ],
            CarletButton.primary(
              text: 'Post alert',
              onPressed: _submit,
              showLoading: _loading,
              icon: const Icon(Icons.send),
            ),
            const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
