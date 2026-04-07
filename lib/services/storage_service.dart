import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image for a specific artwork
  /// Returns the download URL
  Future<String> uploadWorkImage({
    required String uid,
    required String workId,
    required String filePath,
  }) async {
    final ref = _storage.ref('users/$uid/works/$workId/image.jpg');

    if (kIsWeb) {
      final file = XFile(filePath);
      final bytes = await file.readAsBytes();
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } else {
      final file = File(filePath);
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    }
  }

  /// Upload from bytes (useful for web)
  Future<String> uploadWorkImageBytes({
    required String uid,
    required String workId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref('users/$uid/works/$workId/image.jpg');
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete all files for a specific artwork
  Future<void> deleteWorkFiles(String uid, String workId) async {
    try {
      final ref = _storage.ref('users/$uid/works/$workId');
      final listResult = await ref.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // If folder doesn't exist, ignore
      debugPrint('Error deleting work files: $e');
    }
  }

  /// Delete all files for a user (account deletion)
  Future<void> deleteUserFiles(String uid) async {
    try {
      final ref = _storage.ref('users/$uid');
      final listResult = await ref.listAll();
      for (final prefix in listResult.prefixes) {
        final items = await prefix.listAll();
        for (final item in items.items) {
          await item.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting user files: $e');
    }
  }
}

