import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/proforma.dart';
import '../proforma_service.dart';
import 'proforma_detail_screen.dart';

/// Maps a proforma status to its display colour (mirrors the web
/// `BillingDocument::$proformaStatuses` palette).
Color proformaStatusColor(String status, {String? hex}) {
  if (hex != null && hex.isNotEmpty) {
    final parsed = _parseHex(hex);
    if (parsed != null) return parsed;
  }
  switch (status) {
    case 'draft':    return const Color(0xFF94A3B8);
    case 'sent':     return const Color(0xFF60A5FA);
    case 'accepted': return const Color(0xFF22C55E);
    case 'expired':  return const Color(0xFFF59E0B);
    default:         return const Color(0xFF94A3B8);
  }
}

Color? _parseHex(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// Formats an amount with an explicit currency code (proformas may be USD/TZS).
String formatProformaMoney(double amount, String currency) {
  return '$currency ${_thousands(amount)}';
}

String _thousands(double amount) {
  final whole = amount.round();
  final s = whole.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${whole < 0 ? '-' : ''}$buf';
}

/// Billing · Proformas list screen. Read-only: searchable, status-filterable
/// list of proforma documents with tap-through to a detail view.
class ProformasScreen extends StatefulWidget {
  const ProformasScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ProformasScreen> createState() => _ProformasScreenState();
}

class _ProformasScreenState extends State<ProformasScreen> {
  late final ProformaService _service;
  late Future<List<Proforma>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  static const _statusFilters = [
    ('all', 'All'),
    ('draft', 'Draft'),
    ('sent', 'Sent'),
    ('accepted', 'Accepted'),
    ('expired', 'Expired'),
  ];

  @override
  void initState() {
    super.initState();
    _service = ProformaService(widget.apiClient);
    _future = _service.fetchProformas();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchProformas());

  List<Proforma> _applyFilters(List<Proforma> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final matchesStatus = _statusFilter == 'all' || p.status == _statusFilter;
      final matchesQuery = q.isEmpty ||
          p.documentNumber.toLowerCase().contains(q) ||
          (p.clientName ?? '').toLowerCase().contains(q);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Billing',
            title: 'Proforma',
            subtitle: 'Pro forma invoices',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search number or client…',
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
          filled: true,
          fillColor: AppColors.surface(context),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = _statusFilters[i];
          final selected = _statusFilter == value;
          final color = value == 'all' ? kPrimary : proformaStatusColor(value);
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.14) : AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color : AppColors.border(context),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Text(
                label,
                style: AppType.body(
                  12.5,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : kMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Proforma>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _reload);
        }
        final filtered = _applyFilters(snapshot.data ?? []);
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _reload(),
          child: filtered.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: const AppEmpty(
                        icon: Icons.description_outlined,
                        message: 'No proformas\nProforma documents will appear here.',
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProformaCard(
                        proforma: filtered[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProformaDetailScreen(
                              proformaId: filtered[i].id,
                              service: _service,
                            ),
                          ),
                        ),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 118, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ProformaCard extends StatelessWidget {
  const _ProformaCard({required this.proforma, required this.onTap});

  final Proforma proforma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = proformaStatusColor(proforma.status, hex: proforma.statusColor);
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(proforma.documentNumber,
                  style: AppType.display(15, color: AppColors.textNavy(context))),
              StatusPill(label: proforma.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            proforma.clientName ?? proforma.clientCompany ?? 'Unknown client',
            style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: AppType.body(10, color: kMuted, weight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    formatProformaMoney(proforma.total, proforma.currency),
                    style: AppType.number(15, color: AppColors.textPrimary(context)),
                  ),
                ],
              ),
              const Spacer(),
              if (proforma.issueDate != null) ...[
                const Icon(Icons.event_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(formatDate(proforma.issueDate), style: AppType.body(11, color: kMuted)),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right_rounded, size: 16, color: kMuted),
            ],
          ),
        ],
      ),
    );
  }
}
