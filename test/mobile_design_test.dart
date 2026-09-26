import 'package:arid/data/models/enums.dart';
import 'package:arid/data/models/report.dart';
import 'package:arid/data/repositories/config_repository.dart';
import 'package:arid/data/repositories/repositories.dart';
import 'package:arid/providers.dart';
import 'package:arid/services/rewards/points_rules.dart';
import 'package:arid/ui/navigation/app_navigation.dart';
import 'package:arid/ui/screens/capture/capture_screen.dart';
import 'package:arid/ui/screens/history/history_screen.dart';
import 'package:arid/ui/screens/home/home_screen.dart';
import 'package:arid/ui/screens/profile/profile_screen.dart';
import 'package:arid/ui/screens/rewards/rewards_screen.dart';
import 'package:arid/ui/theme/app_colors.dart';
import 'package:arid/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Config extends Fake implements ConfigRepository {
  @override
  Future<String> get(String key, {String fallback = ''}) async => fallback;
}

class _Reports extends Fake implements ReportRepository {
  final deleted = <String>[];

  @override
  Future<void> deleteLocal(String id) async => deleted.add(id);
}

Report _report({
  String id = 'local-report',
  RiskLevel risk = RiskLevel.green,
  SyncStatus sync = SyncStatus.pendingUpload,
}) => Report()
  ..id = id
  ..imagePath = 'missing-photo.jpg'
  ..classification = risk == RiskLevel.green
      ? Classification.nonBreeding
      : Classification.breeding
  ..riskLevel = risk
  ..confidenceScore = 0.82
  ..capturedAt = DateTime(2026, 9, 24, 10)
  ..syncStatus = sync
  ..groundTruth = GroundTruth.unlabeled;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  double scale = 1,
  bool dark = false,
  bool highContrast = false,
  _Reports? repository,
  List<Report>? reports,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configRepositoryProvider.overrideWithValue(_Config()),
        reportsProvider.overrideWith(
          (ref) => Stream.value(reports ?? [_report()]),
        ),
        profileProvider.overrideWith((ref) => Stream.value(null)),
        pointsRulesProvider.overrideWith((ref) async => const PointsRules()),
        if (repository != null)
          reportRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: switch ((dark, highContrast)) {
          (false, false) => AppTheme.light,
          (true, false) => AppTheme.dark,
          (false, true) => AppTheme.highContrastLight,
          (true, true) => AppTheme.highContrastDark,
        },
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            highContrast: highContrast,
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _mixedReports = [
  _report(id: 'a', risk: RiskLevel.red),
  _report(id: 'b', risk: RiskLevel.yellow, sync: SyncStatus.failed),
  _report(id: 'c', risk: RiskLevel.green, sync: SyncStatus.synced),
];

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('Every tab screen fits 320px at ${scale}x, dark=$dark', (
        tester,
      ) async {
        for (final screen in <Widget>[
          HomeScreen(onCapture: () {}, onOpenMap: () {}, onOpenHistory: () {}),
          const HistoryScreen(),
          const CaptureScreen(),
          const ProfileScreen(),
          const RewardsScreen(),
        ]) {
          await _pump(
            tester,
            screen,
            scale: scale,
            dark: dark,
            reports: _mixedReports,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} initial layout',
          );
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -2400),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} scrolled layout',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }

  testWidgets('Increased contrast renders opaque bars without errors', (
    tester,
  ) async {
    await _pump(
      tester,
      const HistoryScreen(),
      highContrast: true,
      reports: _mixedReports,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Large title condenses into the toolbar after scrolling', (
    tester,
  ) async {
    await _pump(tester, const HistoryScreen(), reports: _mixedReports);
    final toolbarTitle = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(AnimatedOpacity),
    );
    expect(tester.widget<AnimatedOpacity>(toolbarTitle).opacity, 0);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(toolbarTitle).opacity, 1);
  });

  testWidgets('Tab labels stay visible and pages are padded clear of the bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int index = 0;
    late EdgeInsets pagePadding;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            padding: EdgeInsets.only(bottom: 34),
            disableAnimations: true,
            textScaler: TextScaler.linear(3),
          ),
          child: StatefulBuilder(
            builder: (context, setState) => AppNavigation(
              selectedIndex: index,
              onSelected: (value) => setState(() => index = value),
              child: Builder(
                builder: (context) {
                  pagePadding = MediaQuery.paddingOf(context);
                  return const SizedBox.expand(key: Key('page'));
                },
              ),
            ),
          ),
        ),
      ),
    );
    for (final label in ['Home', 'Map', 'Capture', 'History', 'Profile']) {
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(index, 4);
    final barTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    expect(640 - pagePadding.bottom, lessThanOrEqualTo(barTop));
    expect(
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .animationDuration,
      Duration.zero,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wide navigation retains all five destinations', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppNavigation(
          selectedIndex: 3,
          onSelected: (value) => selected = value,
          child: const SizedBox(),
        ),
      ),
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('Capture'));
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancel keeps report; explicit confirmation deletes it', (
    tester,
  ) async {
    final repository = _Reports();
    await _pump(tester, const HistoryScreen(), repository: repository);
    await tester.tap(find.byTooltip('Report actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);
    await tester.tap(find.byTooltip('Report actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete report'));
    await tester.pumpAndSettle();
    expect(repository.deleted, ['local-report']);
  });

  testWidgets('Synced reports offer no delete action', (tester) async {
    await _pump(
      tester,
      const HistoryScreen(),
      reports: [_report(sync: SyncStatus.synced)],
    );
    await tester.tap(find.byTooltip('Report actions'));
    await tester.pumpAndSettle();
    expect(find.text('Label actual result'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });

  double ratio(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return ((x > y ? x : y) + 0.05) / ((x < y ? x : y) + 0.05);
  }

  test('Text and primary actions meet 4.5:1 contrast in every appearance', () {
    for (final theme in [
      AppTheme.light,
      AppTheme.dark,
      AppTheme.highContrastLight,
      AppTheme.highContrastDark,
    ]) {
      final p = theme.extension<AridPalette>()!;
      for (final bg in [p.surface, p.groupedBackground]) {
        expect(ratio(p.ink, bg), greaterThanOrEqualTo(4.5));
        expect(ratio(p.secondaryInk, bg), greaterThanOrEqualTo(4.5));
        expect(ratio(p.accent, bg), greaterThanOrEqualTo(4.5));
      }
      expect(ratio(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
      expect(ratio(p.accentInk, p.accentTint), greaterThanOrEqualTo(4.5));
      expect(ratio(p.accent, p.fill), greaterThanOrEqualTo(4.5));
    }
  });

  test('Risk colors: badge text 4.5:1, glyphs 3:1 non-text contrast', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final p = theme.extension<AridPalette>()!;
      for (final level in RiskLevel.values) {
        final tone = p.risk(level);
        expect(ratio(tone.ink, tone.tint), greaterThanOrEqualTo(4.5));
        expect(ratio(tone.fill, p.surface), greaterThanOrEqualTo(3));
      }
    }
    // Map pins always sit on light tiles, drawn with the light risk fills.
    for (final color in [
      AppColors.riskRed,
      AppColors.riskYellow,
      AppColors.riskGreen,
    ]) {
      expect(ratio(Colors.white, color), greaterThanOrEqualTo(3));
    }
  });
}
