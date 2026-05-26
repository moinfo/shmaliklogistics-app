import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../models/client.dart';
import '../clients_service.dart';
import 'client_detail_screen.dart';

/// Module 3 — Clients. A polished, searchable list of customer cards that
/// taps through to a read-only detail screen. Wired into the app drawer by the
/// orchestrator via the [ClientsScreen] entry class.
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late final ClientsService _service;
  late Future<List<Client>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statusFilter; // null == all

  @override
  void initState() {
    super.initState();
    _service = ClientsService(widget.apiClient);
    _future = _service.fetchClients();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchClients());

  List<Client> _applyFilters(List<Client> clients) {
    return clients.where((c) {
      if (_statusFilter != null && c.status != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final hay = [
        c.name,
        c.companyName ?? '',
        c.email ?? '',
        c.phone ?? '',
        c.tinNumber ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Customers',
            title: 'Clients',
            subtitle: 'Directory · contacts · tax details',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<Client>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(message: snapshot.error.toString(), onRetry: _reload);
                }
                final all = snapshot.data ?? const <Client>[];
                final filtered = _applyFilters(all);
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _searchBar()),
                      SliverToBoxAdapter(child: _statusChips(all)),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmpty(
                            icon: Icons.people_outline_rounded,
                            message: all.isEmpty
                                ? 'No clients registered yet.'
                                : 'No clients match your search.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => RevealOnLoad(
                              delayMs: (i * 60).clamp(0, 300),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ClientCard(
                                  client: filtered[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ClientDetailScreen(
                                        clientId: filtered[i].id,
                                        service: _service,
                                        initial: filtered[i],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Search field ──────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Search name, company, email, TIN…',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: kMuted),
                  onPressed: () => _searchCtrl.clear(),
                ),
          filled: true,
          fillColor: AppColors.surface(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  // ── Status filter chips ─────────────────────────────────────────────────────

  Widget _statusChips(List<Client> clients) {
    final present = <String, String>{};
    for (final c in clients) {
      present.putIfAbsent(c.status, () => c.statusLabel);
    }
    if (present.isEmpty) return const SizedBox.shrink();

    final entries = present.entries.toList();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        children: [
          _chip('All', _statusFilter == null, () => setState(() => _statusFilter = null)),
          for (final e in entries)
            _chip(
              e.value,
              _statusFilter == e.key,
              () => setState(() => _statusFilter = e.key),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: AppType.body(
          12.5,
          weight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textPrimary(context),
        ),
        selectedColor: kPrimary,
        backgroundColor: AppColors.surface(context),
        showCheckmark: false,
        side: BorderSide(color: selected ? kPrimary : AppColors.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _skeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          AppSkeleton.box(context, height: 48, radius: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 104, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client list card
// ─────────────────────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  const _ClientCard({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = client.statusColor;
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(context, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: AppType.display(15.5, color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (client.hasCompany) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.companyName!,
                        style: AppType.body(12, color: kMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: client.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (client.phone != null && client.phone!.isNotEmpty) ...[
                const Icon(Icons.phone_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    client.phone!,
                    style: AppType.body(12, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (client.email != null && client.email!.isNotEmpty) ...[
                const Icon(Icons.email_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    client.email!,
                    style: AppType.body(12, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 18, color: kMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context, Color color) {
    final source = client.hasCompany ? client.companyName! : client.name;
    final initials = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: AppType.number(14, color: color),
      ),
    );
  }
}
