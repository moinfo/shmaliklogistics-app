import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../documents_service.dart';
import '../models/document.dart';

/// Documents library — read-only feed of the staff document store.
///
/// Lists [AppCard]s (title, related-type [StatusPill], a file icon and a size /
/// uploaded-date footer). Tapping a card opens a metadata bottom sheet. Includes
/// a search box and related-type filter chips.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late final DocumentsService _service;

  List<StaffDocument>? _documents;
  bool _loading = true;
  String? _error;

  String _typeFilter = 'all';
  String _search = '';
  final _searchController = TextEditingController();

  static const _typeFilters = [
    ('all', 'All'),
    ('trip', 'Trips'),
    ('vehicle', 'Vehicles'),
    ('driver', 'Drivers'),
  ];

  @override
  void initState() {
    super.initState();
    _service = DocumentsService(widget.apiClient);
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
      final docs = await _service.fetchDocuments();
      if (mounted) setState(() => _documents = docs);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load documents.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<StaffDocument> get _filtered {
    final all = _documents ?? [];
    final q = _search.trim().toLowerCase();
    return all.where((d) {
      final matchesType = _typeFilter == 'all' || d.type == _typeFilter;
      final matchesSearch = q.isEmpty ||
          d.title.toLowerCase().contains(q) ||
          (d.fileName?.toLowerCase().contains(q) ?? false) ||
          (d.relatedName?.toLowerCase().contains(q) ?? false);
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Files',
            title: 'Documents',
            subtitle: _documents != null
                ? '${_documents!.length} on file'
                : 'Trip · vehicle · driver records',
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _load,
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
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search title, file or record…',
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

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _typeFilters.map((f) {
            final (value, label) = f;
            final selected = _typeFilter == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _typeFilter = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? kPrimary : AppColors.chipUnselected(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? kPrimary : AppColors.border(context),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppType.body(12,
                        weight: FontWeight.w600,
                        color: selected ? Colors.white : kMuted),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) {
      return _wrapScroll(AppError(message: _error!, onRetry: _load));
    }

    final docs = _filtered;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _load,
      child: docs.isEmpty
          ? _wrapScroll(
              AppEmpty(
                icon: Icons.folder_open_rounded,
                message: (_documents?.isEmpty ?? true)
                    ? 'No documents yet. Uploaded files will appear here.'
                    : 'No documents match your filter.',
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              itemCount: docs.length,
              itemBuilder: (_, i) => RevealOnLoad(
                delayMs: (i * 60).clamp(0, 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DocumentCard(
                    document: docs[i],
                    onTap: () => _showDetail(docs[i]),
                  ),
                ),
              ),
            ),
    );
  }

  void _showDetail(StaffDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DocumentSheet(document: doc),
    );
  }

  Widget _wrapScroll(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: child,
        ),
      ],
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
              child: AppSkeleton.box(context, height: 92, radius: 16),
            ),
        ],
      ),
    );
  }
}

// ── Document type → colour / file icon helpers ───────────────────────────────

Color _typeColor(String? type) {
  switch (type) {
    case 'trip':
      return const Color(0xFF3B82F6);
    case 'vehicle':
      return const Color(0xFF0E9F6E);
    case 'driver':
      return const Color(0xFFEA580C);
    default:
      return kMuted;
  }
}

IconData _fileIcon(StaffDocument doc) {
  final mime = doc.mimeType ?? '';
  final ext = doc.extension ?? '';
  if (mime.contains('pdf') || ext == 'PDF') return Icons.picture_as_pdf_rounded;
  if (mime.startsWith('image/') || ['JPG', 'JPEG', 'PNG'].contains(ext)) {
    return Icons.image_rounded;
  }
  if (mime.contains('sheet') || ['XLS', 'XLSX', 'CSV'].contains(ext)) {
    return Icons.table_chart_rounded;
  }
  if (mime.contains('word') || ['DOC', 'DOCX'].contains(ext)) {
    return Icons.description_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

// ── Document card ────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final StaffDocument document;
  final VoidCallback onTap;
  const _DocumentCard({required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(document.type);

    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_fileIcon(document), size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        style: AppType.display(14, color: AppColors.textNavy(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(label: document.typeLabel, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                if (document.relatedName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 13, color: kMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          document.relatedName!,
                          style: AppType.body(12, color: kMuted, weight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    if (document.extension != null) ...[
                      Text(document.extension!,
                          style: AppType.body(10.5,
                              weight: FontWeight.w700, color: color)),
                      const SizedBox(width: 8),
                    ],
                    if (document.fileSizeHuman != null) ...[
                      const Icon(Icons.sd_storage_outlined, size: 12, color: kMuted),
                      const SizedBox(width: 3),
                      Text(document.fileSizeHuman!,
                          style: AppType.body(11, color: kMuted)),
                    ],
                    const Spacer(),
                    if (document.uploadedAt != null)
                      Text(formatDate(document.uploadedAt),
                          style: AppType.body(11, color: kMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail bottom sheet ──────────────────────────────────────────────────────

class _DocumentSheet extends StatelessWidget {
  final StaffDocument document;
  const _DocumentSheet({required this.document});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(document.type);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_fileIcon(document), size: 26, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(document.title,
                          style: AppType.display(18, color: AppColors.textNavy(context))),
                      const SizedBox(height: 4),
                      StatusPill(label: document.typeLabel, color: color),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MetaRow(label: 'File', value: document.fileName ?? '—'),
            if (document.extension != null)
              _MetaRow(label: 'Format', value: document.extension!),
            if (document.fileSizeHuman != null)
              _MetaRow(label: 'Size', value: document.fileSizeHuman!),
            if (document.relatedName != null)
              _MetaRow(
                  label: document.typeLabel,
                  value: document.relatedName!),
            _MetaRow(
              label: 'Uploaded',
              value: document.uploadedAt != null
                  ? formatDateTime(document.uploadedAt!)
                  : '—',
            ),
            if (document.hasNotes) ...[
              const SizedBox(height: 8),
              Text('Notes',
                  style: AppType.eyebrow(color: kMuted)),
              const SizedBox(height: 4),
              Text(document.notes!,
                  style: AppType.body(13.5, color: AppColors.textPrimary(context))),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: AppType.body(12.5, color: kMuted, weight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: AppType.body(13.5,
                    color: AppColors.textPrimary(context), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
