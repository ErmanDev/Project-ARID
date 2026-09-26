import '../../data/models/enums.dart';

class ClassificationResult {
  const ClassificationResult({
    required this.classification,
    required this.confidenceScore,
    required this.label,
    required this.usedOnDeviceModel,
    this.allScores = const {},
    this.detections = const [],
    this.imageWidth = 0,
    this.imageHeight = 0,
  });

  final Classification classification;
  final double confidenceScore;
  final String label;
  final bool usedOnDeviceModel;
  final Map<String, double> allScores;

  /// Containers found by the detector, highest confidence first, in the
  /// coordinates of the upright photo ([imageWidth] x [imageHeight]).
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;
}

/// One potential breeding container located in a photo.
class Detection {
  const Detection({
    required this.classId,
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int classId;
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;
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
