import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class DocumentScanService {
  final _picker = ImagePicker();

  Future<File?> scanDocument() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null) {
      final gallery = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (gallery == null) return null;
      return File(gallery.path);
    }
    return File(photo.path);
  }

  Future<String> extractText(String imagePath) async => '';

  Future<void> dispose() async {}
}

final documentScanServiceProvider = Provider<DocumentScanService>((ref) {
  return DocumentScanService();
});
