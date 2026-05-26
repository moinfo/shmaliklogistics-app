import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/quote_request.dart';
import '../quote_requests_service.dart';
import 'quote_request_detail_screen.dart';

/// Staff · Quote Requests module entry point. A polished, searchable +
/// status-filterable list of client portal leads, with tap-through detail.
/// Read-only.
class QuoteRequestsScreen extends StatefulWidget {
  const QuoteRequestsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<QuoteRequestsScreen> createState() => _QuoteRequestsScreenState();
}

class _QuoteRequestsScreenState extends State<QuoteRequestsScreen> {
  late final QuoteRequestsService _service;
  late Future<List<QuoteRequest>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  // Mirrors PortalQuoteRequest::$statuses order on the backend.
  static const _statusFilters = <(String, String)>[
    ('all', 'All'),
    ('pending', 'Pending'),
    ('reviewed', 'Reviewed'),
    ('quoted', 'Quoted'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _service = QuoteRequestsService(widget.apiClient);
    _future = _service.fetchQuoteRequests();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = _service.fetchQuoteRequests());
  }

  List<QuoteRequest> _apply(List<QuoteRequest> items) {
    final q = _query.trim().toLowerCase();
    return items.where((r) {
      if (_statusFilter != 'all' && r.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return r.displayClient.toLowerCase().contains(q) ||
          r.routeFrom.toLowerCase().contains(q) ||
          r.routeTo.toLowerCase().contains(q) ||
          (r.cargoDescription ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Leads',
            title: 'Quote Requests',
            subtitle: 'Client portal enquiries',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildSearch(),
          _buildStatusFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Search client, route or cargo…',
          hintStyle: AppType.body(14, color: kMuted),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
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
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = _statusFilters[i];
          final selected = _statusFilter == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _statusFilter = value),
            showCheckmark: false,
            labelStyle: AppType.body(
              12.5,
              weight: FontWeight.w700,
              color: selected ? Colors.white : kMuted,
            ),
            backgroundColor: AppColors.surface(context),
            selectedColor: kPrimary,
            side: BorderSide(
              color: selected ? kPrimary : AppColors.border(context),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<QuoteRequest>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _reload);
        }

        final all = snapshot.data ?? [];
        final items = _apply(all);

        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _reload(),
          child: items.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.42,
                      child: AppEmpty(
                        icon: Icons.request_quote_outlined,
                        message: all.isEmpty
                            ? 'No quote requests\nClient enquiries will appear here.'
                            : 'No matches\nTry a different search or filter.',
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuoteRequestCard(
                        request: items[i],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuoteRequestDetailScreen(
                                requestId: items[i].id,
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 122, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _QuoteRequestCard extends StatelessWidget {
  final QuoteRequest request;
  final VoidCallback onTap;
  const _QuoteRequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(request.statusColorValue);
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.displayClient,
                  style: AppType.display(15.5, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: request.statusLabel, color: color),
            ],
          ),
          if (request.clientCompany != null &&
              request.clientCompany != request.clientName) ...[
            const SizedBox(height: 2),
            Text(
              request.clientCompany!,
              style: AppType.body(12, color: kMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.route_rounded, size: 14, color: kMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request.route,
                  style: AppType.body(13,
                      weight: FontWeight.w600,
                      color: AppColors.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (request.cargoDescription != null &&
              request.cargoDescription!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 13, color: kMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.cargoDescription!,
                    style: AppType.body(12, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 12, color: kMuted),
              const SizedBox(width: 4),
              Text(
                request.createdAt != null
                    ? timeAgo(request.createdAt!)
                    : '—',
                style: AppType.body(11, color: kMuted),
              ),
              const Spacer(),
              Text('View',
                  style: AppType.body(11, color: kPrimary, weight: FontWeight.w600)),
              const Icon(Icons.chevron_right_rounded, size: 14, color: kPrimary),
            ],
          ),
        ],
      ),
    );
  }
}
