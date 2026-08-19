import 'package:arid/data/models/enums.dart';
import 'package:arid/data/models/user_profile.dart';
import 'package:arid/services/classification/classification_result.dart';
import 'package:arid/services/rewards/points_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiskMapper', () {
    const mapper = RiskMapper(highConfidenceThreshold: 0.70);

    test('non-breeding is green', () {
      expect(
        mapper.map(
          classification: Classification.nonBreeding,
          confidence: 0.99,
        ),
        RiskLevel.green,
      );
    });

    test('breeding with high confidence is red', () {
      expect(
        mapper.map(
          classification: Classification.breeding,
          confidence: 0.85,
        ),
        RiskLevel.red,
      );
    });

    test('breeding with lower confidence is yellow', () {
      expect(
        mapper.map(
          classification: Classification.breeding,
          confidence: 0.55,
        ),
        RiskLevel.yellow,
      );
    });
  });

  group('PointsEngine', () {
    test('awards provisional points without network', () {
      final profile = UserProfile()
        ..id = 'device'
        ..displayName = 'Tester'
        ..totalPoints = 0
        ..verifiedPoints = 0
        ..reportCount = 0
        ..currentStreak = 0
        ..syncStatus = SyncStatus.pendingUpload;

      final award = const PointsEngine(PointsRules()).award(
        classification: Classification.breeding,
        confidence: 0.9,
        riskLevel: RiskLevel.red,
        profile: profile,
        capturedAt: DateTime(2026, 8, 18),
      );

      expect(award.points, 10 + 5 + 5 + 3);
      expect(award.breakdown, isNotEmpty);
    });
  });
}
