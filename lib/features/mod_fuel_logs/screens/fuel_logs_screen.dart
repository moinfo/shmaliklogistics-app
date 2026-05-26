import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../fuel_log_service.dart';
import '../models/fuel_log.dart';

/// Fuel Logs — fleet-wide fuel consumption ledger for staff.
///
/// Read-only: searchable + fuel-type-filterable list of fuel entries with
/// litres, cost and odometer, plus summary totals.
class FuelLogsScreen extends StatefulWidget {
  const FuelLogsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<FuelLogsScreen> createState() => _FuelLogsScreenState();
}

class _FuelLogsScreenState extends State<FuelLogsScreen> {
  late final FuelLogService _service;

  List<FuelLog>? _logs;
  FuelStats? _stats;
  bool _loading = true;
  String? _error;

  String _search = '';
  String _typeFilter = 'all';

  static const _typeFilters = [
    ('all', 'All'),
    ('diesel', 'Diesel'),
    ('petrol', 'Petrol'),
    ('cng', 'CNG'),
  ];

  static const _accent = ModuleAccent.ops;

  @override
  void initState() {
    super.initState();
    _service = FuelLogService(widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle = await _service.fetchFuelLogs();
      if (mounted) {
        setState(() {
          _logs = bundle.logs;
          _stats = bundle.stats;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load fuel logs.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<FuelLog> get _filtered {
    final all = _logs ?? [];
    final q = _search.trim().toLowerCase();
    return all.where((l) {
      if (_typeFilter != 'all' && l.fuelType != _typeFilter) return false;
      if (q.isEmpty) return true;
      return (l.vehiclePlate ?? '').toLowerCase().contains(q) ||
          (l.station ?? '').toLowerCase().contains(q) ||
          (l.driverName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Fuel',
            title: 'Fuel Logs',
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _load,
                tooltip: 'Refresh',
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _wrapScroll(AppError(message: _error!, onRetry: _load));

    final logs = _filtered;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          if (_stats != null) ...[
            RevealOnLoad(child: _buildStats(_stats!)),
            const SizedBox(height: 20),
          ],
          _buildSearch(),
          const SizedBox(height: 12),
          _buildTypeChips(),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.32,
              child: AppEmpty(
                icon: Icons.local_gas_station_outlined,
                message: _search.isNotEmpty || _typeFilter != 'all'
                    ? 'No fuel logs match your filters.'
                    : 'No fuel logs yet. Recorded fill-ups will appear here.',
              ),
            )
          else
            for (var i = 0; i < logs.length; i++)
              RevealOnLoad(
                delayMs: (i * 60).clamp(0, 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FuelLogCard(log: logs[i]),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildStats(FuelStats stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Total litres',
            value: '${_compactLitres(stats.totalLiters)} L',
            icon: Icons.local_gas_station_rounded,
            accent: _accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Total fuel cost',
            value: formatCurrency(stats.totalCost),
            icon: Icons.payments_rounded,
            accent: ModuleAccent.finance,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (v) => setState(() => _search = v),
      style: AppType.body(14, color: AppColors.textPrimary(context)),
      decoration: InputDecoration(
        hintText: 'Search vehicle, station or driver',
        hintStyle: AppType.body(13.5, color: kMuted),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _typeFilters.map((f) {
          final (value, label) = f;
          final selected = _typeFilter == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _typeFilter = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? _accent.base : AppColors.chipUnselected(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _accent.base : AppColors.border(context),
                  ),
                ),
                child: Text(
                  label,
                  style: AppType.body(12,
                      weight: FontWeight.w600,
                      color: selected ? Colors.white : kMuted),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _wrapScroll(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: child,
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              Expanded(child: AppSkeleton.box(context, height: 110, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(context, height: 110, radius: 20)),
            ],
          ),
          const SizedBox(height: 20),
          AppSkeleton.box(context, height: 52, radius: 16),
          const SizedBox(height: 16),
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSkeleton.box(context, height: 116, radius: 18),
            ),
        ],
      ),
    );
  }
}

/// Compact whole/short number formatter for litre stat tiles.
String _compactLitres(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }
  return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
}

// ── Fuel log card ────────────────────────────────────────────────────────────

class _FuelLogCard extends StatelessWidget {
  final FuelLog log;
  const _FuelLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    const accent = ModuleAccent.ops;

    return AppCard(
      accentColor: accent.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.base.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_gas_station_rounded, size: 18, color: accent.base),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.vehiclePlate ?? 'Unknown vehicle',
                      style: AppType.number(14, color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (log.vehicleDescription.isNotEmpty)
                      Text(
                        log.vehicleDescription,
                        style: AppType.body(11, color: kMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (log.fuelType != null)
                StatusPill(label: log.fuelTypeLabel, color: accent.base),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(
                label: 'Litres',
                value: '${log.liters.toStringAsFixed(log.liters.truncateToDouble() == log.liters ? 0 : 1)} L',
              ),
              const SizedBox(width: 18),
              _Metric(
                label: 'Cost',
                value: formatCurrency(log.totalCost),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: kMuted),
              const SizedBox(width: 4),
              Text(formatDate(log.logDate), style: AppType.body(11, color: kMuted)),
              if (log.odometerKm != null) ...[
                const SizedBox(width: 14),
                const Icon(Icons.speed_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text('${log.odometerKm} km',
                    style: AppType.number(11, weight: FontWeight.w700, color: kMuted)),
              ],
            ],
          ),
          if (log.station != null && log.station!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(log.station!,
                      style: AppType.body(11, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppType.eyebrow(size: 9, color: kMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppType.number(15, color: AppColors.textNavy(context))),
      ],
    );
  }
}
