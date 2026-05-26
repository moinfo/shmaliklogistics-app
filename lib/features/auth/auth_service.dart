import '../../core/api/api_client.dart';
import '../../core/auth/app_session.dart';
import '../../core/models/driver.dart';
import '../../core/services/auth_storage.dart';

class LoginResult {
  final String token;
  final String accountType; // 'staff' | 'driver' | 'customer'
  final Driver? driver;     // present only for drivers

  LoginResult({required this.token, required this.accountType, this.driver});
}

class AuthService {
  final ApiClient _api;
  final AuthStorage _storage;

  AuthService({required ApiClient api, required AuthStorage storage})
      : _api = api,
        _storage = storage;

  /// Exposes secure storage for the login screen's biometric flow.
  AuthStorage get storage => _storage;

  Future<LoginResult> login(String login, String password) async {
    final data = await _api.post(
      '/auth/login',
      {'login': login, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;

    final token = data['token'] as String;
    final accountType = data['account_type'] as String? ?? 'driver';

    final user = data['user'] as Map<String, dynamic>?;
    final permissions = ((user?['permissions'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final name = (user?['name'] as String?) ??
        (data['client']?['name'] as String?) ??
        (data['driver']?['name'] as String?) ??
        '';
    final email = (user?['email'] as String?) ??
        (data['client']?['email'] as String?) ??
        '';
    final role = (user?['role'] as String?) ?? accountType;

    await _storage.saveSession(
      token: token,
      accountType: accountType,
      permissions: permissions,
      name: name,
      email: email,
      role: role,
    );
    AppSession.instance.set(
      accountType: accountType,
      permissions: permissions,
      name: name,
      email: email,
      role: role,
    );

    final driver = data['driver'] != null
        ? Driver.fromJson(data['driver'] as Map<String, dynamic>)
        : null;

    return LoginResult(token: token, accountType: accountType, driver: driver);
  }

  Future<void> logout() async {
    AppSession.instance.clear();
    await _storage.clearToken();
  }
}
