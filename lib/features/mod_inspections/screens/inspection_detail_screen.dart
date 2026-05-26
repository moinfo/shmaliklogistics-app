import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../inspections_service.dart';
import '../models/inspection.dart';
import 'inspections_screen.dart' show inspectionStatusColor, inspectionTypeColor;

class InspectionDetailScreen extends StatefulWidget {
  final int inspectionId;
  final InspectionsService service;

  const InspectionDetailScreen({
    super.key,
    required this.inspectionId,
    required this.service,
  });

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  late Future<Inspection> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchInspection(widget.inspectionId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchInspection(widget.inspectionId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Inspection>(
      future: _future,
      builder: (context, snapshot) {
        final inspection = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(inspection),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Inspection? inspection) {
    return AppGradientHeader(
      eyebrow: 'Inspection',
      title: inspection?.vehiclePlate ?? 'Inspection',
      subtitle: inspection?.typeLabel,
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

  Widget _buildBody(AsyncSnapshot<Inspection> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final i = snapshot.data!;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildSummaryCard(i)),
            const SizedBox(height: 14),
            ...List.generate(i.sections.length, (idx) {
              final s = i.sections[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RevealOnLoad(
                  delayMs: ((idx + 1) * 70).clamp(0, 300),
                  child: _buildSectionCard(s),
                ),
              );
            }),
            if (i.notes != null && i.notes!.isNotEmpty)
              RevealOnLoad(
                delayMs: 300,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(i.notes!, style: AppType.body(14, height: 1.5))],
                ),
              ),
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
          AppSkeleton.box(context, height: 170, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 200, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 200, radius: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Inspection i) {
    final statusColor = inspectionStatusColor(i);
    final typeColor = inspectionTypeColor(i);
    return _SectionCard(
      title: 'Overview',
      eyebrow: 'Inspection',
      icon: Icons.fact_check_outlined,
      children: [
        Row(
          children: [
            StatusPill(label: i.overallStatusLabel, color: statusColor),
            const SizedBox(width: 8),
            StatusPill(label: i.typeLabel, color: typeColor),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Items OK',
                value: i.okCount.toString(),
                valueColor: kSuccess,
              ),
            ),
            Expanded(
              child: _MiniStat(
                label: 'Issues',
                value: i.issueCount.toString(),
                valueColor: i.issueCount > 0 ? kDanger : AppColors.textPrimary(context),
              ),
            ),
            Expanded(
              child: _MiniStat(
                label: 'Odometer',
                value: i.odometerKm != null ? '${i.odometerKm} km' : '—',
              ),
            ),
          ],
        ),
        const Divider(height: 22),
        if (i.vehicleDescription.isNotEmpty)
          _IconLine(icon: Icons.directions_car_outlined, text: i.vehicleDescription),
        const SizedBox(height: 6),
        _IconLine(
          icon: Icons.person_outline_rounded,
          text: i.inspectorName ?? 'Unknown inspector',
        ),
        if (i.inspectorPhone != null && i.inspectorPhone!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.phone_outlined, text: i.inspectorPhone!),
        ],
        const SizedBox(height: 6),
        _IconLine(
          icon: Icons.schedule_outlined,
          text: i.inspectedAt != null ? formatDateTime(i.inspectedAt!) : 'No date recorded',
        ),
        if (i.location != null && i.location!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.place_outlined, text: i.location!),
        ],
        if (i.tripNumber != null && i.tripNumber!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(
            icon: Icons.local_shipping_outlined,
            text: [
              i.tripNumber,
              if (i.routeFrom != null) '${i.routeFrom} → ${i.routeTo}',
            ].whereType<String>().join('  ·  '),
          ),
        ],
        if (i.createdByName != null && i.createdByName!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.badge_outlined, text: 'Logged by ${i.createdByName}'),
        ],
      ],
    );
  }

  Widget _buildSectionCard(InspectionSection s) {
    final issues = s.issueCount;
    return _SectionCard(
      title: s.title,
      eyebrow: 'Checklist',
      icon: issues > 0 ? Icons.warning_amber_rounded : Icons.checklist_rounded,
      trailing: issues > 0
          ? StatusPill(label: '$issues issue${issues == 1 ? '' : 's'}', color: kDanger)
          : null,
      children: s.items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: _ChecklistRow(item: item),
              ))
          .toList(),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final InspectionItem item;
  const _ChecklistRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    if (item.isOk) {
      color = kSuccess;
      icon = Icons.check_circle_rounded;
    } else if (item.isIssue) {
      color = kDanger;
      icon = Icons.error_rounded;
    } else {
      color = kMuted;
      icon = Icons.remove_circle_outline_rounded;
    }
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            style: AppType.body(13.5,
                color: AppColors.textPrimary(context), weight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.statusLabel,
          style: AppType.body(12, color: color, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ── Shared detail widgets ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    this.eyebrow,
    required this.icon,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            eyebrow: eyebrow,
            icon: icon,
            accent: ModuleAccent.ops,
            trailing: trailing,
          ),
          ...children,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MiniStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.body(10.5, color: kMuted, weight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: AppType.number(15, color: valueColor ?? AppColors.textPrimary(context))),
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
        Icon(icon, size: 14, color: kMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppType.body(13, color: kMuted))),
      ],
    );
  }
}
