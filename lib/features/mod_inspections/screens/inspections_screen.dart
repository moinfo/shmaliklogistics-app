import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../inspections_service.dart';
import '../models/inspection.dart';
import 'inspection_detail_screen.dart';

/// Maps an inspection overall status to its display colour (mirrors the web
/// `VehicleInspection::$statuses` palette). Falls back to a hex string from the
/// API when present.
Color inspectionStatusColor(Inspection i) {
  final hex = i.overallStatusColor;
  if (hex != null && hex.isNotEmpty) return _hex(hex);
  switch (i.overallStatus) {
    case 'ok':
      return kSuccess;
    case 'minor_issues':
      return kWarning;
    case 'critical':
      return kDanger;
    default:
      return kMuted;
  }
}

/// Maps an inspection type to its accent colour.
Color inspectionTypeColor(Inspection i) {
  final hex = i.typeColor;
  if (hex != null && hex.isNotEmpty) return _hex(hex);
  switch (i.type) {
    case 'pre_trip':
      return const Color(0xFF3B82F6);
    case 'periodic':
      return const Color(0xFFEA580C);
    case 'post_trip':
      return const Color(0xFF64748B);
    default:
      return kMuted;
  }
}

Color _hex(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF64748B);
}

/// Module #9 — Vehicle Inspections. A polished, searchable list of safety
/// inspections with status filtering and tap-through to a grouped checklist
/// detail. Read-only.
class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  late final InspectionsService _service;
  late Future<List<Inspection>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all'; // all | ok | minor_issues | critical

  static const _accent = ModuleAccent.ops;

  @override
  void initState() {
    super.initState();
    _service = InspectionsService(widget.apiClient);
    _future = _service.fetchInspections();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchInspections());

  List<Inspection> _filter(List<Inspection> all) {
    return all.where((i) {
      if (_statusFilter != 'all' && i.overallStatus != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return (i.vehiclePlate ?? '').toLowerCase().contains(q) ||
          (i.inspectorName ?? '').toLowerCase().contains(q) ||
          i.typeLabel.toLowerCase().contains(q) ||
          i.vehicleDescription.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Safety',
            title: 'Inspections',
            subtitle: 'Vehicle safety checks',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<Inspection>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(message: snapshot.error.toString(), onRetry: _reload);
                }
                final all = snapshot.data ?? [];
                final filtered = _filter(all);
                return Column(
                  children: [
                    _buildControls(all),
                    Expanded(
                      child: RefreshIndicator(
                        color: kPrimary,
                        onRefresh: () async => _reload(),
                        child: filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: AppEmpty(
                                      icon: Icons.fact_check_outlined,
                                      message: all.isEmpty
                                          ? 'No inspections yet.\nCompleted checks will appear here.'
                                          : 'No inspections match your filters.',
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => RevealOnLoad(
                                  delayMs: (i * 60).clamp(0, 300),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _InspectionCard(
                                      inspection: filtered[i],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InspectionDetailScreen(
                                            inspectionId: filtered[i].id,
                                            service: _service,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(List<Inspection> all) {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: AppType.body(14, color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: 'Search plate, inspector, type…',
              hintStyle: AppType.body(13.5, color: kMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceVariant(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('all', 'All', all.length),
                _chip('ok', 'All Good', all.where((i) => i.overallStatus == 'ok').length),
                _chip('minor_issues', 'Minor', all.where((i) => i.overallStatus == 'minor_issues').length),
                _chip('critical', 'Critical', all.where((i) => i.overallStatus == 'critical').length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, int count) {
    final selected = _statusFilter == value;
    final color = value == 'critical'
        ? kDanger
        : value == 'minor_issues'
            ? kWarning
            : value == 'ok'
                ? kSuccess
                : _accent.base;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : AppColors.surfaceVariant(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : AppColors.border(context),
            ),
          ),
          child: Text(
            '$label  $count',
            style: AppType.body(12.5,
                weight: FontWeight.w700, color: selected ? color : kMuted),
          ),
        ),
      ),
    );
  }

  Widget _skeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 116, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final Inspection inspection;
  final VoidCallback onTap;
  const _InspectionCard({required this.inspection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = inspectionStatusColor(inspection);
    final typeColor = inspectionTypeColor(inspection);
    return AppCard(
      accentColor: statusColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inspection.vehiclePlate ?? 'Unknown vehicle',
                  style: AppType.display(16, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusPill(label: inspection.overallStatusLabel, color: statusColor),
            ],
          ),
          if (inspection.vehicleDescription.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(inspection.vehicleDescription,
                style: AppType.body(12.5, color: kMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              StatusPill(label: inspection.typeLabel, color: typeColor),
              const Spacer(),
              if (inspection.inspectedAt != null) ...[
                const Icon(Icons.event_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(formatDate(inspection.inspectedAt),
                    style: AppType.body(11.5, color: kMuted)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(inspection.inspectorName ?? 'Unknown inspector',
                    style: AppType.body(12, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('View',
                  style: AppType.body(11,
                      color: ModuleAccent.ops.base, weight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, size: 14, color: ModuleAccent.ops.base),
            ],
          ),
        ],
      ),
    );
  }
}
