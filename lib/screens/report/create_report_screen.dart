import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/services/report_service.dart';
import 'package:carlet/utils/snackbar.dart';
import 'package:carlet/utils/ui_constants.dart';

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
  bool _anonymous = false;
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
    return Scaffold(
      appBar: AppBar(
        // Invisible AppBar: transparent background, zero elevation
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),
            TextField(
              controller: _plate,
              decoration: const InputDecoration(
                labelText: 'License plate',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ).copyWith(contentPadding: UIConstants.kInputContentPadding),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'e.g. Your headlights are on',
                prefixIcon: Icon(Icons.message_outlined),
              ).copyWith(contentPadding: UIConstants.kInputContentPadding),
              maxLength: 120,
            ),
            SwitchListTile(
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              title: const Text('Post anonymously'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(UIConstants.kButtonMinHeight)),
                icon: const Icon(Icons.send),
                label: const Text('Post alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
