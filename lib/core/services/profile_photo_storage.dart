import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract final class ProfilePhotoStorage {
  static Future<String> upload(String uid, Uint8List bytes) async {
    if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('You can edit only your own photo.');
    if (bytes.length > 5 * 1024 * 1024) throw ArgumentError('Choose a photo smaller than 5 MB.');
    final ref = FirebaseStorage.instance.ref('profiles/$uid/${DateTime.now().microsecondsSinceEpoch}.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return 'storage:${ref.fullPath}';
  }
}
