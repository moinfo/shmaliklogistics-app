import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../reference_service.dart';

/// Generic read-only list backed by `ReferenceController` — used for HR
/// Allowances, Notifications and every Settings menu. Shows summary counts, a
/// search box, one card per row and a detail sheet with all of the row's fields.
class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({
    super.key,
    required this.apiClient,
    required this.title,
    required this.eyebrow,
    required this.path,
    this.icon = Icons.list_alt_rounded,
  });

  final ApiClient apiClient;
  final String title;
  final String eyebrow;

  /// API path relative to the base URL, e.g. `/staff/modules/settings/roles`.
  final String path;
  final IconData icon;

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  late final ReferenceService _service;

  RefList? _data;
  bool _loading = true;
  String? _error;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = ReferenceService(widget.apiClient);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetch(widget.path);
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load ${widget.title.toLowerCase()}.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RefItem> get _filtered {
    final all = _data?.items ?? const <RefItem>[];
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((i) {
      return i.title.toLowerCase().contains(q) ||
          (i.subtitle?.toLowerCase().contains(q) ?? false) ||
          i.fields.any((f) => f.value.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final count = _data?.items.length;
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: widget.eyebrow,
            title: widget.title,
            subtitle: count != null ? '$count record${count == 1 ? '' : 's'}' : 'Loading…',
            actions: [
              HeaderIconButton(icon: Icons.refresh_rounded, onTap: _load, tooltip: 'Refresh'),
            ],
          ),
          if ((_data?.items.length ?? 0) > 6) _buildSearchBar(),
          if ((_data?.summary ?? const []).isNotEmpty) _buildSummary(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search ${widget.title.toLowerCase()}…',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: kMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
          filled: true,
          fillColor: AppColors.surfaceVariant(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: _border(AppColors.border(context)),
          enabledBorder: _border(AppColors.border(context)),
          focusedBorder: _border(kPrimary, width: 1.5),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _buildSummary() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in _data!.summary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.chipUnselected(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                  text: '${s.value}  ',
                  style: AppType.body(13, weight: FontWeight.w700, color: AppColors.textPrimary(context)),
                ),
                TextSpan(text: s.label, style: AppType.body(12, color: kMuted)),
              ])),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _wrapScroll(AppError(message: _error!, onRetry: _load));

    final rows = _filtered;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _load,
      child: rows.isEmpty
          ? _wrapScroll(AppEmpty(
              icon: widget.icon,
              message: (_data?.items.isEmpty ?? true)
                  ? 'No ${widget.title.toLowerCase()} yet.'
                  : 'Nothing matches your search.',
            ))
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              itemCount: rows.length,
              itemBuilder: (_, i) => RevealOnLoad(
                delayMs: (i * 40).clamp(0, 240),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RefCard(item: rows[i], onTap: () => _showDetail(rows[i])),
                ),
              ),
            ),
    );
  }

  void _showDetail(RefItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RefSheet(item: item),
    );
  }

  Widget _wrapScroll(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [SizedBox(height: MediaQuery.of(context).size.height * 0.45, child: child)],
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSkeleton.box(context, height: 84, radius: 16),
            ),
        ],
      ),
    );
  }
}

Color _toneColor(String? tone) {
  switch (tone) {
    case 'success':
      return const Color(0xFF0E9F6E);
    case 'warning':
      return const Color(0xFFF59E0B);
    case 'danger':
      return const Color(0xFFEF4444);
    case 'info':
      return const Color(0xFF3B82F6);
    default:
      return kMuted;
  }
}

class _RefCard extends StatelessWidget {
  final RefItem item;
  final VoidCallback onTap;
  const _RefCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(item.badgeTone);
    final preview = item.fields.take(2).toList();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body(14.5,
                          weight: FontWeight.w700, color: AppColors.textPrimary(context)),
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body(12.5, color: kMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.badge != null && item.badge!.isNotEmpty) ...[
                const SizedBox(width: 10),
                StatusPill(label: item.badge!.toUpperCase(), color: color),
              ],
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final f in preview)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${f.label}: ', style: AppType.body(12, color: kMuted)),
                    TextSpan(
                      text: f.value,
                      style: AppType.body(12,
                          weight: FontWeight.w600, color: AppColors.textPrimary(context)),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RefSheet extends StatelessWidget {
  final RefItem item;
  const _RefSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: AppType.display(18, color: AppColors.textPrimary(context)),
                  ),
                ),
                if (item.badge != null && item.badge!.isNotEmpty)
                  StatusPill(label: item.badge!.toUpperCase(), color: _toneColor(item.badgeTone)),
              ],
            ),
            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.subtitle!, style: AppType.body(13, color: kMuted)),
            ],
            const SizedBox(height: 16),
            if (item.fields.isEmpty)
              Text('No further details.', style: AppType.body(13, color: kMuted))
            else
              for (final f in item.fields)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.label, style: AppType.body(11.5, color: kMuted)),
                      const SizedBox(height: 2),
                      SelectableText(
                        f.value,
                        style: AppType.body(14,
                            weight: FontWeight.w600, color: AppColors.textPrimary(context)),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
