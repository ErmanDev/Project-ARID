import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/enums.dart';
import '../../data/models/report.dart';

class ConfusionMatrix {
  const ConfusionMatrix({
    required this.tp,
    required this.tn,
    required this.fp,
    required this.fn,
    required this.unlabeled,
  });

  final int tp;
  final int tn;
  final int fp;
  final int fn;
  final int unlabeled;

  int get labeled => tp + tn + fp + fn;

  double get accuracy => labeled == 0 ? 0 : (tp + tn) / labeled;

  double get precision => (tp + fp) == 0 ? 0 : tp / (tp + fp);

  double get recall => (tp + fn) == 0 ? 0 : tp / (tp + fn);
}

class EvaluationExportService {
  ConfusionMatrix matrix(List<Report> reports) {
    var tp = 0, tn = 0, fp = 0, fn = 0, unlabeled = 0;
    for (final report in reports) {
      if (report.groundTruth == GroundTruth.unlabeled) {
        unlabeled += 1;
        continue;
      }
      final predictedBreeding =
          report.classification == Classification.breeding;
      final actualBreeding = report.groundTruth == GroundTruth.breeding;
      if (predictedBreeding && actualBreeding) tp += 1;
      if (!predictedBreeding && !actualBreeding) tn += 1;
      if (predictedBreeding && !actualBreeding) fp += 1;
      if (!predictedBreeding && actualBreeding) fn += 1;
    }
    return ConfusionMatrix(tp: tp, tn: tn, fp: fp, fn: fn, unlabeled: unlabeled);
  }

  String toCsv(List<Report> reports) {
    final buffer = StringBuffer()
      ..writeln(
        [
          'id',
          'classification',
          'groundTruth',
          'confidence',
          'riskLevel',
          'latitude',
          'longitude',
          'gpsAccuracy',
          'gpsManual',
          'capturedAt',
          'pointsAwarded',
          'pointsStatus',
          'syncStatus',
        ].join(','),
      );
    for (final report in reports) {
      buffer.writeln(
        [
          report.id,
          report.classification.name,
          report.groundTruth.name,
          report.confidenceScore.toStringAsFixed(4),
          report.riskLevel.name,
          report.latitude.toStringAsFixed(6),
          report.longitude.toStringAsFixed(6),
          report.gpsAccuracy.toStringAsFixed(1),
          report.gpsManual,
          report.capturedAt.toIso8601String(),
          report.pointsAwarded,
          report.pointsStatus.name,
          report.syncStatus.name,
        ].join(','),
      );
    }
    return buffer.toString();
  }

  String toJson(List<Report> reports) {
    final stats = matrix(reports);
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'confusionMatrix': {
        'tp': stats.tp,
        'tn': stats.tn,
        'fp': stats.fp,
        'fn': stats.fn,
        'unlabeled': stats.unlabeled,
        'accuracy': stats.accuracy,
        'precision': stats.precision,
        'recall': stats.recall,
      },
      'reports': [
        for (final report in reports)
          {
            'id': report.id,
            'classification': report.classification.name,
            'groundTruth': report.groundTruth.name,
            'confidence': report.confidenceScore,
            'riskLevel': report.riskLevel.name,
            'latitude': report.latitude,
            'longitude': report.longitude,
            'gpsAccuracy': report.gpsAccuracy,
            'gpsManual': report.gpsManual,
            'capturedAt': report.capturedAt.toIso8601String(),
            'pointsAwarded': report.pointsAwarded,
            'pointsStatus': report.pointsStatus.name,
            'syncStatus': report.syncStatus.name,
          },
      ],
    });
  }

  Future<File> writeFile({
    required String contents,
    required String extension,
  }) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(dir.path, 'arid_evaluation_$stamp.$extension'));
    await file.writeAsString(contents, flush: true);
    return file;
  }
}
