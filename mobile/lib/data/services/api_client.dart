import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin, stateless HTTP wrapper around the ZedSync backend.
///
/// Read-only: it only ever issues GET requests.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  /// Override with `--dart-define=API_BASE_URL=http://host:8000`.
  /// Android emulators reach the host machine on 10.0.2.2.
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<Object?> getJson(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl/api/v1$path').replace(queryParameters: query);
    final http.Response res;
    try {
      res = await _client.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw ApiException('Cannot reach server: $e');
    }
    if (res.statusCode != 200) {
      throw ApiException('GET $path failed', statusCode: res.statusCode);
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<Map<String, dynamic>> getObject(String path, [Map<String, String>? query]) async =>
      (await getJson(path, query)) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> getList(String path, [Map<String, String>? query]) async =>
      ((await getJson(path, query)) as List<dynamic>).cast<Map<String, dynamic>>();
}
