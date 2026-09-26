import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/enums.dart';
import '../../../providers.dart';
import '../../../services/location/location_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/large_title_page.dart';
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
            content: Text(
              'Not saved yet. Place a pin so the site can be found.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t save this report. Try again.')),
      );
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
        action: 'Open Settings',
      );
      if (open == true) await openAppSettings();
    } else if (outcome == LocationPermissionOutcome.denied) {
      await _showMessage(
        'Location helps others find the site',
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
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final draft = widget.draft;
    final isBreeding = draft.classification == Classification.breeding;
    final fix = _locationPreview;
    final percent = (draft.confidenceScore * 100).clamp(0, 100);

    return Stack(
      children: [
        LargeTitlePage(
          title: 'Review',
          subtitle: 'Check the result, then save your report.',
          bottomBar: FloatingActionBar(
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : () => _confirm(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save report'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Discard'),
              ),
            ],
          ),
          slivers: [
            SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.file(
                        File(draft.imageFile.path),
                        fit: BoxFit.cover,
                        semanticLabel: 'Your photo',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SectionCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RiskBadge(level: draft.riskLevel),
                        const SizedBox(height: 10),
                        Text(
                          isBreeding
                              ? 'Possible breeding site'
                              : 'No breeding site found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Confidence',
                                style: TextStyle(
                                  color: p.secondaryInk,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              '${percent.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: draft.confidenceScore.clamp(0, 1),
                            minHeight: 8,
                            color: p.risk(draft.riskLevel).fill,
                            semanticsLabel: 'Confidence',
                          ),
                        ),
                        if (!draft.usedOnDeviceModel) ...[
                          const SizedBox(height: 14),
                          _TestModelNote(),
                        ],
                      ],
                    ),
                  ),
                ),
                GroupedSection(
                  header: 'Location',
                  footer:
                      'The report saves on this device and appears on the '
                      'map once it syncs.',
                  dividerIndent: 60,
                  children: [
                    GroupedRow(
                      leading: IconTile(
                        icon: Icons.location_on_rounded,
                        color: fix == null ? p.tertiaryInk : AppColors.primary,
                      ),
                      title: _locating
                          ? 'Finding your location…'
                          : fix == null
                          ? 'No GPS signal yet'
                          : '${fix.latitude.toStringAsFixed(5)}, '
                                '${fix.longitude.toStringAsFixed(5)}',
                      subtitle: _locating
                          ? null
                          : fix == null
                          ? 'You can place the pin yourself when you save.'
                          : 'Accurate to ±${fix.accuracy.toStringAsFixed(0)} m',
                      trailing: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : null,
                    ),
                    GroupedRow(
                      title: 'Refresh location',
                      accent: true,
                      onTap: _busy || _locating
                          ? null
                          : () => unawaited(_refreshLocation()),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        if (_busy)
          const Positioned.fill(child: BusyOverlay(label: 'Saving report…')),
      ],
    );
  }
}

class _TestModelNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.science_outlined, size: 18, color: p.secondaryInk),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            kDebugMode
                ? 'Test model active. Add the trained model at '
                      'assets/models/arid_model.tflite for real results.'
                : 'This result comes from a test model and may be inaccurate.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
