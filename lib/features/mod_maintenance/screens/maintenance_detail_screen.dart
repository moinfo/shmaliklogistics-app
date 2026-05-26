import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../maintenance_service.dart';
import '../models/service_record.dart';
import 'maintenance_screen.dart' show kMaintAccent, maintenanceStatusColor, formatServiceCost;

/// Read-only detail for a single vehicle service record.
class MaintenanceDetailScreen extends StatefulWidget {
  final int recordId;
  final MaintenanceService service;

  const MaintenanceDetailScreen({
    super.key,
    required this.recordId,
    required this.service,
  });

  @override
  State<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  late Future<ServiceRecord> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchRecord(widget.recordId);
  }

  void _reload() => setState(() => _future = widget.service.fetchRecord(widget.recordId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceRecord>(
      future: _future,
      builder: (context, snapshot) {
        final record = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(record),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ServiceRecord? record) {
    return AppGradientHeader(
      eyebrow: 'Service record',
      title: record?.vehiclePlate ?? 'Maintenance',
      subtitle: record?.serviceType,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        HeaderIconButton(icon: Icons.refresh_rounded, onTap: _reload, tooltip: 'Refresh'),
      ],
    );
  }

  Widget _buildBody(AsyncSnapshot<ServiceRecord> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final r = snapshot.data!;
    final statusColor = maintenanceStatusColor(r.status);

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildOverviewCard(r, statusColor)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _buildServiceCard(r)),
            if (r.nextServiceDate != null || r.nextServiceMileage != null) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 120, child: _buildNextServiceCard(r)),
            ],
            if (r.description != null && r.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 180,
                child: _SectionCard(
                  title: 'Description',
                  eyebrow: 'Work done',
                  icon: Icons.description_outlined,
                  children: [Text(r.description!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 240,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(r.notes!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppSkeleton.box(context, height: 130, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 170, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 110, radius: 16),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ServiceRecord r, Color statusColor) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: r.vehiclePlate ?? 'Unknown vehicle',
            eyebrow: 'Vehicle',
            icon: Icons.local_shipping_outlined,
            accent: kMaintAccent,
            trailing: StatusPill(label: r.statusLabel, color: statusColor),
          ),
          if (r.vehicleDescription != null) ...[
            _IconLine(icon: Icons.directions_car_outlined, text: r.vehicleDescription!),
            const SizedBox(height: 4),
          ],
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Cost',
                  value: formatServiceCost(r.cost, r.currency),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Odometer',
                  value: r.odometerKm != null ? '${_grouped(r.odometerKm!)} km' : '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceRecord r) {
    return _SectionCard(
      title: 'Service Details',
      eyebrow: 'Record',
      icon: Icons.build_outlined,
      children: [
        _DetailRow(label: 'Service type', value: r.serviceType),
        _DetailRow(label: 'Service date', value: formatDate(r.serviceDate)),
        if (r.workshopName != null && r.workshopName!.isNotEmpty)
          _DetailRow(label: 'Workshop', value: r.workshopName!),
        _DetailRow(label: 'Cost', value: formatServiceCost(r.cost, r.currency), isNumber: true),
      ],
    );
  }

  Widget _buildNextServiceCard(ServiceRecord r) {
    return _SectionCard(
      title: 'Next Service',
      eyebrow: 'Upcoming',
      icon: Icons.event_repeat_outlined,
      children: [
        if (r.nextServiceDate != null)
          _DetailRow(label: 'Due date', value: formatDate(r.nextServiceDate)),
        if (r.nextServiceMileage != null)
          _DetailRow(
            label: 'Due mileage',
            value: '${_grouped(r.nextServiceMileage!)} km',
            isNumber: true,
          ),
      ],
    );
  }

  static String _grouped(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${value < 0 ? '-' : ''}$buf';
  }
}

// ── Shared detail widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, this.eyebrow, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: kMaintAccent),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isNumber;
  const _DetailRow({required this.label, required this.value, this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppType.body(13, color: kMuted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: isNumber
                  ? AppType.number(13.5, color: AppColors.textPrimary(context))
                  : AppType.body(13.5, weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.body(10, color: kMuted, weight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: AppType.number(14, color: AppColors.textPrimary(context))),
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppType.body(12, color: kMuted))),
      ],
    );
  }
}
