import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/quote_request.dart';
import '../quote_requests_service.dart';

/// Read-only detail for a single client portal quote request.
class QuoteRequestDetailScreen extends StatefulWidget {
  final int requestId;
  final QuoteRequestsService service;

  const QuoteRequestDetailScreen({
    super.key,
    required this.requestId,
    required this.service,
  });

  @override
  State<QuoteRequestDetailScreen> createState() =>
      _QuoteRequestDetailScreenState();
}

class _QuoteRequestDetailScreenState extends State<QuoteRequestDetailScreen> {
  late Future<QuoteRequest> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchQuoteRequest(widget.requestId);
  }

  void _reload() => setState(
      () => _future = widget.service.fetchQuoteRequest(widget.requestId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuoteRequest>(
      future: _future,
      builder: (context, snapshot) {
        final req = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(req),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(QuoteRequest? req) {
    return AppGradientHeader(
      eyebrow: 'Lead',
      title: req?.displayClient ?? 'Quote Request',
      subtitle: req != null ? req.route : null,
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

  Widget _buildBody(AsyncSnapshot<QuoteRequest> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final req = snapshot.data!;
    final color = Color(req.statusColorValue);

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildStatusCard(req, color)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _buildClientCard(req)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _buildRouteCargoCard(req)),
            if (req.notes != null && req.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 180,
                child: _SectionCard(
                  title: 'Client Notes',
                  eyebrow: 'Enquiry',
                  icon: Icons.chat_bubble_outline_rounded,
                  children: [
                    Text(req.notes!, style: AppType.body(14, height: 1.5)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 240, child: _buildReviewCard(req)),
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
          AppSkeleton.box(context, height: 90, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 150, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 160, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 16),
        ],
      ),
    );
  }

  Widget _buildStatusCard(QuoteRequest req, Color color) {
    return AppCard(
      accentColor: color,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.request_quote_rounded, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status',
                    style: AppType.body(11, color: kMuted, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                StatusPill(label: req.statusLabel, color: color),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Submitted',
                  style: AppType.body(11, color: kMuted, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                req.createdAt != null ? formatDate(req.createdAt) : '—',
                style: AppType.body(13,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(QuoteRequest req) {
    return _SectionCard(
      title: 'Client',
      eyebrow: 'Requested by',
      icon: Icons.business_rounded,
      children: [
        Text(req.displayClient,
            style: AppType.display(16, color: AppColors.textPrimary(context))),
        if (req.clientCompany != null &&
            req.clientCompany != req.clientName) ...[
          const SizedBox(height: 2),
          Text(req.clientCompany!, style: AppType.body(13, color: kMuted)),
        ],
        if (req.clientEmail != null && req.clientEmail!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _IconLine(icon: Icons.email_outlined, text: req.clientEmail!),
        ],
        if (req.clientPhone != null && req.clientPhone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _IconLine(icon: Icons.phone_outlined, text: req.clientPhone!),
        ],
      ],
    );
  }

  Widget _buildRouteCargoCard(QuoteRequest req) {
    return _SectionCard(
      title: 'Route & Cargo',
      eyebrow: 'Requirements',
      icon: Icons.local_shipping_outlined,
      children: [
        _DetailRow(label: 'From', value: req.routeFrom),
        _DetailRow(label: 'To', value: req.routeTo),
        const Divider(height: 18),
        if (req.cargoDescription != null && req.cargoDescription!.isNotEmpty)
          _DetailRow(label: 'Cargo', value: req.cargoDescription!),
        if (req.hasWeight)
          _DetailRow(
            label: 'Weight',
            value: '${req.cargoWeightKg!.toStringAsFixed(req.cargoWeightKg! == req.cargoWeightKg!.roundToDouble() ? 0 : 2)} kg',
          ),
        if (req.hasVolume)
          _DetailRow(label: 'Volume', value: '${req.cargoVolumeM3} m³'),
        if (req.preferredDate != null)
          _DetailRow(
              label: 'Preferred date', value: formatDate(req.preferredDate)),
      ],
    );
  }

  Widget _buildReviewCard(QuoteRequest req) {
    final hasNotes = req.staffNotes != null && req.staffNotes!.isNotEmpty;
    return _SectionCard(
      title: 'Internal Review',
      eyebrow: 'Staff',
      icon: Icons.assignment_outlined,
      children: [
        _DetailRow(
          label: 'Reviewed by',
          value: req.reviewerName ?? 'Not yet reviewed',
        ),
        const SizedBox(height: 6),
        Text('Staff notes',
            style: AppType.body(11, color: kMuted, weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          hasNotes ? req.staffNotes! : 'No internal notes recorded.',
          style: AppType.body(14,
              height: 1.5,
              color: hasNotes ? AppColors.textPrimary(context) : kMuted),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared detail widgets
// ─────────────────────────────────────────────────────────────────────────────

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
              accent: ModuleAccent.finance),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppType.body(13, color: kMuted, weight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: AppType.body(13,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary(context))),
          ),
        ],
      ),
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
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppType.body(12, color: kMuted))),
      ],
    );
  }
}
