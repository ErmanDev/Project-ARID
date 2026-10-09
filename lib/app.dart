import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'ui/navigation/main_shell.dart';
import 'ui/screens/auth/sign_in_screen.dart';
import 'ui/screens/onboarding/location_onboarding_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/arid_logo.dart';

class AridApp extends ConsumerWidget {
  const AridApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    final onboarding = ref.watch(locationOnboardingDoneProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'A.R.I.D.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      highContrastTheme: AppTheme.highContrastLight,
      highContrastDarkTheme: AppTheme.highContrastDark,
      themeMode: themeMode,
      home: switch (user) {
        AsyncData(value: null) || AsyncError() => const SignInScreen(),
        AsyncData() => onboarding.when(
          data: (done) =>
              done ? const MainShell() : const LocationOnboardingScreen(),
          loading: () => const _LaunchPlaceholder(),
          error: (_, _) => const MainShell(),
        ),
        _ => const _LaunchPlaceholder(),
      },
    );
  }
}

class _LaunchPlaceholder extends StatelessWidget {
  const _LaunchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AridLogo(size: 96)));
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
