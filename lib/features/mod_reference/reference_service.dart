import '../../core/api/api_client.dart';

/// One label/value line shown on a reference row.
class RefField {
  final String label;
  final String value;
  const RefField(this.label, this.value);

  factory RefField.fromJson(Map<String, dynamic> j) =>
      RefField(j['label']?.toString() ?? '', j['value']?.toString() ?? '');
}

/// A single row of a generic read-only list (allowance, department, alert…).
class RefItem {
  final int id;
  final String title;
  final String? subtitle;
  final String? badge;
  final String? badgeTone; // success | warning | danger | info | muted
  final List<RefField> fields;

  const RefItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.badge,
    this.badgeTone,
    this.fields = const [],
  });

  factory RefItem.fromJson(Map<String, dynamic> j) => RefItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '—',
        subtitle: j['subtitle']?.toString(),
        badge: j['badge']?.toString(),
        badgeTone: j['badge_tone']?.toString(),
        fields: ((j['fields'] as List?) ?? const [])
            .map((e) => RefField.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Envelope returned by `ReferenceController` on the backend.
class RefList {
  final String title;
  final List<RefField> summary;
  final List<RefItem> items;

  const RefList({required this.title, required this.summary, required this.items});

  factory RefList.fromJson(Map<String, dynamic> j) => RefList(
        title: j['title']?.toString() ?? '',
        summary: ((j['summary'] as List?) ?? const [])
            .map((e) => RefField.fromJson(e as Map<String, dynamic>))
            .toList(),
        items: ((j['items'] as List?) ?? const [])
            .map((e) => RefItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Reads the generic read-only lists behind HR → Allowances, Notifications and
/// the Settings screens.
class ReferenceService {
  final ApiClient _api;
  ReferenceService(this._api);

  Future<RefList> fetch(String path) async {
    final json = await _api.get(path) as Map<String, dynamic>;
    return RefList.fromJson(json);
  }
}
