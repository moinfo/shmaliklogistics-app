/// A recruitment job vacancy, as returned by
/// `GET /staff/modules/recruitment` and `/recruitment/{id}`.
///
/// Mirrors the payload shaped by `Api\Staff\Modules\TalentController`
/// (flattens the `JobVacancy` model + application counts; on detail it also
/// includes `applications`, the stage `pipeline`, and the long-form
/// description/requirements).
class PipelineStage {
  final String stage;
  final String label;
  final int colorValue;
  final int count;

  const PipelineStage({
    required this.stage,
    required this.label,
    required this.colorValue,
    required this.count,
  });

  factory PipelineStage.fromJson(Map<String, dynamic> j) => PipelineStage(
        stage: j['stage'] as String? ?? '',
        label: j['label'] as String? ?? '',
        colorValue: hexToArgb(j['color'] as String?),
        count: j['count'] as int? ?? 0,
      );
}

class Vacancy {
  final int id;
  final String title;
  final String? department;
  final int? openings;
  final String status;
  final String statusLabel;
  final int statusColorValue;
  final DateTime? closingDate;
  final int applicationsCount;

  // Detail-only fields.
  final String? description;
  final String? requirements;
  final String? createdBy;
  final DateTime? createdAt;
  final List<PipelineStage> pipeline;

  const Vacancy({
    required this.id,
    required this.title,
    this.department,
    this.openings,
    required this.status,
    required this.statusLabel,
    required this.statusColorValue,
    this.closingDate,
    required this.applicationsCount,
    this.description,
    this.requirements,
    this.createdBy,
    this.createdAt,
    this.pipeline = const [],
  });

  factory Vacancy.fromJson(Map<String, dynamic> j) {
    final rawPipeline = j['pipeline'] as List? ?? [];
    return Vacancy(
      id: j['id'] as int? ?? 0,
      title: j['title'] as String? ?? '—',
      department: j['department'] as String?,
      openings: j['openings'] as int?,
      status: j['status'] as String? ?? 'open',
      statusLabel:
          j['status_label'] as String? ?? (j['status'] as String? ?? 'Open'),
      statusColorValue: hexToArgb(j['status_color'] as String?),
      closingDate: _date(j['closing_date']),
      applicationsCount: j['applications_count'] as int? ?? 0,
      description: j['description'] as String?,
      requirements: j['requirements'] as String?,
      createdBy: j['created_by'] as String?,
      createdAt: _date(j['created_at']),
      pipeline: rawPipeline
          .map((e) => PipelineStage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime? _date(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;
}

/// Parses a `#RRGGBB` hex string into an opaque ARGB int. Falls back to the
/// neutral slate the backend uses for unmapped statuses/stages.
int hexToArgb(String? hex) {
  if (hex == null || hex.isEmpty) return 0xFF94A3B8;
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return 0xFF94A3B8;
  return cleaned.length <= 6 ? 0xFF000000 | value : value;
}
