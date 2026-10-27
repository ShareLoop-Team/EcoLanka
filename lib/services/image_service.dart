// API implementation of ImageStorage — photos are uploaded to the Laravel
// backend (POST /uploads) and served from /api/files/… (replaces Cloudinary).
// Works on Android, iOS and web (uses bytes, not dart:io File).

import 'package:image_picker/image_picker.dart';

import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiImageStorage implements ImageStorage {
  ApiImageStorage(this._api, {ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ApiClient _api;
  final ImagePicker _picker;

  @override
  bool get isConfigured => true;

  /// Opens the gallery and returns a compressed image, or null if cancelled.
  @override
  Future<XFile?> pickOne() => _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 70, // keeps most photos well under 500 KB
      );

  @override
  Future<List<XFile>> pickMany(int max) async {
    final files = await _picker.pickMultiImage(maxWidth: 1280, imageQuality: 70);
    return files.take(max).toList();
  }

  /// Uploads [file] and returns its public URL. [folder] e.g. `items/{itemId}`.
  @override
  Future<String> upload(XFile file, {required String folder}) async {
    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    final json = await _api.upload(
      '/uploads',
      bytes: await file.readAsBytes(),
      filename: name,
      fields: {'folder': folder},
    ) as Map<String, dynamic>;
    return json['url'] as String;
  }
}
