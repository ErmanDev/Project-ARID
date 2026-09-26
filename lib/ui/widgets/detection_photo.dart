import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/classification/classification_result.dart';

/// Per-class box colours, matching the web dashboard's Analyze page.
const detectionColors = [
  Color(0xFF00A9CC),
  Color(0xFFE08A1E),
  Color(0xFF8B7BF0),
  Color(0xFFE0555F),
  Color(0xFF3FB488),
];

Color detectionColor(int classId) =>
    detectionColors[classId % detectionColors.length];

/// Dark ink on light fills, white on dark ones, so chip labels stay legible.
Color detectionInk(Color fill) =>
    fill.computeLuminance() > 0.19 ? const Color(0xFF0B1220) : Colors.white;

/// A photo with the detector's boxes drawn over each container it found.
class DetectionPhoto extends StatelessWidget {
  const DetectionPhoto({
    super.key,
    required this.file,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  final File file;
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final hasSize = imageWidth > 0 && imageHeight > 0;
    final aspect = hasSize ? imageWidth / imageHeight : 4 / 3;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        // Keep very tall or very wide photos from dominating the screen.
        aspectRatio: aspect.clamp(3 / 4, 16 / 9),
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sx = hasSize ? constraints.maxWidth / imageWidth : 0.0;
                  final sy = hasSize
                      ? constraints.maxHeight / imageHeight
                      : 0.0;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        file,
                        fit: BoxFit.fill,
                        semanticLabel: 'Your photo',
                      ),
                      if (hasSize)
                        for (final d in detections)
                          Positioned(
                            left: d.x * sx,
                            top: d.y * sy,
                            width: d.width * sx,
                            height: d.height * sy,
                            child: _Box(detection: d),
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final color = detectionColor(detection.classId);
    final percent = (detection.confidence * 100).round();
    return Semantics(
      label: '${detection.label}, $percent% confidence',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            color: color,
            child: Text(
              '${detection.label} $percent%',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: detectionInk(color),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
