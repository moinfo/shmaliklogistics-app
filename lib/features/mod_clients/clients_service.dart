import '../../core/api/api_client.dart';
import 'models/client.dart';

/// Talks to the `/staff/modules/clients` endpoints (Module 3 — ClientController).
class ClientsService {
  final ApiClient _api;
  ClientsService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `mod_drivers_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Client>> fetchClients() async {
    final json = await _api.get('/staff/modules/clients') as Map<String, dynamic>;
    return _unwrapList(json['clients'])
        .map((e) => Client.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Client> fetchClient(int id) async {
    final json = await _api.get('/staff/modules/clients/$id') as Map<String, dynamic>;
    return Client.fromJson(json['client'] as Map<String, dynamic>);
  }
}
