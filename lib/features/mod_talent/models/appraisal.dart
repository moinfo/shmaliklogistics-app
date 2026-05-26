import 'vacancy.dart';

/// A staff performance appraisal, as returned by
/// `GET /staff/modules/appraisals`.
///
/// Mirrors the flattened `Appraisal` shape from
/// `Api\Staff\Modules\TalentController` (`employee_name`, metric ratings,
/// computed `overall_score`, flattened status).
class Appraisal {
  final int id;
  final int? employeeId;
  final String employeeName;
  final String? employeeNumber;
  final String? department;
  final String? position;
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final int? tripsCount;
  final double? onTimePct;
  final double? fuelEffKml;
  final int? incidents;
  final int? ratingPunctuality;
  final int? ratingConduct;
  final int? ratingCargoCare;
  final int? ratingCompliance;
  final int? managerRating;
  final String? managerNotes;
  final double? overallScore;
  final String status;
  final String statusLabel;
  final int statusColorValue;
  final String? createdBy;
  final DateTime? createdAt;

  const Appraisal({
    required this.id,
    this.employeeId,
    required this.employeeName,
    this.employeeNumber,
    this.department,
    this.position,
    this.periodFrom,
    this.periodTo,
    this.tripsCount,
    this.onTimePct,
    this.fuelEffKml,
    this.incidents,
    this.ratingPunctuality,
    this.ratingConduct,
    this.ratingCargoCare,
    this.ratingCompliance,
    this.managerRating,
    this.managerNotes,
    this.overallScore,
    required this.status,
    required this.statusLabel,
    required this.statusColorValue,
    this.createdBy,
    this.createdAt,
  });

  factory Appraisal.fromJson(Map<String, dynamic> j) => Appraisal(
        id: j['id'] as int? ?? 0,
        employeeId: j['employee_id'] as int?,
        employeeName: j['employee_name'] as String? ?? 'Unknown',
        employeeNumber: j['employee_number'] as String?,
        department: j['department'] as String?,
        position: j['position'] as String?,
        periodFrom: _date(j['period_from']),
        periodTo: _date(j['period_to']),
        tripsCount: j['trips_count'] as int?,
        onTimePct: _num(j['on_time_pct']),
        fuelEffKml: _num(j['fuel_eff_kml']),
        incidents: j['incidents'] as int?,
        ratingPunctuality: j['rating_punctuality'] as int?,
        ratingConduct: j['rating_conduct'] as int?,
        ratingCargoCare: j['rating_cargo_care'] as int?,
        ratingCompliance: j['rating_compliance'] as int?,
        managerRating: j['manager_rating'] as int?,
        managerNotes: j['manager_notes'] as String?,
        overallScore: _num(j['overall_score']),
        status: j['status'] as String? ?? 'draft',
        statusLabel: j['status_label'] as String? ??
            (j['status'] as String? ?? 'Draft'),
        statusColorValue: hexToArgb(j['status_color'] as String?),
        createdBy: j['created_by'] as String?,
        createdAt: _date(j['created_at']),
      );

  /// Period as `dd MMM – dd MMM yyyy` style is left to the screen; this is the
  /// raw range presence check.
  bool get hasPeriod => periodFrom != null && periodTo != null;

  static double? _num(dynamic v) =>
      v != null ? double.tryParse(v.toString()) : null;

  static DateTime? _date(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;
}
