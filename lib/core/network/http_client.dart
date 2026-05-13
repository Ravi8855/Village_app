import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/failures.dart';

class HttpClient {
  HttpClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  http.Client get client => _client;

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    try {
      final response = await _client.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        throw const ServerFailure('Invalid JSON shape');
      }
      throw ServerFailure('HTTP ${response.statusCode}');
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure('Could not reach the server.');
    }
  }

  void close() => _client.close();
}
