import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  static const String _liveUrl = 'https://transmaslogistics.co.tz/api';

  static const String _localUrl = 'http://192.168.0.193:8000/api';

  // TEMPORARY: the new staff endpoints (Allowances, Notifications, Settings) are
  // not deployed to the live server yet, so every build talks to the local
  // backend. Set to false once the backend is deployed to go back to live.
  static const bool _useLocal = true;

  // Optional override, e.g. `flutter run --dart-define=API_BASE_URL=https://transmaslogistics.co.tz/api`
  static const String _overrideUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl =>
      _overrideUrl.isNotEmpty ? _overrideUrl : (_useLocal ? _localUrl : _liveUrl);

  static const Duration _timeout = Duration(seconds: 30);

  // Base URL without /api — used to construct storage file URLs.
  static String get storageUrl => baseUrl.replaceAll('/api', '');

  final AuthStorage _storage;
  ApiClient(this._storage);

  /// Called when the server rejects the saved login token (HTTP 401) on an
  /// authenticated request, after the stored session has been cleared. The app
  /// uses it to send the user back to the login screen.
  static void Function()? onUnauthorized;

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await _storage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Reads are idempotent, so a transient network failure (no connection,
  /// timeout, dropped socket — statusCode 0) is retried up to twice with a short
  /// backoff before the error is shown. Writes are never retried automatically.
  Future<dynamic> get(String path) async {
    final headers = await _headers();
    for (var attempt = 0;; attempt++) {
      try {
        return await _guard(() => http.get(Uri.parse('$baseUrl$path'), headers: headers));
      } on ApiException catch (e) {
        if (e.statusCode != 0 || attempt >= 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
      }
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return _guard(() => http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body)), auth: auth);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    return _guard(() => http.patch(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body)));
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
    return _guard(() async => http.Response.fromStream(await req.send()));
  }

  /// Runs [send] with a timeout and turns network failures into readable
  /// [ApiException]s (statusCode 0) instead of raw socket errors.
  Future<dynamic> _guard(Future<http.Response> Function() send, {bool auth = true}) async {
    try {
      return _handle(await send().timeout(_timeout));
    } on ApiException catch (e) {
      if (e.statusCode == 401 && auth) {
        // The saved token is no longer valid (expired, revoked, or issued by a
        // different server) — drop it and send the user back to sign in.
        await _storage.clearToken();
        onUnauthorized?.call();
        throw ApiException(401, 'Your session has expired. Please sign in again.');
      }
      rethrow;
    } on TimeoutException {
      throw ApiException(0, 'The server took too long to respond. Please try again.');
    } on SocketException {
      throw ApiException(0, 'No internet connection. Check your network and try again.');
    } on http.ClientException {
      throw ApiException(0, 'Could not reach the server. Check your connection and try again.');
    }
  }

  dynamic _handle(http.Response res) {
    dynamic body;
    try {
      body = res.body.isEmpty ? null : jsonDecode(res.body);
    } on FormatException {
      body = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = (body is Map ? body['message'] : null) as String? ??
        (res.statusCode >= 500 ? 'Server error. Please try again later.' : 'Something went wrong');
    throw ApiException(res.statusCode, msg);
  }
}
