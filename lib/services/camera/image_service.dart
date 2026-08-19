import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<File?> pickFromCamera() => _pick(ImageSource.camera);

  Future<File?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<File?> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 92,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Copy out of the picker cache into durable local storage.
  Future<File> persistReportImage({
    required File source,
    required String reportId,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'reports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final dest = File(p.join(dir.path, '$reportId.jpg'));
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return source.copy(dest.path);
    }
    final resized = decoded.width > 1600
        ? img.copyResize(decoded, width: 1600)
        : decoded;
    await dest.writeAsBytes(img.encodeJpg(resized, quality: 82), flush: true);
    return dest;
  }

  /// Smaller JPEG used only when uploading to Cloudinary.
  Future<File> compressForUpload(File source) async {
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return source;
    final resized = decoded.width > 1280
        ? img.copyResize(decoded, width: 1280)
        : decoded;
    final docs = await getApplicationDocumentsDirectory();
    final dest = File(
      p.join(docs.path, 'uploads', '${p.basenameWithoutExtension(source.path)}_sync.jpg'),
    );
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(img.encodeJpg(resized, quality: 70), flush: true);
    return dest;
  }

  Future<void> deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
