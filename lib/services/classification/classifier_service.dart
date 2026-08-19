import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../data/models/enums.dart';
import 'classification_result.dart';

/// On-device Teachable Machine / TFLite classifier.
///
/// Drop your exported model at `assets/models/arid_model.tflite` and labels at
/// `assets/models/labels.txt`. Until then, a deterministic fallback is used so
/// the rest of the offline pipeline can be demonstrated.
class ClassifierService {
  ClassifierService();

  static const modelAsset = 'assets/models/arid_model.tflite';
  static const labelsAsset = 'assets/models/labels.txt';

  Interpreter? _interpreter;
  List<String> _labels = const ['Breeding', 'Non Breeding'];
  bool _ready = false;
  bool _modelPresent = false;

  bool get usingOnDeviceModel => _modelPresent;

  Future<void> init() async {
    if (_ready) return;
    _labels = await _loadLabels();
    _modelPresent = await _assetExists(modelAsset);
    if (_modelPresent) {
      try {
        _interpreter = await Interpreter.fromAsset(modelAsset);
      } catch (_) {
        _modelPresent = false;
        _interpreter = null;
      }
    }
    _ready = true;
  }

  Future<ClassificationResult> classify(File imageFile) async {
    await init();
    if (_interpreter != null) {
      return _classifyWithModel(imageFile);
    }
    return _fallbackClassify(imageFile);
  }

  Future<ClassificationResult> _classifyWithModel(File imageFile) async {
    final interpreter = _interpreter!;
    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final inputShape = inputTensor.shape;
    final height = inputShape.length >= 3 ? inputShape[1] : 224;
    final width = inputShape.length >= 4 ? inputShape[2] : 224;
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image for classification.');
    }
    final resized = img.copyResize(decoded, width: width, height: height);

    final input = _buildInput(resized, inputTensor);
    final outputSize = outputTensor.shape.reduce((a, b) => a * b);
    final output = List.filled(outputSize, 0.0).reshape(outputTensor.shape);

    interpreter.run(input, output);

    final scores = _flattenScores(output);
    var bestIndex = 0;
    var bestScore = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }

    final label = bestIndex < _labels.length
        ? _labels[bestIndex]
        : 'class_$bestIndex';
    final classification = _isBreedingLabel(label)
        ? Classification.breeding
        : Classification.nonBreeding;

    final named = <String, double>{};
    for (var i = 0; i < scores.length; i++) {
      final name = i < _labels.length ? _labels[i] : 'class_$i';
      named[name] = scores[i];
    }

    return ClassificationResult(
      classification: classification,
      confidenceScore: bestScore,
      label: label,
      usedOnDeviceModel: true,
      allScores: named,
    );
  }

  Object _buildInput(img.Image image, Tensor tensor) {
    final shape = tensor.shape;
    final height = shape[1];
    final width = shape[2];
    final isFloat = tensor.type == TensorType.float32;

    if (isFloat) {
      final buffer = Float32List(1 * height * width * 3);
      var i = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final pixel = image.getPixel(x, y);
          buffer[i++] = pixel.r / 255.0;
          buffer[i++] = pixel.g / 255.0;
          buffer[i++] = pixel.b / 255.0;
        }
      }
      return buffer.reshape(shape);
    }

    final buffer = Uint8List(1 * height * width * 3);
    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        buffer[i++] = pixel.r.toInt();
        buffer[i++] = pixel.g.toInt();
        buffer[i++] = pixel.b.toInt();
      }
    }
    return buffer.reshape(shape);
  }

  List<double> _flattenScores(Object output) {
    final scores = <double>[];
    void walk(Object value) {
      if (value is List) {
        for (final item in value) {
          walk(item);
        }
      } else if (value is num) {
        scores.add(value.toDouble());
      }
    }

    walk(output);
    if (scores.isEmpty) {
      scores.add(0);
    }
    return scores;
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
      classification:
          isBreeding ? Classification.breeding : Classification.nonBreeding,
      confidenceScore: isBreeding ? breedingScore : nonBreedingScore,
      label: isBreeding ? _labels.first : _labels.last,
      usedOnDeviceModel: false,
      allScores: {
        _labels.first: breedingScore,
        _labels.last: nonBreedingScore,
      },
    );
  }

  bool _isBreedingLabel(String label) {
    final normalized = label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (normalized.contains('nonbreed') ||
        normalized.contains('notbreed') ||
        normalized.contains('negative') ||
        normalized.contains('safe') ||
        normalized.contains('clean')) {
      return false;
    }
    return normalized.contains('breed') ||
        normalized.contains('aedes') ||
        normalized.contains('larva') ||
        normalized.contains('mosquito') ||
        normalized.contains('positive');
  }

  Future<List<String>> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString(labelsAsset);
      final labels = raw
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (labels.length >= 2) return labels;
    } catch (_) {}
    return const ['Breeding', 'Non Breeding'];
  }

  Future<bool> _assetExists(String asset) async {
    try {
      await rootBundle.load(asset);
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _ready = false;
  }
}
