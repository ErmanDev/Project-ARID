import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../../data/models/enums.dart';
import 'classification_result.dart';

/// On-device YOLOv5s breeding-container detector.
///
/// Runs the same `medsam_yolov5s.onnx` model as the web dashboard's Analyze
/// page (dashboard/src/services/detection/yolo.ts) with identical pre- and
/// post-processing, so both surfaces report the same containers. A photo is a
/// possible breeding site when at least one container is detected.
///
/// If the model cannot load, a deterministic fallback is used so the rest of
/// the offline pipeline can still be demonstrated.
class ClassifierService {
  ClassifierService();

  static const modelAsset = 'assets/models/medsam_yolov5s.onnx';

  static const classes = [
    'Bottle',
    'Coconut-Exocarp',
    'Drain-Inlet',
    'Tire',
    'Vase',
  ];

  static const _inputSize = 640;
  static const _confidenceThreshold = 0.25;
  static const _iouThreshold = 0.45;
  static const _maxDetections = 100;

  OrtSession? _session;
  bool _ready = false;

  bool get usingOnDeviceModel => _session != null;

  Future<void> init() async {
    if (_ready) return;
    try {
      OrtEnv.instance.init();
      final raw = await rootBundle.load(modelAsset);
      final options = OrtSessionOptions()
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
      _session = OrtSession.fromBuffer(raw.buffer.asUint8List(), options);
      options.release();
    } catch (_) {
      _session = null;
    }
    _ready = true;
  }

  Future<ClassificationResult> classify(File imageFile) async {
    await init();
    if (_session != null) {
      return _detect(imageFile);
    }
    return _fallbackClassify(imageFile);
  }

  Future<ClassificationResult> _detect(File imageFile) async {
    final session = _session!;
    final bytes = await imageFile.readAsBytes();
    final prepared = await Isolate.run(() => _prepareInput(bytes));

    final input = OrtValueTensor.createTensorWithDataList(prepared.tensor, [
      1,
      3,
      _inputSize,
      _inputSize,
    ]);
    final runOptions = OrtRunOptions();
    List<OrtValue?> outputs = const [];
    try {
      outputs =
          await session.runAsync(runOptions, {session.inputNames.first: input}) ??
          const [];
      final value = outputs.isEmpty ? null : outputs.first?.value;
      if (value is! List || value.isEmpty || value.first is! List) {
        throw StateError('The detection model returned an unexpected result.');
      }
      final rows = (value.first as List).cast<List>();
      return _decode(rows, prepared);
    } finally {
      input.release();
      runOptions.release();
      for (final output in outputs) {
        output?.release();
      }
    }
  }

  ClassificationResult _decode(List<List> rows, _PreparedInput prepared) {
    final candidates = <Detection>[];
    var bestRawScore = 0.0;

    for (final row in rows) {
      if (row.length < 5 + classes.length) continue;
      final objectness = (row[4] as num).toDouble();

      var classId = 0;
      var classProbability = (row[5] as num).toDouble();
      for (var index = 1; index < classes.length; index++) {
        final probability = (row[5 + index] as num).toDouble();
        if (probability > classProbability) {
          classId = index;
          classProbability = probability;
        }
      }

      final confidence = objectness * classProbability;
      if (confidence > bestRawScore) bestRawScore = confidence;
      if (objectness < _confidenceThreshold ||
          confidence < _confidenceThreshold) {
        continue;
      }

      final centerX = (row[0] as num).toDouble();
      final centerY = (row[1] as num).toDouble();
      final boxWidth = (row[2] as num).toDouble();
      final boxHeight = (row[3] as num).toDouble();
      double mapX(double v) =>
          ((v - prepared.padX) / prepared.scale).clamp(0, prepared.width);
      double mapY(double v) =>
          ((v - prepared.padY) / prepared.scale).clamp(0, prepared.height);
      final left = mapX(centerX - boxWidth / 2);
      final top = mapY(centerY - boxHeight / 2);
      final right = mapX(centerX + boxWidth / 2);
      final bottom = mapY(centerY + boxHeight / 2);
      if (right <= left || bottom <= top) continue;

      candidates.add(
        Detection(
          classId: classId,
          label: classes[classId],
          confidence: confidence,
          x: left,
          y: top,
          width: right - left,
          height: bottom - top,
        ),
      );
    }

    final detections = _nonMaximumSuppression(candidates);
    final found = detections.isNotEmpty;
    final top = found ? detections.first : null;

    final byLabel = <String, double>{};
    for (final detection in detections) {
      byLabel[detection.label] = math.max(
        byLabel[detection.label] ?? 0,
        detection.confidence,
      );
    }

    return ClassificationResult(
      classification: found
          ? Classification.breeding
          : Classification.nonBreeding,
      // With no detections, confidence is how clearly the best candidate fell
      // short of being a container.
      confidenceScore: found ? top!.confidence : 1 - bestRawScore,
      label: found ? top!.label : 'No containers',
      usedOnDeviceModel: true,
      allScores: byLabel,
      detections: detections,
      imageWidth: prepared.width,
      imageHeight: prepared.height,
    );
  }

