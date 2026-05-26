import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../check_in_service.dart';
import '../models/check_in.dart';

/// Trip Check-Ins — driver check-in feed for staff (read-only).
///
/// Searchable + status-filterable list of driver check-ins along active trips,
/// showing trip, status, location, odometer and time, plus activity tallies.
class CheckInsScreen extends StatefulWidget {
  const CheckInsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<CheckInsScreen> createState() => _CheckInsScreenState();
}

class _CheckInsScreenState extends State<CheckInsScreen> {
  late final CheckInService _service;

  List<CheckIn>? _checkIns;
  CheckInStats? _stats;
  bool _loading = true;
  String? _error;

  String _search = '';
  String _statusFilter = 'all';

  static const _statusFilters = [
    ('all', 'All'),
    ('ok', 'All Good'),
    ('issue', 'Issue'),
    ('emergency', 'Emergency'),
  ];

  static const _accent = ModuleAccent.ops;

  @override
  void initState() {
    super.initState();
    _service = CheckInService(widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle = await _service.fetchCheckIns();
      if (mounted) {
        setState(() {
          _checkIns = bundle.checkIns;
          _stats = bundle.stats;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load check-ins.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CheckIn> get _filtered {
    final all = _checkIns ?? [];
    final q = _search.trim().toLowerCase();
    return all.where((c) {
      if (_statusFilter != 'all' && c.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return (c.tripNumber ?? '').toLowerCase().contains(q) ||
          (c.driverName ?? '').toLowerCase().contains(q) ||
          (c.location ?? '').toLowerCase().contains(q) ||
          c.routeDescription.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Tracking',
            title: 'Check-Ins',
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
    if (_error != null) {
      return _wrapScroll(AppError(message: _error!, onRetry: _load));
    }

    final checkIns = _filtered;

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
          _buildStatusChips(),
          const SizedBox(height: 16),
          if (checkIns.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.32,
              child: AppEmpty(
                icon: Icons.where_to_vote_outlined,
                message: _search.isNotEmpty || _statusFilter != 'all'
                    ? 'No check-ins match your filters.'
                    : 'No check-ins yet. Driver check-ins will appear here.',
              ),
            )
          else
            for (var i = 0; i < checkIns.length; i++)
              RevealOnLoad(
                delayMs: (i * 60).clamp(0, 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CheckInCard(checkIn: checkIns[i]),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildStats(CheckInStats stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Today',
            value: '${stats.today}',
            icon: Icons.today_rounded,
            accent: _accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Open issues',
            value: '${stats.issues + stats.emergency}',
            icon: Icons.report_problem_rounded,
            accent: ModuleAccent.danger,
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
        hintText: 'Search trip, driver or location',
        hintStyle: AppType.body(13.5, color: kMuted),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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

  Widget _buildStatusChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((f) {
          final (value, label) = f;
          final selected = _statusFilter == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? _accent.base
                      : AppColors.chipUnselected(context),
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
              child: AppSkeleton.box(context, height: 124, radius: 18),
            ),
        ],
      ),
    );
  }
}

// ── Check-in card ────────────────────────────────────────────────────────────

class _CheckInCard extends StatelessWidget {
  final CheckIn checkIn;
  const _CheckInCard({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final statusColor = checkIn.statusColor;

    return AppCard(
      accentColor: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.where_to_vote_rounded,
                    size: 18, color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkIn.tripNumber ?? 'Unknown trip',
                      style: AppType.number(14, color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (checkIn.routeDescription.isNotEmpty)
                      Text(
                        checkIn.routeDescription,
                        style: AppType.body(11, color: kMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: checkIn.statusLabel, color: statusColor),
            ],
          ),
          if (checkIn.driverName != null && checkIn.driverName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    checkIn.driverName!,
                    style: AppType.body(12, color: AppColors.textPrimary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (checkIn.location != null && checkIn.location!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    checkIn.location!,
                    style: AppType.body(12, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 12, color: kMuted),
              const SizedBox(width: 4),
              Text(
                checkIn.checkedInAt != null
                    ? formatDateTime(checkIn.checkedInAt!)
                    : '—',
                style: AppType.body(11, color: kMuted),
              ),
              if (checkIn.odometerKm != null) ...[
                const SizedBox(width: 14),
                const Icon(Icons.speed_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text('${checkIn.odometerKm} km',
                    style: AppType.number(11,
                        weight: FontWeight.w700, color: kMuted)),
              ],
            ],
          ),
          if (checkIn.notes != null && checkIn.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              checkIn.notes!,
              style: AppType.body(12, color: AppColors.textPrimary(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
