import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/appraisal.dart';
import '../models/vacancy.dart';
import '../talent_service.dart';
import 'vacancy_detail_screen.dart';

/// HR → Talent. Entry screen wired into the app shell by the orchestrator.
/// Two internal tabs: Recruitment (job vacancies → tap for applications) and
/// Appraisals (staff performance reviews with metric scores). Read-only.
class TalentScreen extends StatefulWidget {
  const TalentScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<TalentScreen> createState() => _TalentScreenState();
}

class _TalentScreenState extends State<TalentScreen> {
  late final TalentService _service;

  int _tab = 0;

  Future<List<Vacancy>>? _vacanciesFuture;
  Future<List<Appraisal>>? _appraisalsFuture;

  final _searchCtrl = TextEditingController();
  String _search = '';

  // Recruitment filter — mirrors JobVacancy::$statuses.
  String _vacancyStatus = 'all';
  static const _vacancyStatusOptions = <(String, String)>[
    ('all', 'All'),
    ('open', 'Open'),
    ('closed', 'Closed'),
    ('filled', 'Filled'),
  ];

  // Appraisal filter — mirrors Appraisal::$statuses.
  String _appraisalStatus = 'all';
  static const _appraisalStatusOptions = <(String, String)>[
    ('all', 'All'),
    ('published', 'Published'),
    ('draft', 'Draft'),
  ];