  static double _intersectionOverUnion(Detection a, Detection b) {
    final left = math.max(a.x, b.x);
    final top = math.max(a.y, b.y);
    final right = math.min(a.x + a.width, b.x + b.width);
    final bottom = math.min(a.y + a.height, b.y + b.height);
    final intersection =
        math.max(0.0, right - left) * math.max(0.0, bottom - top);
    final union = a.width * a.height + b.width * b.height - intersection;
    return union > 0 ? intersection / union : 0;
  }

  static List<Detection> _nonMaximumSuppression(List<Detection> candidates) {
    final ordered = [...candidates]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <Detection>[];
    for (final candidate in ordered) {
      final overlaps = kept.any(
        (existing) =>
            existing.classId == candidate.classId &&
            _intersectionOverUnion(existing, candidate) > _iouThreshold,
      );
      if (!overlaps) kept.add(candidate);
      if (kept.length >= _maxDetections) break;
    }
    return kept;
  }

  /// Letterboxes the photo into a 640x640 grey canvas and packs it as a
  /// planar RGB float tensor in [0, 1], matching YOLOv5's export.
  static _PreparedInput _prepareInput(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image for detection.');
    }
    final oriented = img.bakeOrientation(decoded);
    final width = oriented.width;
    final height = oriented.height;

    final scale = math.min(_inputSize / width, _inputSize / height);
    final renderedWidth = math.max(1, (width * scale).round());
    final renderedHeight = math.max(1, (height * scale).round());
    final padX = (_inputSize - renderedWidth) / 2;
    final padY = (_inputSize - renderedHeight) / 2;

    final resized = img.copyResize(
      oriented,
      width: renderedWidth,
      height: renderedHeight,
      interpolation: img.Interpolation.linear,
    );

    const plane = _inputSize * _inputSize;
    const grey = 114 / 255;
    final tensor = Float32List(plane * 3)..fillRange(0, plane * 3, grey);
    final offsetX = padX.floor();
    final offsetY = padY.floor();
    for (var y = 0; y < renderedHeight; y++) {
      final row = (y + offsetY) * _inputSize + offsetX;
      for (var x = 0; x < renderedWidth; x++) {
        final pixel = resized.getPixel(x, y);
        final index = row + x;
        tensor[index] = pixel.r / 255;
        tensor[plane + index] = pixel.g / 255;
        tensor[plane * 2 + index] = pixel.b / 255;
      }
    }

    return _PreparedInput(
      tensor: tensor,
      width: width.toDouble(),
      height: height.toDouble(),
      scale: scale,
      padX: offsetX.toDouble(),
      padY: offsetY.toDouble(),
    );
  }

  Future<ClassificationResult> _fallbackClassify(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    var hash = 0;
    for (var i = 0; i < bytes.length; i += 17) {
      hash = (hash * 31 + bytes[i]) & 0x7fffffff;
    }
    final breedingScore = 0.45 + (hash % 50) / 100.0;
    final nonBreedingScore = 1.0 - breedingScore;
    final isBreeding = breedingScore >= nonBreedingScore;
    return ClassificationResult(
      classification: isBreeding
          ? Classification.breeding
          : Classification.nonBreeding,
      confidenceScore: isBreeding ? breedingScore : nonBreedingScore,
      label: isBreeding ? 'Breeding' : 'Non Breeding',
      usedOnDeviceModel: false,
      allScores: {'Breeding': breedingScore, 'Non Breeding': nonBreedingScore},
    );
  }

  void dispose() {
    _session?.release();
    _session = null;
    _ready = false;
  }
}

class _PreparedInput {
  const _PreparedInput({
    required this.tensor,
    required this.width,
    required this.height,
    required this.scale,
    required this.padX,
    required this.padY,
  });

  final Float32List tensor;
  final double width;
  final double height;
  final double scale;
  final double padX;
  final double padY;
}
