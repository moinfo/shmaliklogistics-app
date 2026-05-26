import 'vacancy.dart';

/// A candidate's application against a job vacancy, as returned in the
/// `applications` array of `GET /staff/modules/recruitment/{id}`.
///
/// Mirrors the flattened `JobApplication` shape from
/// `Api\Staff\Modules\TalentController` (`applicant_name`, flattened stage).
class JobApplication {
  final int id;
  final int vacancyId;
  final String applicantName;
  final String? phone;
  final String? email;
  final String stage;
  final String stageLabel;
  final int stageColorValue;
  final DateTime? interviewDate;
  final String? interviewNotes;
  final double? offerAmount;
  final String? notes;
  final bool hasCv;
  final DateTime? appliedAt;

  const JobApplication({
    required this.id,
    required this.vacancyId,
    required this.applicantName,
    this.phone,
    this.email,
    required this.stage,
    required this.stageLabel,
    required this.stageColorValue,
    this.interviewDate,
    this.interviewNotes,
    this.offerAmount,
    this.notes,
    required this.hasCv,
    this.appliedAt,
  });

  factory JobApplication.fromJson(Map<String, dynamic> j) => JobApplication(
        id: j['id'] as int? ?? 0,
        vacancyId: j['vacancy_id'] as int? ?? 0,
        applicantName: j['applicant_name'] as String? ?? 'Unknown',
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        stage: j['stage'] as String? ?? 'applied',
        stageLabel:
            j['stage_label'] as String? ?? (j['stage'] as String? ?? 'Applied'),
        stageColorValue: hexToArgb(j['stage_color'] as String?),
        interviewDate: _date(j['interview_date']),
        interviewNotes: j['interview_notes'] as String?,
        offerAmount: j['offer_amount'] != null
            ? double.tryParse(j['offer_amount'].toString())
            : null,
        notes: j['notes'] as String?,
        hasCv: j['has_cv'] as bool? ?? false,
        appliedAt: _date(j['applied_at']),
      );

  static DateTime? _date(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;
}
