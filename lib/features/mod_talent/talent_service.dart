import '../../core/api/api_client.dart';
import 'models/appraisal.dart';
import 'models/job_application.dart';
import 'models/vacancy.dart';

/// Talks to the staff Talent module endpoints (Recruitment + Appraisals).
///
/// Mirrors the structure of the other module services (see
/// `features/mod_purchase_orders/purchase_orders_service.dart`): unwraps both
/// the plain list shape `{ "vacancies": [...] }` and the paginated
/// `{ "vacancies": { "data": [...] } }`.
class TalentService {
  final ApiClient _api;
  TalentService(this._api);

  static const String _base = '/staff/modules';

  /// All job vacancies, newest first — `GET /staff/modules/recruitment`.
  Future<List<Vacancy>> fetchVacancies() async {
    final json = await _api.get('$_base/recruitment') as Map<String, dynamic>;
    final raw = json['vacancies'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data
        .map((e) => Vacancy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A single vacancy plus its applications —
  /// `GET /staff/modules/recruitment/{id}`.
  Future<VacancyDetail> fetchVacancy(int id) async {
    final json =
        await _api.get('$_base/recruitment/$id') as Map<String, dynamic>;
    final vacancy = Vacancy.fromJson(json['vacancy'] as Map<String, dynamic>);
    final rawApps = json['applications'];
    final appData = (rawApps is Map ? rawApps['data'] : rawApps) as List? ?? [];
    final applications = appData
        .map((e) => JobApplication.fromJson(e as Map<String, dynamic>))
        .toList();
    return VacancyDetail(vacancy: vacancy, applications: applications);
  }

  /// All staff appraisals, newest first — `GET /staff/modules/appraisals`.
  Future<List<Appraisal>> fetchAppraisals() async {
    final json = await _api.get('$_base/appraisals') as Map<String, dynamic>;
    final raw = json['appraisals'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data
        .map((e) => Appraisal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Bundle returned by [TalentService.fetchVacancy]: the vacancy and its
/// applications, since the detail endpoint returns them as siblings.
class VacancyDetail {
  final Vacancy vacancy;
  final List<JobApplication> applications;
  const VacancyDetail({required this.vacancy, required this.applications});
}
