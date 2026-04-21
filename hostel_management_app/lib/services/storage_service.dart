import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service that handles file uploads / downloads via Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a profile image and return the download URL.
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('profile_images/$userId.jpg');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload a generic file (e.g. complaint attachment).
  Future<String> uploadFile({
    required String path,
    required File file,
  }) async {
    final ref = _storage.ref().child(path);
    final snapshot = await ref.putFile(file);
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete a file at the given storage path.
  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
}
