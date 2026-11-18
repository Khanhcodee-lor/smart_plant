import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_storage_service.g.dart';

class FirebaseStorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  Future<String> uploadFile(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getDownloadUrl(String path) async {
    return await resolveDownloadUrl(path);
  }

  Future<String> resolveDownloadUrl(String pathOrUrl) async {
    final normalized = pathOrUrl.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(normalized);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      // Pi may already provide a public or signed URL. Resolving it again
      // through Firebase Storage can block loading and invalidates signatures.
      return normalized;
    }

    if (normalized.startsWith('gs://')) {
      return await _storage.refFromURL(normalized).getDownloadURL();
    }

    return await _storage.ref().child(normalized).getDownloadURL();
  }
}

@riverpod
FirebaseStorageService firebaseStorageService(FirebaseStorageServiceRef ref) {
  return FirebaseStorageService();
}
