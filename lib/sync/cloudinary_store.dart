import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/models/report.dart';
import '../services/camera/image_service.dart';

/// Uploads compressed report photos to Cloudinary (free plan, unsigned preset).
/// Capture still saves locally first; this runs only from the sync service.
class CloudinaryStore {
  CloudinaryStore({
    required this.cloudName,
    required this.uploadPreset,
    ImageService? images,
  }) : _images = images ?? ImageService();

  final String cloudName;
  final String uploadPreset;
  final ImageService _images;

  Future<String> upload(Report report) async {
    if (report.imageRemoteUrl != null && report.imageRemoteUrl!.isNotEmpty) {
      return report.imageRemoteUrl!;
    }
    final local = File(report.imagePath);
    if (!await local.exists()) {
      throw StateError('Local image missing for ${report.id}');
    }
    final compressed = await _images.compressForUpload(local);
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    Future<http.StreamedResponse> send({required bool includePublicId}) async {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset;
      if (includePublicId) {
        request.fields['public_id'] = report.id;
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          compressed.path,
          filename: '${report.id}.jpg',
        ),
      );
      return request.send();
    }

    var streamed = await send(includePublicId: true);
    var body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 400 && body.contains('not allowed')) {
      streamed = await send(includePublicId: false);
      body = await streamed.stream.bytesToString();
    }
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw StateError('Cloudinary upload failed (${streamed.statusCode}): $body');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Cloudinary returned an unexpected response.');
    }
    final url = decoded['secure_url'] as String? ?? decoded['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Cloudinary response did not include an image URL.');
    }
    return url;
  }
}
