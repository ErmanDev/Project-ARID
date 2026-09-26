import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/large_title_page.dart';
import 'remarks_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  bool _busy = false;
  String? _busyLabel;

  Future<void> _start(
    Future<File?> Function() pick, {
    bool camera = false,
  }) async {
    if (_busy) return;
    if (camera) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted && mounted) {
        final open = await _showMessage(
          'Allow camera access',
          'A.R.I.D. needs the camera to photograph possible breeding sites. '
              'The photo is checked on this device.',
          action: cameraStatus.isPermanentlyDenied ? 'Open Settings' : null,
        );
        if (open == true) await openAppSettings();
        return;
      }
    }

    setState(() {
      _busy = true;
      _busyLabel = 'Finding your location…';
    });
    try {
      await ref.read(locationServiceProvider).requestPermission();
      await ref
          .read(locationServiceProvider)
          .freshFix(timeout: const Duration(seconds: 10));
    } catch (_) {
      // Camera can still open; the review step refreshes the location again.
    }

    if (!mounted) return;
    setState(() => _busyLabel = camera ? 'Opening camera…' : 'Opening photos…');
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
      _busyLabel = 'Checking your photo…';
    });
    try {
      final draft = await ref.read(classifyCaptureProvider)(file);
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => RemarksScreen(draft: draft)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Couldn’t check this photo. Try again with a clearer, closer shot.',
          ),
        ),
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

  Future<bool?> _showMessage(String title, String body, {String? action}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(action == null ? 'OK' : 'Not now'),
          ),
          if (action != null)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
        ],
      ),
    );
  }

  void _takePhoto() =>
      _start(ref.read(imageServiceProvider).pickFromCamera, camera: true);

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Stack(
      children: [
        LargeTitlePage(
          title: 'Capture',
          subtitle: 'Photograph a possible breeding site.',
          slivers: [
            SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _Viewfinder(onTap: _busy ? null : _takePhoto),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Take photo'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _start(
                            ref.read(imageServiceProvider).pickFromGallery,
                          ),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Choose existing photo'),
                  ),
                ),
                GroupedSection(
                  header: 'How it works',
                  dividerIndent: 60,
                  footer:
                      'For the best result, fill the frame with the container '
                      'or water and shoot in daylight.',
                  children: [
                    for (final (i, step) in const [
                      'The photo is checked for signs of breeding',
                      'Review the result and its risk level',
                      'Confirm where the site is',
                      'Save — it syncs when you’re online',
                    ].indexed)
                      GroupedRow(
                        leading: _StepNumber(i + 1, color: p.accent),
                        title: step,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        if (_busy) Positioned.fill(child: BusyOverlay(label: _busyLabel ?? '')),
      ],
    );
  }
}

class _StepNumber extends StatelessWidget {
  const _StepNumber(this.number, {required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final size = MediaQuery.textScalerOf(context).scale(30).clamp(30.0, 44.0);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.accentTint, shape: BoxShape.circle),
      child: Text(
        '$number',
        style: TextStyle(
          color: p.accentInk,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// A large, easy-to-hit target that reads as "point the camera here".
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Semantics(
      button: true,
      label: 'Take photo',
      excludeSemantics: true,
      child: Material(
        color: p.accentTint,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            // The hint is decorative; its twin is the Take photo button.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 2,
              child: _viewfinderContent(p),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewfinderContent(AridPalette p) {
    return Builder(
      builder: (context) => SizedBox.expand(
        child: CustomPaint(
          painter: _CornerBrackets(p.accentInk.withValues(alpha: 0.55)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: p.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 34,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Aim at containers, tires, drains or puddles',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.accentInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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

class _CornerBrackets extends CustomPainter {
  _CornerBrackets(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const inset = 22.0, arm = 26.0;
    final w = size.width, h = size.height;
    for (final (x, y, dx, dy) in [
      (inset, inset, 1.0, 1.0),
      (w - inset, inset, -1.0, 1.0),
      (inset, h - inset, 1.0, -1.0),
      (w - inset, h - inset, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * arm)
          ..lineTo(x, y)
          ..lineTo(x + dx * arm, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerBrackets old) => old.color != color;
}
