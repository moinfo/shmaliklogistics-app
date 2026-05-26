import 'permissions.dart';

/// In-memory holder for the authenticated user's identity and permissions.
///
/// Populated by [AuthService.login] after sign-in, and rehydrated from
/// [AuthStorage] on cold start by the splash screen. Feature screens gate UI
/// with `AppSession.instance.can('module.action')`.
class AppSession {
  static final AppSession instance = AppSession._();
  AppSession._();

  /// 'staff' | 'driver' | 'customer'
  String accountType = 'driver';
  List<String> permissions = const [];
  String name = '';

  /// The signed-in user's email (empty if unknown).
  String email = '';

  /// The role slug (e.g. 'admin', 'finance_officer', 'customer'); empty if unknown.
  String role = '';

  /// True if the current role grants [permission] (supports `*` and `module.*`).
  bool can(String permission) => checkPermission(permissions, permission);

  /// True if ANY of [list] is granted.
  bool canAny(List<String> list) => list.any(can);

  void set({
    required String accountType,
    required List<String> permissions,
    required String name,
    String email = '',
    String role = '',
  }) {
    this.accountType = accountType;
    this.permissions = permissions;
    this.name = name;
    this.email = email;
    this.role = role;
  }

  void clear() {
    accountType = 'driver';
    permissions = const [];
    name = '';
    email = '';
    role = '';
  }
}
