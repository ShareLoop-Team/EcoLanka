// Image uploads via Cloudinary (free plan, replaces Firebase Storage).
// Works on Android, iOS and web (uses bytes, not dart:io File).
// Config: lib/config/app_config.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';

class CloudinaryService {
  CloudinaryService._();

  static final ImagePicker _picker = ImagePicker();

  /// Opens gallery/camera and returns a compressed image, or null if cancelled.
  static Future<XFile?> pickImage({bool fromCamera = false}) {
    return _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 70, // keeps most photos well under 500 KB
    );
  }

  /// Picks several gallery images (capped at [AppConfig.maxItemImages]).
  static Future<List<XFile>> pickImages() async {
    final files = await _picker.pickMultiImage(maxWidth: 1280, imageQuality: 70);
    return files.take(AppConfig.maxItemImages).toList();
  }

  /// Uploads [file] and returns its public HTTPS URL.
  /// [folder] e.g. 'items/<itemId>', 'users/<uid>', 'reports/<reportId>'.
  static Future<String> upload(XFile file, {required String folder}) async {
    if (AppConfig.cloudinaryCloudName.startsWith('REPLACE')) {
      throw StateError('Set cloudinaryCloudName in lib/config/app_config.dart');
    }
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..fields['folder'] = 'shareloop/$folder'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception('Image upload failed (${response.statusCode}): ${response.body}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['secure_url'] as String;
  }

  /// Uploads several images in order and returns their URLs.
  static Future<List<String>> uploadAll(List<XFile> files, {required String folder}) async {
    final urls = <String>[];
    for (final f in files.take(AppConfig.maxItemImages)) {
      urls.add(await upload(f, folder: folder));
    }
    return urls;
  }
}

/* Example — creating an item with photos:

final itemRef = FirebaseFirestore.instance.collection('items').doc();
final urls = await CloudinaryService.uploadAll(picked, folder: 'items/${itemRef.id}');
await itemRef.set(Item(
  id: itemRef.id,
  donorId: FirebaseAuth.instance.currentUser!.uid,
  title: title, description: description, categoryId: categoryId,
  condition: condition, images: urls, district: district, city: city,
).toNewDoc());
*/
