import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_storage_service.g.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      final storagePath = _storagePathFromGoogleStorageUrl(uri);
      if (storagePath != null) {
        return await _storage.ref().child(storagePath).getDownloadURL();
      }

      return normalized;
    }

    if (normalized.startsWith('gs://')) {
      return await _storage.refFromURL(normalized).getDownloadURL();
    }

    return await _storage.ref().child(normalized).getDownloadURL();
  }

  String? _storagePathFromGoogleStorageUrl(Uri uri) {
    if (uri.host != 'storage.googleapis.com') {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.length < 2) {
      return null;
    }

    final bucket = segments.first;
    if (bucket != _storage.bucket) {
      return null;
    }

    return segments.skip(1).join('/');
  }
}

@riverpod
FirebaseStorageService firebaseStorageService(FirebaseStorageServiceRef ref) {
  return FirebaseStorageService();
}
