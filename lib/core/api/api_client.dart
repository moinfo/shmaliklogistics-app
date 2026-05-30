import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/auth_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static const String _liveUrl  = 'https://transmaslogistics.co.tz/api';
  static const String _localUrl = 'http://127.0.0.1:8000/api';

  // Release builds → live server. Debug/profile → local server.
  static String get baseUrl => kReleaseMode ? _liveUrl : _localUrl;

  // Base URL without /api — used to construct storage file URLs.
  static String get storageUrl => baseUrl.replaceAll('/api', '');

  final AuthStorage _storage;
  ApiClient(this._storage);

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await _storage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> postMultipart(String path, Map<String, String> fields, {String? filePath, String? fileField, String? mimeType}) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers());
    req.headers.remove('Content-Type'); // multipart sets its own
    fields.forEach((k, v) => req.fields[k] = v);
    if (filePath != null && fileField != null) {
      req.files.add(await http.MultipartFile.fromPath(fileField, filePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null));
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body['message'] ?? 'Something went wrong';
    throw ApiException(res.statusCode, msg);
  }
}