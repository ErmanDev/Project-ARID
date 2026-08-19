import '../../data/models/enums.dart';
import '../../data/models/user_profile.dart';

/// Tunable locally. Stored in the AppConfig table so Chapter III thresholds
/// can be adjusted without a rebuild.
class PointsRules {
  const PointsRules({
    this.highConfidenceThreshold = 0.70,
    this.completeReport = 10,
    this.breedingBonus = 5,
    this.highConfidenceBonus = 5,
    this.redRiskBonus = 3,
    this.streakBonus = 2,
  });

  final double highConfidenceThreshold;
  final int completeReport;
  final int breedingBonus;
  final int highConfidenceBonus;
  final int redRiskBonus;
  final int streakBonus;

  List<MapEntry<String, String>> get documented => [
        MapEntry('Complete report', '+$completeReport'),
        MapEntry('Breeding detection', '+$breedingBonus'),
        MapEntry(
          'High confidence (≥ ${(highConfidenceThreshold * 100).round()}%)',
          '+$highConfidenceBonus',
        ),
        MapEntry('Red-risk site', '+$redRiskBonus'),
        MapEntry('Streak (consecutive day)', '+$streakBonus'),
      ];
}

class PointsAward {
  const PointsAward({required this.points, required this.breakdown});

  final int points;
  final List<String> breakdown;
}

class PointsEngine {
  const PointsEngine(this.rules);

  final PointsRules rules;

  PointsAward award({
    required Classification classification,
    required double confidence,
    required RiskLevel riskLevel,
    required UserProfile profile,
    required DateTime capturedAt,
  }) {
    var total = rules.completeReport;
    final breakdown = <String>['Complete report +${rules.completeReport}'];

    if (classification == Classification.breeding) {
      total += rules.breedingBonus;
      breakdown.add('Breeding detection +${rules.breedingBonus}');
    }
    if (confidence >= rules.highConfidenceThreshold) {
      total += rules.highConfidenceBonus;
      breakdown.add('High confidence +${rules.highConfidenceBonus}');
    }
    if (riskLevel == RiskLevel.red) {
      total += rules.redRiskBonus;
      breakdown.add('Red-risk site +${rules.redRiskBonus}');
    }

    final last = profile.lastReportDate;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final today = DateTime(capturedAt.year, capturedAt.month, capturedAt.day);
      if (today.difference(lastDay).inDays == 1) {
        total += rules.streakBonus;
        breakdown.add('Streak bonus +${rules.streakBonus}');
      }
    }

    return PointsAward(points: total, breakdown: breakdown);
  }
}

class RewardBadge {
  const RewardBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.earned,
  });

  final String id;
  final String title;
  final String description;
  final bool earned;
}

List<RewardBadge> badgesFor({
  required int reportCount,
  required int totalPoints,
  required int redCount,
  required int streak,
}) {
  return [
    RewardBadge(
      id: 'first_report',
      title: 'First pin',
      description: 'Submit your first report',
      earned: reportCount >= 1,
    ),
    RewardBadge(
      id: 'ten_reports',
      title: 'Field regular',
      description: 'Submit 10 reports',
      earned: reportCount >= 10,
    ),
    RewardBadge(
      id: 'fifty_reports',
      title: 'Barangay scout',
      description: 'Submit 50 reports',
      earned: reportCount >= 50,
    ),
    RewardBadge(
      id: 'red_spotter',
      title: 'High-risk spotter',
      description: 'Log 5 red-risk breeding sites',
      earned: redCount >= 5,
    ),
    RewardBadge(
      id: 'points_100',
      title: '100 points',
      description: 'Reach 100 local points',
      earned: totalPoints >= 100,
    ),
    RewardBadge(
      id: 'points_500',
      title: '500 points',
      description: 'Reach 500 local points',
      earned: totalPoints >= 500,
    ),
    RewardBadge(
      id: 'streak_3',
      title: 'Three-day streak',
      description: 'Report on 3 consecutive days',
      earned: streak >= 3,
    ),
  ];
}
