import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../providers.dart';
import '../../../services/location/location_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'pin_drop_screen.dart';
import 'result_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  bool _busy = false;

  Future<void> _start(Future<File?> Function() pick) async {
    if (_busy) return;
    final file = await pick();
    if (file == null || !mounted) return;
    await _process(file);
  }

  Future<void> _process(File file, {GpsFix? manualFix}) async {
    setState(() => _busy = true);
    try {
      final outcome = await ref.read(submitReportProvider)(
        CaptureInput(sourceFile: file, manualFix: manualFix),
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(outcome: outcome)),
      );
    } on GpsRequiredException {
      if (!mounted) return;
      final fix = await Navigator.of(context).push<GpsFix>(
        MaterialPageRoute(builder: (_) => const PinDropScreen()),
      );
      if (fix != null && mounted) {
        await _process(file, manualFix: fix);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report not saved — a GPS tag is required.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save report: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _explainLocationThenCapture(
    Future<File?> Function() pick, {
    bool camera = false,
  }) async {
    if (camera) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted && mounted) {
        await _showMessage(
          'Camera permission needed',
          'A.R.I.D. photographs possible breeding sites so classification can run on this device.',
        );
        if (!cameraStatus.isGranted) return;
      }
    }
    final location = ref.read(locationServiceProvider);
    final outcome = await location.requestPermission();
    if (!mounted) return;
    if (outcome == LocationPermissionOutcome.disabled) {
      await _showMessage(
        'Location is turned off',
        '${LocationService.rationale}\n\nYou can still drop a pin on the map after the photo.',
      );
    } else if (outcome == LocationPermissionOutcome.permanentlyDenied) {
      final open = await _showMessage(
        'Location permission needed',
        '${LocationService.rationale}\n\nOpen Settings to allow location, or drop a pin after capture.',
        action: 'Open settings',
      );
      if (open == true) await openAppSettings();
    } else if (outcome == LocationPermissionOutcome.denied) {
      await _showMessage(
        'Location helps the map',
        '${LocationService.rationale}\n\nIf GPS is unavailable, you can place the pin yourself.',
      );
    }
    await _start(pick);
  }

  Future<bool?> _showMessage(
    String title,
    String body, {
    String? action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          if (action != null)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Photograph a possible breeding site. Classification runs on this device — no internet required.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _explainLocationThenCapture(
                          ref.read(imageServiceProvider).pickFromCamera,
                          camera: true,
                        ),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Take photo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _explainLocationThenCapture(
                          ref.read(imageServiceProvider).pickFromGallery,
                        ),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from gallery'),
              ),
              const SizedBox(height: 24),
              const SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. On-device TFLite classification\n'
                      '2. GPS tag (or manual pin if the signal fails)\n'
                      '3. Saved to local storage immediately\n'
                      '4. Provisional points awarded instantly',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x99F5F5F3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Classifying on-device…'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
