import '../../data/models/enums.dart';

class ClassificationResult {
  const ClassificationResult({
    required this.classification,
    required this.confidenceScore,
    required this.label,
    required this.usedOnDeviceModel,
    this.allScores = const {},
  });

  final Classification classification;
  final double confidenceScore;
  final String label;
  final bool usedOnDeviceModel;
  final Map<String, double> allScores;
}

class RiskMapper {
  const RiskMapper({this.highConfidenceThreshold = 0.70});

  final double highConfidenceThreshold;

  RiskLevel map({
    required Classification classification,
    required double confidence,
  }) {
    if (classification == Classification.nonBreeding) {
      return RiskLevel.green;
    }
    if (confidence >= highConfidenceThreshold) {
      return RiskLevel.red;
    }
    return RiskLevel.yellow;
  }
}
