import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/theme_mode_button.dart';
import 'remarks_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  bool _busy = false;
  String? _busyLabel;

  Future<void> _start(Future<File?> Function() pick, {bool camera = false}) async {
    if (_busy) return;
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

    setState(() {
      _busy = true;
      _busyLabel = 'Updating GPS…';
    });
    try {
      await ref.read(locationServiceProvider).requestPermission();
      await ref.read(locationServiceProvider).freshFix(
        timeout: const Duration(seconds: 10),
      );
    } catch (_) {
      // Camera can still open; confirm step will refresh again.
    }

    if (!mounted) return;
    setState(() => _busyLabel = camera ? 'Opening camera…' : 'Opening gallery…');
    final file = await pick();
    if (!mounted) return;
    if (file == null) {
      setState(() {
        _busy = false;
        _busyLabel = null;
      });
      return;
    }
    await _classify(file);
  }

  Future<void> _classify(File file) async {
    setState(() {
      _busy = true;
      _busyLabel = 'Classifying on-device…';
    });
    try {
      final draft = await ref.read(classifyCaptureProvider)(file);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RemarksScreen(draft: draft)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not classify photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = null;
        });
      }
    }
  }

  Future<bool?> _showMessage(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture'),
        actions: const [ThemeModeButton()],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Photograph a possible breeding site. Classification runs on this device — no internet required.',
                style: TextStyle(color: context.aridMuted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _start(
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
                    : () => _start(ref.read(imageServiceProvider).pickFromGallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from gallery'),
              ),
              const SizedBox(height: 24),
              SectionCard(
                child: Builder(
                  builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What happens next',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. On-device TFLite classification\n'
                        '2. Review remarks (label, confidence, risk)\n'
                        '3. Confirm to pin your refreshed location\n'
                        '4. Saved locally — syncs to the map when online',
                        style: TextStyle(color: context.aridMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_busy)
            ColoredBox(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.78),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(_busyLabel ?? 'Working…'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
