import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/inspection.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/app_theme.dart';
import '../inspection_service.dart';

class InspectionScreen extends StatefulWidget {
  final ApiClient apiClient;
  const InspectionScreen({super.key, required this.apiClient});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  late final InspectionService _service;

  String _inspectionType = 'pre_trip';
  String _overallStatus = 'ok';
  final Map<String, String> _statuses = {}; // key → 'ok'|'issue'|'na'
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  final List<({String value, String label})> _types = const [
    (value: 'pre_trip', label: 'Pre-Trip'),
    (value: 'periodic', label: 'On-Route'),
    (value: 'post_trip', label: 'Post-Trip'),
  ];

  final List<({String value, String label, Color color})> _overallOptions = const [
    (value: 'ok', label: 'All Good', color: kSuccess),
    (value: 'minor_issues', label: 'Minor Issues', color: kWarning),
    (value: 'critical', label: 'Critical', color: kDanger),
  ];

  @override
  void initState() {
    super.initState();
    _service = InspectionService(widget.apiClient);
    for (final section in inspectionSections) {
      for (final item in section.items) {
        _statuses[item.key] = 'ok';
      }
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final unanswered = _statuses.values.where((v) => v.isEmpty).length;
    if (unanswered > 0) {
      setState(() => _error = 'Please complete all checklist items.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final items = _statuses.entries
          .map((e) => InspectionItem(key: e.key, status: e.value))
          .toList();
      await _service.submit(
        inspectionType: _inspectionType,
        overallStatus: _overallStatus,
        items: items,
        odometerKm: int.tryParse(_odometerController.text.trim()),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection submitted successfully'),
          backgroundColor: kSuccess,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to submit. Check your connection.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Staggered reveal order: type selector, sections A–E, overall, odometer, notes.
    var reveal = 0;
    int nextDelay() => (reveal++ * 60).clamp(0, 300);

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Vehicle inspection',
            title: 'Safety Checklist',
            subtitle: 'Complete all checklist items',
            actions: [
              HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              children: [
                RevealOnLoad(delayMs: nextDelay(), child: _buildTypeSelector()),
                const SizedBox(height: 18),
                ...inspectionSections.map(
                  (s) => RevealOnLoad(delayMs: nextDelay(), child: _buildSection(s)),
                ),
                const SizedBox(height: 4),
                RevealOnLoad(delayMs: nextDelay(), child: _buildOverallStatus()),
                const SizedBox(height: 18),
                RevealOnLoad(delayMs: nextDelay(), child: _buildOdometer()),
                const SizedBox(height: 18),
                RevealOnLoad(delayMs: nextDelay(), child: _buildNotes()),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _buildError(),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'Scope',
          title: 'Inspection Type',
          icon: Icons.fact_check_rounded,
          accent: ModuleAccent.ops,
        ),
        AppCard(
          child: Row(
            children: _types.map((t) {
              final selected = _inspectionType == t.value;
              final isLast = t == _types.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: _SegmentButton(
                    label: t.label,
                    selected: selected,
                    color: kPrimary,
                    onTap: () => setState(() => _inspectionType = t.value),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(InspectionSection section) {
    final issueCount = section.items
        .where((i) => _statuses[i.key] == 'issue')
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Section ${section.letter}',
            title: section.title,
            icon: _sectionIcon(section.letter),
            accent: ModuleAccent.ops,
            trailing: issueCount > 0
                ? StatusPill(
                    label: '$issueCount issue${issueCount > 1 ? 's' : ''}',
                    color: statusColor('issue'),
                    icon: Icons.warning_amber_rounded,
                  )
                : null,
          ),
          AppCard(
            padding: EdgeInsets.zero,
            accentColor: issueCount > 0 ? statusColor('issue') : statusColor('ok'),
            child: Column(
              children: [
                for (var i = 0; i < section.items.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: AppColors.border(context)),
                  _buildCheckRow(section.items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _sectionIcon(String letter) {
    switch (letter) {
      case 'A':
        return Icons.opacity_rounded;
      case 'B':
        return Icons.trip_origin_rounded;
      case 'C':
        return Icons.lightbulb_outline_rounded;
      case 'D':
        return Icons.health_and_safety_rounded;
      case 'E':
        return Icons.inventory_2_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }

  Widget _buildCheckRow(InspectionCheckItem item) {
    final current = _statuses[item.key] ?? 'ok';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(item.label,
                style: AppType.body(14, color: AppColors.textNavy(context))),
          ),
          const SizedBox(width: 12),
          _StatusSegment(
            label: 'OK',
            selected: current == 'ok',
            color: statusColor('ok'),
            onTap: () => setState(() => _statuses[item.key] = 'ok'),
          ),
          const SizedBox(width: 8),
          _StatusSegment(
            label: 'Issue',
            selected: current == 'issue',
            color: statusColor('issue'),
            onTap: () => setState(() => _statuses[item.key] = 'issue'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'Verdict',
          title: 'Overall Vehicle Status',
          icon: Icons.verified_rounded,
          accent: ModuleAccent.ops,
        ),
        AppCard(
          child: Row(
            children: _overallOptions.map((opt) {
              final selected = _overallStatus == opt.value;
              final isLast = opt == _overallOptions.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: _SegmentButton(
                    label: opt.label,
                    selected: selected,
                    color: opt.color,
                    tinted: true,
                    onTap: () => setState(() => _overallStatus = opt.value),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOdometer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'Reading',
          title: 'Odometer (km)',
          icon: Icons.speed_rounded,
          accent: ModuleAccent.ops,
        ),
        AppCard(
          child: TextFormField(
            controller: _odometerController,
            keyboardType: TextInputType.number,
            style: AppType.number(17, color: AppColors.textNavy(context)),
            decoration: InputDecoration(
              hintText: 'Optional',
              hintStyle: AppType.body(14, color: kMuted),
              prefixIcon: const Icon(Icons.speed_rounded, color: kMuted, size: 20),
              filled: true,
              fillColor: AppColors.surfaceVariant(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'Notes',
          title: 'Observations',
          icon: Icons.notes_rounded,
          accent: ModuleAccent.ops,
        ),
        AppCard(
          child: TextFormField(
            controller: _notesController,
            maxLines: 3,
            style: AppType.body(15, color: AppColors.textNavy(context)),
            decoration: InputDecoration(
              hintText: 'Any additional observations...',
              hintStyle: AppType.body(14, color: kMuted),
              filled: true,
              fillColor: AppColors.surfaceVariant(context),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kDanger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDanger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kDanger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style: AppType.body(13, color: kDanger, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    final issueCount = _statuses.values.where((v) => v == 'issue').length;
    return Container(
      color: AppColors.navBar(context),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (issueCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: statusColor('issue')),
                  const SizedBox(width: 6),
                  Text(
                    '$issueCount item${issueCount > 1 ? 's' : ''} flagged with issues',
                    style: AppType.body(12,
                        color: statusColor('issue'), weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1638),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text('Submit Inspection',
                      style: AppType.body(16,
                          color: Colors.white, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width segmented option (inspection type / overall status).
class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool tinted;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    if (selected) {
      bg = tinted ? color.withValues(alpha: 0.15) : color;
      border = color;
      fg = tinted ? color : Colors.white;
    } else {
      bg = AppColors.surfaceVariant(context);
      border = AppColors.border(context);
      fg = kMuted;
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border, width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppType.body(12.5, color: fg, weight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Compact ok/issue status chip for a checklist row.
class _StatusSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusSegment({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.border(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppType.body(12, color: selected ? color : kMuted, weight: FontWeight.w700),
        ),
      ),
    );
  }
}
