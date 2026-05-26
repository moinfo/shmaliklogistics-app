/// Permission check ported EXACTLY from `web/resources/js/lib/can.js`.
///
/// Supports:
///   • `*`        — full access (grants everything)
///   • exact      — `trips.view`
///   • `module.*` — `trips.*` grants `trips.view`, `trips.edit`, etc.
bool checkPermission(List<String> permissions, String permission) {
  if (permission.isEmpty) return true;
  if (permissions.isEmpty) return false;
  if (permissions.contains('*')) return true;
  if (permissions.contains(permission)) return true;
  // module.* wildcard: "trips.*" grants "trips.view", "trips.edit", etc.
  final dot = permission.indexOf('.');
  if (dot > -1) {
    final moduleKey = permission.substring(0, dot);
    if (permissions.contains('$moduleKey.*')) return true;
  }
  return false;
}

/// True if ANY permission in [list] is granted by [permissions].
bool canAny(List<String> permissions, List<String> list) {
  return list.any((p) => checkPermission(permissions, p));
}
