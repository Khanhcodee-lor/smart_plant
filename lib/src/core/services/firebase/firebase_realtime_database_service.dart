import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class FirebaseRealtimeDatabaseException implements Exception {
  const FirebaseRealtimeDatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseRealtimeDatabaseService {
  FirebaseRealtimeDatabaseService({
    required http.Client client,
    FirebaseAuth? auth,
    FirebaseApp? app,
  }) : _client = client,
       _auth = auth ?? FirebaseAuth.instance,
       _app = app ?? Firebase.app();

  final http.Client _client;
  final FirebaseAuth _auth;
  final FirebaseApp _app;

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _sendRequest(
      method: 'PATCH',
      path: path,
      body: jsonEncode(data),
    );
  }

  Future<void> setData(String path, Object? data) async {
    await _sendRequest(
      method: 'PUT',
      path: path,
      body: jsonEncode(data),
    );
  }

  Future<void> _sendRequest({
    required String method,
    required String path,
    required String body,
  }) async {
    final uri = await _buildUri(path);
    final response = switch (method) {
      'PATCH' => await _client.patch(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: body,
      ),
      'PUT' => await _client.put(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: body,
      ),
      _ => throw FirebaseRealtimeDatabaseException(
        'Unsupported Realtime Database method: $method',
      ),
    };

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirebaseRealtimeDatabaseException(
        'Realtime Database request failed '
        '(${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Uri> _buildUri(String path) async {
    final databaseUrl = _app.options.databaseURL;
    if (databaseUrl == null || databaseUrl.trim().isEmpty) {
      throw const FirebaseRealtimeDatabaseException(
        'Realtime Database URL is not configured.',
      );
    }

    final normalizedBase = databaseUrl.endsWith('/')
        ? databaseUrl.substring(0, databaseUrl.length - 1)
        : databaseUrl;
    final normalizedPath = path
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'^/+|/+$'), '');
    final encodedPath = normalizedPath
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');

    var uri = Uri.parse('$normalizedBase/$encodedPath.json');
    final token = await _auth.currentUser?.getIdToken();
    if (token != null && token.isNotEmpty) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'auth': token,
        },
      );
    }

    return uri;
  }
}

final firebaseRealtimeDatabaseServiceProvider =
    Provider<FirebaseRealtimeDatabaseService>((ref) {
      final client = http.Client();
      ref.onDispose(client.close);
      return FirebaseRealtimeDatabaseService(client: client);
    });
