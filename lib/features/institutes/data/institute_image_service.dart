import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/active_profile_controller.dart';
import '../../../core/services/firebase_service.dart';

/// Shared image selection/upload flow for all institute forms.
class InstituteImageService {
  InstituteImageService._();
  static final instance = InstituteImageService._();

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
      maxHeight: 1200,
    );
    if (picked == null) return null;

    // Demo images remain local and never touch Firebase Storage.
    if (ActiveProfileController.instance.isDemo || !FirebaseService.initialized) {
      return picked.path;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before uploading an institute image.');
    }

    final safeName = picked.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final reference = FirebaseStorage.instance
        .ref('institutes/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$safeName');
    await reference.putFile(File(picked.path));
    return reference.getDownloadURL();
  }
}