  @override
  void initState() {
    super.initState();
    _service = TalentService(widget.apiClient);
    _vacanciesFuture = _service.fetchVacancies();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged(int tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _search = '';
      _searchCtrl.clear();
    });
    // Lazy-load the appraisals list on first visit.
    if (tab == 1 && _appraisalsFuture == null) {
      setState(() => _appraisalsFuture = _service.fetchAppraisals());
    }
  }

  void _reload() {
    setState(() {
      if (_tab == 0) {
        _vacanciesFuture = _service.fetchVacancies();
      } else {
        _appraisalsFuture = _service.fetchAppraisals();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Talent',
            title: 'Recruitment',
            subtitle: _tab == 0
                ? 'Vacancies & applications'
                : 'Staff performance appraisals',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildTabBar(),
          _buildSearchBar(),
          _buildStatusChips(),
          Expanded(
            child: _tab == 0 ? _buildRecruitmentTab() : _buildAppraisalsTab(),
          ),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _topTab('Recruitment', Icons.work_outline_rounded, 0),
          const SizedBox(width: 8),
          _topTab('Appraisals', Icons.star_outline_rounded, 1),
        ],
      ),
    );
  }

  Widget _topTab(String label, IconData icon, int index) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: ModuleAccent.hr.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.border(context),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ModuleAccent.hr.base.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : kMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppType.body(
                  13,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search + filter chips ───────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _search = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: _tab == 0
              ? 'Search vacancy title or department'
              : 'Search employee name',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: AppColors.surface(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    final options =
        _tab == 0 ? _vacancyStatusOptions : _appraisalStatusOptions;
    final current = _tab == 0 ? _vacancyStatus : _appraisalStatus;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = options[i];
          final selected = current == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() {
              if (_tab == 0) {
                _vacancyStatus = value;
              } else {
                _appraisalStatus = value;
              }
            }),
            labelStyle: AppType.body(12.5,
                weight: FontWeight.w600,
                color: selected ? Colors.white : kMuted),
            selectedColor: ModuleAccent.hr.base,
            backgroundColor: AppColors.surface(context),
            side: BorderSide(color: AppColors.border(context)),
            showCheckmark: false,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  // ── Recruitment tab ───────────────────────────────────────────────────────

  List<Vacancy> _applyVacancies(List<Vacancy> vacancies) {
    final q = _search.trim().toLowerCase();
    return vacancies.where((v) {
      if (_vacancyStatus != 'all' && v.status != _vacancyStatus) return false;
      if (q.isEmpty) return true;
      return v.title.toLowerCase().contains(q) ||
          (v.department?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Widget _buildRecruitmentTab() {
    return FutureBuilder<List<Vacancy>>(
      future: _vacanciesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _reload);
        }
        final all = snapshot.data ?? [];
        final vacancies = _applyVacancies(all);
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _reload(),
          child: vacancies.isEmpty
              ? _emptyList(
                  icon: Icons.work_off_outlined,
                  message: all.isEmpty
                      ? 'No vacancies yet.'
                      : 'No vacancies match your filters.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: vacancies.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VacancyCard(
                        vacancy: vacancies[i],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VacancyDetailScreen(
                                vacancyId: vacancies[i].id,
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

  // ── Appraisals tab ──────────────────────────────────────────────────────────

  List<Appraisal> _applyAppraisals(List<Appraisal> appraisals) {
    final q = _search.trim().toLowerCase();
    return appraisals.where((a) {
      if (_appraisalStatus != 'all' && a.status != _appraisalStatus) {
        return false;
      }
      if (q.isEmpty) return true;
      return a.employeeName.toLowerCase().contains(q) ||
          (a.employeeNumber?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Widget _buildAppraisalsTab() {
    return FutureBuilder<List<Appraisal>>(
      future: _appraisalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _reload);
        }
        final all = snapshot.data ?? [];
        final appraisals = _applyAppraisals(all);
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _reload(),
          child: appraisals.isEmpty
              ? _emptyList(
                  icon: Icons.star_border_rounded,
                  message: all.isEmpty
                      ? 'No appraisals yet.'
                      : 'No appraisals match your filters.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: appraisals.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AppraisalCard(appraisal: appraisals[i]),
                    ),
                  ),
                ),
        );
      },
    );
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  Widget _emptyList({required IconData icon, required String message}) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: AppEmpty(icon: icon, message: message),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (var i = 0; i < 5; i++) ...[
            AppSkeleton.box(context, height: 116, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────

class _VacancyCard extends StatelessWidget {
  final Vacancy vacancy;
  final VoidCallback onTap;
  const _VacancyCard({required this.vacancy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(vacancy.statusColorValue);
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
                child: Text(vacancy.title,
                    style: AppType.display(15,
                        color: AppColors.textNavy(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              StatusPill(label: vacancy.statusLabel, color: color),
            ],
          ),
          if (vacancy.department != null &&
              vacancy.department!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(vacancy.department!,
                style: AppType.body(13,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                icon: Icons.inbox_outlined,
                value: '${vacancy.applicationsCount}',
                label: 'Applications',
              ),
              const SizedBox(width: 18),
              _MiniStat(
                icon: Icons.people_alt_outlined,
                value: '${vacancy.openings ?? 1}',
                label: 'Openings',
              ),
              const Spacer(),
              if (vacancy.closingDate != null) ...[
                const Icon(Icons.event_busy_outlined,
                    size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(formatDate(vacancy.closingDate),
                    style: AppType.body(11, color: kMuted)),
              ],
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: ModuleAccent.hr.base),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MiniStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ModuleAccent.hr.base),
        const SizedBox(width: 5),
        Text(value,
            style: AppType.number(14, color: AppColors.textNavy(context))),
        const SizedBox(width: 4),
        Text(label, style: AppType.body(10.5, color: kMuted)),
      ],
    );
  }
}

class _AppraisalCard extends StatelessWidget {
  final Appraisal appraisal;
  const _AppraisalCard({required this.appraisal});

  @override
  Widget build(BuildContext context) {
    final color = Color(appraisal.statusColorValue);
    final score = appraisal.overallScore;
    final scoreColor = score == null
        ? kMuted
        : score >= 4
            ? kSuccess
            : score >= 2.5
                ? kWarning
                : kDanger;
    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appraisal.employeeName,
                        style: AppType.display(15,
                            color: AppColors.textNavy(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (appraisal.position != null &&
                        appraisal.position!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(appraisal.position!,
                          style: AppType.body(12, color: kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: appraisal.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall score',
                      style: AppType.body(10,
                          color: kMuted, weight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        score != null ? score.toStringAsFixed(2) : '—',
                        style: AppType.number(20, color: scoreColor),
                      ),
                      Text(' / 5',
                          style: AppType.body(11, color: kMuted)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (appraisal.hasPeriod) ...[
                const Icon(Icons.date_range_outlined,
                    size: 12, color: kMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${formatDate(appraisal.periodFrom)} – ${formatDate(appraisal.periodTo)}',
                    style: AppType.body(11, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
