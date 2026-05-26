import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../maintenance_service.dart';
import '../models/service_record.dart';
import 'maintenance_detail_screen.dart';

/// Accent used across the maintenance feature (ops-blue).
const ModuleAccent kMaintAccent = ModuleAccent.ops;

/// Maps a (derived) service status to its display colour.
Color maintenanceStatusColor(String status) {
  switch (status) {
    case 'completed': return kSuccess;
    case 'scheduled': return const Color(0xFF60A5FA);
    case 'due_soon':  return kWarning;
    case 'overdue':   return kDanger;
    default:          return kMuted;
  }
}

/// Formats a service cost with its currency code (records may be TZS/USD).
String formatServiceCost(double amount, String currency) {
  final whole = amount.round();
  final s = whole.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$currency ${whole < 0 ? '-' : ''}$buf';
}

/// Module #5 — Maintenance. A searchable list of vehicle service records with
/// tap-through to a read-only detail screen.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  late final MaintenanceService _service;
  late Future<List<ServiceRecord>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _service = MaintenanceService(widget.apiClient);
    _future = _service.fetchRecords();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchRecords());

  List<ServiceRecord> _filter(List<ServiceRecord> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((r) {
      return r.serviceType.toLowerCase().contains(q) ||
          (r.vehiclePlate ?? '').toLowerCase().contains(q) ||
          (r.workshopName ?? '').toLowerCase().contains(q) ||
          (r.vehicleDescription ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Servicing',
            title: 'Maintenance',
            subtitle: 'Vehicle service records',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildSearchBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search plate, service type, workshop…',
          hintStyle: AppType.body(13, color: kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: kMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceVariant(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kMaintAccent.base, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<ServiceRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _reload);
        }
        final records = _filter(snapshot.data ?? []);
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _reload(),
          child: records.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: AppEmpty(
                        icon: Icons.build_circle_outlined,
                        message: _query.isEmpty
                            ? 'No service records\nMaintenance records will appear here.'
                            : 'No matches\nTry a different search term.',
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: records.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecordCard(
                        record: records[i],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaintenanceDetailScreen(
                                recordId: records[i].id,
                                service: _service,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 128, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final ServiceRecord record;
  final VoidCallback onTap;
  const _RecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = maintenanceStatusColor(record.status);
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.vehiclePlate ?? 'Unknown vehicle',
                  style: AppType.display(15, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: record.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            record.serviceType,
            style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (record.vehicleDescription != null) ...[
            const SizedBox(height: 2),
            Text(record.vehicleDescription!, style: AppType.body(11, color: kMuted)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 14, color: kMuted),
              const SizedBox(width: 4),
              Text(
                formatServiceCost(record.cost, record.currency),
                style: AppType.number(14, color: AppColors.textPrimary(context)),
              ),
              const Spacer(),
              const Icon(Icons.event_outlined, size: 12, color: kMuted),
              const SizedBox(width: 4),
              Text(formatDate(record.serviceDate), style: AppType.body(11, color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
