import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/enums.dart';
import '../../../providers.dart';
import '../../../services/location/location_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'pin_drop_screen.dart';
import 'result_screen.dart';

/// Shows classification remarks and asks the user to confirm before pinning.
class RemarksScreen extends ConsumerStatefulWidget {
  const RemarksScreen({super.key, required this.draft});

  final ClassificationDraft draft;

  @override
  ConsumerState<RemarksScreen> createState() => _RemarksScreenState();
}

class _RemarksScreenState extends ConsumerState<RemarksScreen> {
  bool _busy = false;
  GpsFix? _locationPreview;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshLocation());
    });
  }

  Future<void> _refreshLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      await ref.read(locationServiceProvider).requestPermission();
      final fix = await ref.read(locationServiceProvider).freshFix();
      if (!mounted) return;
      setState(() => _locationPreview = fix);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _confirm({GpsFix? manualFix}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (manualFix == null) {
        await _ensureLocationReady();
        if (_locationPreview == null) {
          await _refreshLocation();
        }
      }
      if (!mounted) return;

      final resolvedFix = manualFix ?? _locationPreview;
      if (resolvedFix == null) {
        throw const GpsRequiredException();
      }

      final outcome = await ref.read(confirmReportProvider)(
        ConfirmReportInput(draft: widget.draft, manualFix: resolvedFix),
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultScreen(outcome: outcome)),
      );
    } on GpsRequiredException {
      if (!mounted) return;
      final fix = await Navigator.of(
        context,
      ).push<GpsFix>(MaterialPageRoute(builder: (_) => const PinDropScreen()));
      if (fix != null && mounted) {
        setState(() => _busy = false);
        await _confirm(manualFix: fix);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report not saved — a location pin is required.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save report: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ensureLocationReady() async {
    final location = ref.read(locationServiceProvider);
    final outcome = await location.requestPermission();
    if (!mounted) return;
    if (outcome == LocationPermissionOutcome.disabled) {
      await _showMessage(
        'Location is turned off',
        '${LocationService.rationale}\n\nYou can still drop a pin on the map.',
      );
    } else if (outcome == LocationPermissionOutcome.permanentlyDenied) {
      final open = await _showMessage(
        'Location permission needed',
        '${LocationService.rationale}\n\nOpen Settings to allow location, or drop a pin on the map.',
        action: 'Open settings',
      );
      if (open == true) await openAppSettings();
    } else if (outcome == LocationPermissionOutcome.denied) {
      await _showMessage(
        'Location helps the map',
        '${LocationService.rationale}\n\nIf GPS is unavailable, you can place the pin yourself.',
      );
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
    final draft = widget.draft;
    final isBreeding = draft.classification == Classification.breeding;
    final title = isBreeding ? 'Breeding site detected' : 'Non-breeding';

    return Scaffold(
      appBar: AppBar(title: const Text('Remarks')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(draft.imageFile.path),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              RiskBadge(level: draft.riskLevel),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Confidence ${(draft.confidenceScore * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: context.aridMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Risk: ${switch (draft.riskLevel) {
                        RiskLevel.red => 'High',
                        RiskLevel.yellow => 'Moderate',
                        RiskLevel.green => 'Non-breeding',
                      }}',
                      style: TextStyle(color: context.aridMuted),
                    ),
                    if (!draft.usedOnDeviceModel) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Development classifier is active. Place your Teachable Machine export at assets/models/arid_model.tflite for production inference.',
                        style: TextStyle(
                          color: context.aridMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location for this report',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_locating)
                      Text(
                        'Refreshing GPS…',
                        style: TextStyle(color: context.aridMuted),
                      )
                    else if (_locationPreview != null)
                      Text(
                        '${_locationPreview!.latitude.toStringAsFixed(5)}, '
                        '${_locationPreview!.longitude.toStringAsFixed(5)}\n'
                        'Accuracy ±${_locationPreview!.accuracy.toStringAsFixed(0)} m',
                        style: TextStyle(color: context.aridMuted, height: 1.45),
                      )
                    else
                      Text(
                        'GPS not ready yet. Refresh before confirming, or drop a pin if needed.',
                        style: TextStyle(color: context.aridMuted, height: 1.45),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy || _locating
                          ? null
                          : () => unawaited(_refreshLocation()),
                      icon: const Icon(Icons.my_location),
                      label: const Text('Refresh my location'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Text(
                  'Confirm to pin this site with your refreshed location. The report saves on this device and syncs to the map when online.',
                  style: TextStyle(color: context.aridMuted, height: 1.45),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : () => _confirm(),
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Confirm & pin location'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Discard'),
              ),
            ],
          ),
          if (_busy)
            ColoredBox(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.78),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Getting location…'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
