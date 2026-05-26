import '../../core/api/api_client.dart';
import 'models/property.dart';

/// One enum option as the API serves it: `{ key: { label, color } }`.
class EnumOption {
  final String key;
  final String label;
  final String? colorHex;
  const EnumOption({required this.key, required this.label, this.colorHex});
}

/// Headline numbers for the Properties list (`stats` sibling key).
class PropertiesStats {
  final int total;
  final int occupied;
  final int underRenovation;
  final double monthlyRoll;

  const PropertiesStats({
    this.total = 0,
    this.occupied = 0,
    this.underRenovation = 0,
    this.monthlyRoll = 0,
  });

  factory PropertiesStats.fromJson(Map<String, dynamic>? j) {
    final m = j ?? const <String, dynamic>{};
    return PropertiesStats(
      total: (m['total'] as num?)?.toInt() ?? 0,
      occupied: (m['occupied'] as num?)?.toInt() ?? 0,
      underRenovation: (m['under_renovation'] as num?)?.toInt() ?? 0,
      monthlyRoll: double.tryParse((m['monthly_roll'] ?? 0).toString()) ?? 0,
    );
  }
}

/// Everything the Properties list screen needs in one shot: the rows, the
/// headline [stats], and the [types]/[statuses] enum maps used for filter chips.
class PropertiesPayload {
  final List<PropertyRow> properties;
  final PropertiesStats stats;
  final List<EnumOption> types;
  final List<EnumOption> statuses;

  const PropertiesPayload({
    required this.properties,
    required this.stats,
    required this.types,
    required this.statuses,
  });
}

/// Talks to the `/staff/modules/real-estate/properties` endpoints
/// (RealEstateController — the "Properties" portfolio module). Read-only.
class ModRePropertiesService {
  ModRePropertiesService(this._api);
  final ApiClient _api;

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `mod_vehicles` / `mod_drivers` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  /// Parses an enum map (`{ key: { label, color } }`) into a list of
  /// [EnumOption]s, preserving the backend's iteration order.
  List<EnumOption> _enumOptions(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const [];
    return raw.entries.map((e) {
      final v = e.value;
      if (v is Map<String, dynamic>) {
        return EnumOption(
          key: e.key,
          label: (v['label'] ?? e.key).toString(),
          colorHex: v['color']?.toString(),
        );
      }
      return EnumOption(key: e.key, label: v.toString());
    }).toList();
  }

  Future<PropertiesPayload> fetchProperties({
    String? search,
    String? status,
    String? type,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (type != null && type.isNotEmpty) params['type'] = type;

    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

    final json = await _api.get('/staff/modules/real-estate/properties$query')
        as Map<String, dynamic>;

    return PropertiesPayload(
      properties: _unwrapList(json['properties'])
          .map((e) => PropertyRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: PropertiesStats.fromJson(json['stats'] as Map<String, dynamic>?),
      types: _enumOptions(json['types']),
      statuses: _enumOptions(json['statuses']),
    );
  }

  Future<PropertyDetail> fetchProperty(int id) async {
    final json = await _api.get('/staff/modules/real-estate/properties/$id')
        as Map<String, dynamic>;
    return PropertyDetail.fromJson(
      property: json['property'] as Map<String, dynamic>,
      units: _unwrapList(json['units']),
      expenses: _unwrapList(json['expenses']),
      financials: json['financials'] as Map<String, dynamic>?,
    );
  }
}