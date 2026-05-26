import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _accountTypeKey = 'account_type';
  static const _permissionsKey = 'permissions';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _roleKey = 'user_role';
  // Biometric login credentials — kept separate from the session so they
  // survive logout (the whole point of "sign in again with Face ID").
  static const _bioLoginKey = 'biometric_login';
  static const _bioPasswordKey = 'biometric_password';
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<bool> hasToken() async => (await getToken()) != null;

  /// Persists the full session so it can be rehydrated on cold start.
  Future<void> saveSession({
    required String token,
    required String accountType,
    required List<String> permissions,
    required String name,
    String email = '',
    String role = '',
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _accountTypeKey, value: accountType);
    await _storage.write(key: _permissionsKey, value: jsonEncode(permissions));
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String> getAccountType() async =>
      (await _storage.read(key: _accountTypeKey)) ?? 'driver';

  Future<List<String>> getPermissions() async {
    final raw = await _storage.read(key: _permissionsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded.map((e) => e.toString()).toList() : const [];
  }

  Future<String> getName() async => (await _storage.read(key: _nameKey)) ?? '';

  Future<String> getEmail() async => (await _storage.read(key: _emailKey)) ?? '';

  Future<String> getRole() async => (await _storage.read(key: _roleKey)) ?? '';

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _accountTypeKey);
    await _storage.delete(key: _permissionsKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _roleKey);
    // NB: biometric credentials are intentionally NOT cleared here — they let
    // the user sign back in with Face ID/fingerprint after logging out.
  }

  // ── Biometric login credentials ────────────────────────────────────────────

  /// Stores the credentials used to re-authenticate after a biometric scan.
  Future<void> saveBiometricCredentials(String login, String password) async {
    await _storage.write(key: _bioLoginKey, value: login);
    await _storage.write(key: _bioPasswordKey, value: password);
  }

  /// Returns the saved biometric credentials, or null if none are enrolled.
  Future<({String login, String password})?> getBiometricCredentials() async {
    final login = await _storage.read(key: _bioLoginKey);
    final password = await _storage.read(key: _bioPasswordKey);
    if (login == null || password == null) return null;
    return (login: login, password: password);
  }

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _bioLoginKey)) != null;

  Future<void> clearBiometricCredentials() async {
    await _storage.delete(key: _bioLoginKey);
    await _storage.delete(key: _bioPasswordKey);
  }
}
