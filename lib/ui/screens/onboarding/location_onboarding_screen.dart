import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/config_repository.dart';
import '../../../providers.dart';
import '../../../services/location/location_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/arid_logo.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              const AridLogo(size: 96),
              const SizedBox(height: 24),
              Text(
                'Allow location',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                LocationService.rationale,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : () => _finish(request: true),
                child: Text(_busy ? 'Please wait…' : 'Allow location'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => _finish(request: false),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
