import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/job_application.dart';
import '../models/vacancy.dart';
import '../talent_service.dart';

/// Detail view for a single job vacancy: overview, the application pipeline,
/// and the list of candidates who applied.
class VacancyDetailScreen extends StatefulWidget {
  final int vacancyId;
  final TalentService service;

  const VacancyDetailScreen({
    super.key,
    required this.vacancyId,
    required this.service,
  });

  @override
  State<VacancyDetailScreen> createState() => _VacancyDetailScreenState();
}

class _VacancyDetailScreenState extends State<VacancyDetailScreen> {
  late Future<VacancyDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchVacancy(widget.vacancyId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchVacancy(widget.vacancyId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VacancyDetail>(
      future: _future,
      builder: (context, snapshot) {
        final vacancy = snapshot.data?.vacancy;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(vacancy),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Vacancy? vacancy) {
    return AppGradientHeader(
      eyebrow: 'Vacancy',
      title: vacancy?.title ?? 'Vacancy',
      subtitle: vacancy?.department ?? vacancy?.statusLabel,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
            icon: Icons.refresh_rounded, onTap: _reload, tooltip: 'Refresh'),
      ],
    );
  }

  Widget _buildBody(AsyncSnapshot<VacancyDetail> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final detail = snapshot.data!;
    final v = detail.vacancy;
    final apps = detail.applications;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildOverviewCard(v)),
            if (v.pipeline.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 60, child: _buildPipelineCard(v)),
            ],
            if ((v.description != null && v.description!.isNotEmpty) ||
                (v.requirements != null && v.requirements!.isNotEmpty)) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 120, child: _buildDetailsCard(v)),
            ],
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 180, child: _buildApplicationsCard(apps)),
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
          AppSkeleton.box(context, height: 120, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 110, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 200, radius: 16),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Vacancy v) {
    final color = Color(v.statusColorValue);
    return _SectionCard(
      title: 'Overview',
      eyebrow: 'Position',
      icon: Icons.work_outline_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(v.title,
                  style:
                      AppType.display(18, color: AppColors.textNavy(context))),
            ),
            StatusPill(label: v.statusLabel, color: color),
          ],
        ),
        const Divider(height: 20),
        if (v.department != null && v.department!.isNotEmpty)
          _IconLine(
              icon: Icons.apartment_rounded, text: v.department!),
        Row(
          children: [
            Expanded(
              child: _IconLine(
                icon: Icons.people_alt_outlined,
                text:
                    '${v.openings ?? 1} opening${(v.openings ?? 1) == 1 ? '' : 's'}',
              ),
            ),
            Expanded(
              child: _IconLine(
                icon: Icons.event_busy_outlined,
                text: v.closingDate != null
                    ? 'Closes ${formatDate(v.closingDate)}'
                    : 'No closing date',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _IconLine(
          icon: Icons.inbox_outlined,
          text:
              '${v.applicationsCount} application${v.applicationsCount == 1 ? '' : 's'}',
        ),
        if (v.createdBy != null && v.createdBy!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(
              icon: Icons.person_outline_rounded, text: 'By ${v.createdBy}'),
        ],
      ],
    );
  }

  Widget _buildPipelineCard(Vacancy v) {
    return _SectionCard(
      title: 'Pipeline',
      eyebrow: 'Stages',
      icon: Icons.timeline_rounded,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: v.pipeline.map((p) {
            final color = Color(p.colorValue);
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${p.count}',
                      style: AppType.number(15, color: color)),
                  const SizedBox(width: 6),
                  Text(p.label,
                      style: AppType.body(12,
                          weight: FontWeight.w600,
                          color: AppColors.textPrimary(context))),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(Vacancy v) {
    return _SectionCard(
      title: 'Details',
      eyebrow: 'Role',
      icon: Icons.description_outlined,
      children: [
        if (v.description != null && v.description!.isNotEmpty) ...[
          Text('Description',
              style: AppType.body(11,
                  color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(v.description!, style: AppType.body(13.5, height: 1.5)),
        ],
        if (v.requirements != null && v.requirements!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Requirements',
              style: AppType.body(11,
                  color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(v.requirements!, style: AppType.body(13.5, height: 1.5)),
        ],
      ],
    );
  }

  Widget _buildApplicationsCard(List<JobApplication> apps) {
    return _SectionCard(
      title: 'Applications (${apps.length})',
      eyebrow: 'Candidates',
      icon: Icons.groups_outlined,
      children: apps.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No applications yet.',
                    style: AppType.body(14, color: kMuted)),
              )
            ]
          : [
              for (var i = 0; i < apps.length; i++) ...[
                if (i > 0) const _Divider(),
                _ApplicationRow(application: apps[i]),
              ],
            ],
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  final JobApplication application;
  const _ApplicationRow({required this.application});

  @override
  Widget build(BuildContext context) {
    final color = Color(application.stageColorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(application.applicantName,
                    style: AppType.body(14,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary(context))),
              ),
              StatusPill(label: application.stageLabel, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (application.phone != null && application.phone!.isNotEmpty)
                _IconLine(icon: Icons.phone_outlined, text: application.phone!),
              if (application.email != null && application.email!.isNotEmpty)
                _IconLine(icon: Icons.email_outlined, text: application.email!),
              if (application.hasCv)
                const _IconLine(
                    icon: Icons.attach_file_rounded, text: 'CV attached'),
            ],
          ),
          if (application.interviewDate != null) ...[
            const SizedBox(height: 4),
            _IconLine(
              icon: Icons.event_outlined,
              text: 'Interview ${formatDateTime(application.interviewDate!)}',
            ),
          ],
          if (application.offerAmount != null) ...[
            const SizedBox(height: 4),
            _IconLine(
              icon: Icons.payments_outlined,
              text: 'Offer ${formatCurrency(application.offerAmount!)}',
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared detail widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title,
      this.eyebrow,
      required this.icon,
      required this.children});

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
              accent: ModuleAccent.hr),
          ...children,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 14, thickness: 0.5);
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: AppType.body(12, color: kMuted))),
      ],
    );
  }
}
