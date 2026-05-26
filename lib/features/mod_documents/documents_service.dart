import '../../core/api/api_client.dart';
import 'models/document.dart';

/// Talks to the staff Documents module endpoint (`/staff/modules/documents`).
///
/// Mirrors the structure of the other staff services (see
/// `features/staff_ops/staff_ops_service.dart`); unwraps both the bare-list and
/// the paginated `{ "documents": { "data": [...] } }` shapes.
class DocumentsService {
  final ApiClient _api;
  DocumentsService(this._api);

  /// Document library — `GET /staff/modules/documents`.
  ///
  /// Response: `{ "documents": { "data": [ {...}, ... ] } }`
  /// (also accepts a bare `{ "documents": [...] }` list).
  Future<List<StaffDocument>> fetchDocuments() async {
    final json = await _api.get('/staff/modules/documents') as Map<String, dynamic>;
    final raw = json['documents'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data
        .map((e) => StaffDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
