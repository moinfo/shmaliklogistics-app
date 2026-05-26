import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/quote.dart';
import '../quote_service.dart';
import 'quote_detail_screen.dart';

/// Maps a quote status to its display colour (mirrors the web
/// `BillingDocument::$quoteStatuses` palette).
Color quoteStatusColor(String status) {
  switch (status) {
    case 'draft':    return const Color(0xFF94A3B8);
    case 'sent':     return const Color(0xFF60A5FA);
    case 'accepted': return const Color(0xFF22C55E);
    case 'rejected': return const Color(0xFFEF4444);
    case 'expired':  return const Color(0xFFF59E0B);
    default:         return const Color(0xFF94A3B8);
  }
}

/// Formats an amount with an explicit currency code (quotes may be USD/TZS).
String formatQuoteMoney(double amount, String currency) {
  final whole = amount.round();
  final s = whole.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$currency ${whole < 0 ? '-' : ''}$buf';
}

/// Billing Quotes feature entry point (Module #11). A searchable, status-
/// filterable list of quotes; tapping a card pushes the detail screen.
class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  late final QuoteService _service;
  late Future<List<Quote>> _future;

  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _statusFilter;

  static const _statuses = [
    ('draft', 'Draft'),
    ('sent', 'Sent'),
    ('accepted', 'Accepted'),
    ('rejected', 'Rejected'),
    ('expired', 'Expired'),
  ];

  @override
  void initState() {
    super.initState();
    _service = QuoteService(widget.apiClient);
    _future = _service.fetchQuotes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchQuotes());

  List<Quote> _applyFilters(List<Quote> quotes) {
    final q = _search.trim().toLowerCase();
    return quotes.where((quote) {
      if (_statusFilter != null && quote.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return quote.documentNumber.toLowerCase().contains(q) ||
          (quote.clientName ?? '').toLowerCase().contains(q) ||
          (quote.clientCompany ?? '').toLowerCase().contains(q);
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
            title: 'Quotes',
            subtitle: 'Quotations issued to clients',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildSearchAndFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: AppType.body(14, color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: 'Search number or client…',
              hintStyle: AppType.body(14, color: kMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: kMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
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
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('All', null),
                for (final s in _statuses) _filterChip(s.$2, s.$1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _statusFilter == value;
    final color = value == null ? ModuleAccent.finance.base : quoteStatusColor(value);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        labelStyle: AppType.body(12.5,
            weight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary(context)),
        selected: selected,
        showCheckmark: false,
        backgroundColor: AppColors.surfaceVariant(context),
        selectedColor: color,
        side: BorderSide(color: selected ? color : AppColors.border(context)),
        onSelected: (_) => setState(() => _statusFilter = value),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Quote>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _reload);
        }
        final quotes = _applyFilters(snapshot.data ?? []);
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _reload(),
          child: quotes.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: const AppEmpty(
                        icon: Icons.request_quote_outlined,
                        message: 'No quotes\nQuotes will appear here.',
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: quotes.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuoteCard(
                        quote: quotes[i],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuoteDetailScreen(
                                quoteId: quotes[i].id,
                                service: _service,
                              ),
                            ),
                          );
                          _reload();
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
          for (var i = 0; i < 5; i++) ...[
            AppSkeleton.box(context, height: 124, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onTap;
  const _QuoteCard({required this.quote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = quoteStatusColor(quote.status);
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(quote.documentNumber,
                  style: AppType.display(15, color: AppColors.textNavy(context))),
              StatusPill(label: quote.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            quote.clientName ?? quote.clientCompany ?? 'Unknown client',
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
                  Text(formatQuoteMoney(quote.total, quote.currency),
                      style: AppType.number(15, color: AppColors.textPrimary(context))),
                ],
              ),
              const Spacer(),
              if (quote.issueDate != null) ...[
                const Icon(Icons.event_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(formatDate(quote.issueDate), style: AppType.body(11, color: kMuted)),
                const SizedBox(width: 8),
              ],
              Text('View', style: AppType.body(11, color: ModuleAccent.finance.base, weight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, size: 14, color: ModuleAccent.finance.base),
            ],
          ),
        ],
      ),
    );
  }
}
