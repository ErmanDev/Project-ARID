import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'ui/navigation/main_shell.dart';
import 'ui/screens/onboarding/location_onboarding_screen.dart';
import 'ui/theme/app_colors.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/arid_logo.dart';

class AridApp extends ConsumerWidget {
  const AridApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(locationOnboardingDoneProvider);
    return MaterialApp(
      title: 'A.R.I.D.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: onboarding.when(
        data: (done) =>
            done ? const MainShell() : const LocationOnboardingScreen(),
        loading: () => const _LaunchPlaceholder(),
        error: (_, _) => const MainShell(),
      ),
    );
  }
}

class _LaunchPlaceholder extends StatelessWidget {
  const _LaunchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: AridLogo(size: 96)),
    );
  }
}

class AridRoot extends ConsumerWidget {
  const AridRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivityBootstrapProvider);
    return const AridApp();
  }
}
