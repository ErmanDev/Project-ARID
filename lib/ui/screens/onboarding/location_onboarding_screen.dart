import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/config_repository.dart';
import '../../../providers.dart';
import '../../../services/location/location_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/arid_logo.dart';

/// The welcome screen: the one place the brand speaks up, followed by an
/// honest, in-context request for location.
class LocationOnboardingScreen extends ConsumerStatefulWidget {
  const LocationOnboardingScreen({super.key});

  @override
  ConsumerState<LocationOnboardingScreen> createState() =>
      _LocationOnboardingScreenState();
}

class _LocationOnboardingScreenState
    extends ConsumerState<LocationOnboardingScreen> {
  bool _busy = false;

  Future<void> _finish({required bool request}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (request) {
        await ref.read(locationServiceProvider).requestPermission();
      }
      await ref
          .read(configRepositoryProvider)
          .set(ConfigKeys.locationOnboardingDone, 'true');
      ref.invalidate(locationOnboardingDoneProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
                children: [
                  const Center(child: AridLogo(size: 88)),
                  const SizedBox(height: 24),
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.5,
                    child: Text(
                      'Welcome to A.R.I.D.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help your community find and clear mosquito breeding '
                    'sites before dengue spreads.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.secondaryInk, fontSize: 17),
                  ),
                  const SizedBox(height: 36),
                  _Feature(
                    icon: Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    title: 'Photograph standing water',
                    body:
                        'Each photo is checked on your phone, no internet '
                        'needed.',
                  ),
                  _Feature(
                    icon: Icons.map_rounded,
                    color: AppColors.riskRed,
                    title: 'See where the risk is',
                    body:
                        'Reports appear on a shared map of breeding '
                        'hotspots.',
                  ),
                  _Feature(
                    icon: Icons.star_rounded,
                    color: AppColors.amber,
                    title: 'Earn points for every report',
                    body: 'Build a streak and collect badges as you help.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: p.secondaryInk,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LocationService.rationale,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _busy ? null : () => _finish(request: true),
                    child: Text(_busy ? 'One moment…' : 'Allow location'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _busy ? null : () => _finish(request: false),
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 34, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(color: p.secondaryInk, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
