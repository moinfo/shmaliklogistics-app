import '../../core/api/api_client.dart';
import 'models/lease.dart';

/// The list payload for `GET /staff/modules/real-estate/leases`: the lease
/// [rows] plus the sibling [stats], [statuses] and [billingCycles] enum maps.
class LeasesPayload {
  final List<LeaseRow> rows;

  /// Summary counters: `active`, `expiring_30d`, `expired`, `monthly_roll`.
  final Map<String, dynamic> stats;

  /// `{key: label}` status options for the filter chips.
  final Map<String, String> statuses;

  /// `{key: {label, months}}` billing cycle definitions — look up a row's
  /// `billing_cycle` key to render its human label.
  final Map<String, BillingCycle> billingCycles;

  LeasesPayload({
    required this.rows,
    required this.stats,
    required this.statuses,
    required this.billingCycles,
  });
}

/// The detail payload for `GET /staff/modules/real-estate/leases/{id}`: the
/// full [lease] plus the sibling [billingCycles] enum map.
class LeaseDetailPayload {
  final LeaseDetail lease;
  final Map<String, BillingCycle> billingCycles;

  LeaseDetailPayload({required this.lease, required this.billingCycles});
}

/// A billing cycle definition (`{label, months}`).
class BillingCycle {
  final String label;
  final int months;
  const BillingCycle({required this.label, required this.months});

  factory BillingCycle.fromJson(Map<String, dynamic> j) => BillingCycle(
        label: (j['label'] ?? '').toString(),
        months: j['months'] == null ? 0 : int.tryParse(j['months'].toString()) ?? 0,
      );
}

/// Talks to the `/staff/modules/real-estate/leases` endpoints
/// (RealEstateController — the "Leases" / tenancy module). Read-only.
class ModReLeasesService {
  ModReLeasesService(this._api);

  final ApiClient _api;

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `mod_vehicles` / `staff_finance` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  /// Parses a `{key: {label, months}}` map of billing cycle definitions.
  Map<String, BillingCycle> _billingCycles(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, BillingCycle>{};
    raw.forEach((k, v) {
      if (v is Map) {
        out[k.toString()] = BillingCycle.fromJson(Map<String, dynamic>.from(v));
      }
    });
    return out;
  }

  /// Parses a `{key: label}` map (statuses).
  Map<String, String> _labelMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((k, v) {
      // Values may be a plain label string or a `{label,...}` object.
      if (v is Map && v['label'] != null) {
        out[k.toString()] = v['label'].toString();
      } else if (v != null) {
        out[k.toString()] = v.toString();
      }
    });
    return out;
  }

  Future<LeasesPayload> fetchLeases({String? search, String? status}) async {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (status != null && status.isNotEmpty) params['status'] = status;
    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

    final json =
        await _api.get('/staff/modules/real-estate/leases$query') as Map<String, dynamic>;

    return LeasesPayload(
      rows: _unwrapList(json['leases'])
          .map((e) => LeaseRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      statuses: _labelMap(json['statuses']),
      billingCycles: _billingCycles(json['billingCycles']),
    );
  }

  Future<LeaseDetailPayload> fetchLease(int id) async {
    final json =
        await _api.get('/staff/modules/real-estate/leases/$id') as Map<String, dynamic>;
    return LeaseDetailPayload(
      lease: LeaseDetail.fromJson(json['lease'] as Map<String, dynamic>),
      billingCycles: _billingCycles(json['billingCycles']),
    );
  }

  /// Uploads (or replaces) the contract (*mkataba*) document for a lease via
  /// `POST /staff/modules/real-estate/leases/{id}/contract` (multipart).
  /// Requires the `realestate_leases.edit` permission server-side.
  ///
  /// Returns the decoded response map:
  /// `{ message, has_contract, contract_url, contract_uploaded_at }`.
  Future<Map<String, dynamic>> uploadContract({
    required int leaseId,
    required String filePath,
    String? mimeType,
  }) async {
    final json = await _api.postMultipart(
      '/staff/modules/real-estate/leases/$leaseId/contract',
      <String, String>{},
      filePath: filePath,
      fileField: 'file',
      mimeType: mimeType,
    ) as Map<String, dynamic>;
    return json;
  }
}