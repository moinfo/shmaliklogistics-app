import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/lease.dart';
import '../mod_re_leases_service.dart';
import 'leases_screen.dart' show moneyWithCurrency;

/// Read-only detail for a single lease (*mkataba*): terms, tenant, property,
/// contract status and the rent invoice ledger.
class LeaseDetailScreen extends StatefulWidget {
  final int leaseId;
  final ModReLeasesService service;

  /// The list-row summary, shown immediately while the full record loads.
  final LeaseRow? initial;

  const LeaseDetailScreen({
    super.key,
    required this.leaseId,
    required this.service,
    this.initial,
  });

  @override
  State<LeaseDetailScreen> createState() => _LeaseDetailScreenState();
}

class _LeaseDetailScreenState extends State<LeaseDetailScreen> {
  late Future<LeaseDetailPayload> _future;

  /// True while a contract upload is in flight (drives the button spinner).
  bool _uploadingContract = false;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchLease(widget.leaseId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchLease(widget.leaseId));

  /// Whether the current user may upload/replace the contract.
  bool get _canEdit => AppSession.instance.can('realestate_leases.edit');

  /// Maps a file extension to its MIME type, or null when unknown.
  String? _mimeForExtension(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
  }

  Future<void> _uploadContract() async {
    if (_uploadingContract) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: false,
      withReadStream: false,
    );
    final picked = result?.files.single;
    if (picked == null || picked.path == null) return; // cancelled

    setState(() => _uploadingContract = true);
    try {
      await widget.service.uploadContract(
        leaseId: widget.leaseId,
        filePath: picked.path!,
        mimeType: _mimeForExtension(picked.extension),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contract uploaded'),
          backgroundColor: kSuccess,
        ),
      );
      // Re-fetch so the card reflects has_contract + contract_uploaded_at.
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: kDanger),
      );
    } finally {
      if (mounted) setState(() => _uploadingContract = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeaseDetailPayload>(
      future: _future,
      builder: (context, snapshot) {
        final lease = snapshot.data?.lease;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _header(lease),
              Expanded(child: _body(snapshot)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header(LeaseDetail? lease) {
    return AppGradientHeader(
      eyebrow: 'Real Estate',
      title: lease?.leaseNumber ?? widget.initial?.leaseNumber ?? 'Lease',
      subtitle: lease?.statusLabel ?? widget.initial?.statusLabel,
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

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _body(AsyncSnapshot<LeaseDetailPayload> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        widget.initial == null) {
      return _skeleton();
    }
    if (snapshot.hasError && snapshot.data == null) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final payload = snapshot.data;
    final cycles = payload?.billingCycles ?? const <String, BillingCycle>{};
    final loading = snapshot.connectionState == ConnectionState.waiting;

    // Detail is required for the body; while loading without it, show skeleton.
    final lease = payload?.lease;
    if (lease == null) return _skeleton();

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _statusCard(lease)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _termsCard(lease, cycles)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _tenantCard(lease)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 180, child: _propertyCard(lease)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 240, child: _contractCard(lease)),
            if (lease.terms != null && lease.terms!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 280,
                child: _SectionCard(
                  title: 'Terms',
                  eyebrow: 'Agreement',
                  icon: Icons.gavel_rounded,
                  children: [Text(lease.terms!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
            const SizedBox(height: 18),
            RevealOnLoad(
              delayMs: 320,
              child: SectionHeader(
                title: 'Rent Invoices (${lease.invoices.length})',
                eyebrow: 'Ledger',
                icon: Icons.receipt_long_outlined,
                accent: ModuleAccent.finance,
              ),
            ),
            const SizedBox(height: 4),
            if (lease.invoices.isEmpty)
              RevealOnLoad(
                delayMs: 360,
                child: AppCard(
                  child: AppEmpty(
                    icon: Icons.receipt_long_outlined,
                    message: loading
                        ? 'Loading invoices…'
                        : 'No rent invoices for this lease.',
                  ),
                ),
              )
            else
              for (var i = 0; i < lease.invoices.length; i++) ...[
                RevealOnLoad(
                  delayMs: (360 + i * 50).clamp(0, 600),
                  child: _InvoiceCard(invoice: lease.invoices[i]),
                ),
                if (i != lease.invoices.length - 1) const SizedBox(height: 12),
              ],
            if (lease.notes != null && lease.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 420,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(lease.notes!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppSkeleton.box(context, height: 90, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 170, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 100, radius: 18),
        ],
      ),
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Widget _statusCard(LeaseDetail l) {
    final color = l.statusColor;
    return AppCard(
      accentColor: color,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.description_rounded, size: 26, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.leaseNumber,
                    style: AppType.number(20, color: AppColors.textNavy(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (l.propertyLabel != null && l.propertyLabel!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(l.propertyLabel!,
                      style: AppType.body(13, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                StatusPill(label: l.statusLabel, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsCard(LeaseDetail l, Map<String, BillingCycle> cycles) {
    final cycleLabel = cycles[l.billingCycle]?.label ?? l.billingCycle;
    return _SectionCard(
      title: 'Lease Terms',
      eyebrow: 'Agreement',
      icon: Icons.assignment_outlined,
      children: [
        _InfoRow(
          label: 'Rent',
          value: moneyWithCurrency(l.rentCurrency, l.rentAmount),
        ),
        if (cycleLabel != null && cycleLabel.isNotEmpty)
          _InfoRow(label: 'Billing cycle', value: cycleLabel),
        if (l.depositAmount != null)
          _InfoRow(
            label: 'Deposit',
            value: moneyWithCurrency(l.rentCurrency, l.depositAmount!),
          ),
        if (l.paymentDay != null)
          _InfoRow(label: 'Payment day', value: _ordinalDay(l.paymentDay!)),
        const Divider(height: 22),
        _InfoRow(
          label: 'Term',
          value: '${formatDate(l.startDate)} – ${formatDate(l.endDate)}',
        ),
      ],
    );
  }

  Widget _tenantCard(LeaseDetail l) {
    return _SectionCard(
      title: 'Tenant',
      eyebrow: 'Lessee',
      icon: Icons.person_outline_rounded,
      children: [
        _InfoRow(label: 'Name', value: l.tenantName ?? '—'),
        if (l.tenantPhone != null && l.tenantPhone!.isNotEmpty)
          _InfoRow(label: 'Phone', value: l.tenantPhone!),
      ],
    );
  }

  Widget _propertyCard(LeaseDetail l) {
    final label = (l.propertyLabel != null && l.propertyLabel!.isNotEmpty)
        ? l.propertyLabel!
        : (l.propertyName ?? '—');
    return _SectionCard(
      title: 'Property',
      eyebrow: 'Premises',
      icon: Icons.apartment_rounded,
      children: [
        _InfoRow(label: 'Property', value: label),
        if (l.unitNumber != null && l.unitNumber!.isNotEmpty)
          _InfoRow(label: 'Unit', value: l.unitNumber!),
      ],
    );
  }

  Widget _contractCard(LeaseDetail l) {
    final color = l.hasContract ? kSuccess : kMuted;
    return _SectionCard(
      title: 'Contract (mkataba)',
      eyebrow: 'Document',
      icon: Icons.folder_outlined,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(
                l.hasContract
                    ? Icons.task_outlined
                    : Icons.insert_drive_file_outlined,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.hasContract ? 'Contract on file' : 'No contract uploaded',
                    style: AppType.body(14,
                        weight: FontWeight.w700, color: color),
                  ),
                  if (l.hasContract && l.contractUploadedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Uploaded ${formatDate(l.contractUploadedAt)}',
                      style: AppType.body(12, color: kMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (_canEdit) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadingContract ? null : _uploadContract,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kPrimary.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _uploadingContract
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                _uploadingContract
                    ? 'Uploading…'
                    : (l.hasContract ? 'Replace Contract' : 'Upload Contract'),
                style: AppType.body(14, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// 1 → "1st of the month", 22 → "22nd of the month".
  static String _ordinalDay(int day) {
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$day$suffix of the month';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice card
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final LeaseInvoiceInfo invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final color = invoice.statusColor;
    final overdue = invoice.balanceDue > 0;
    final period =
        '${formatDate(invoice.periodStart)} – ${formatDate(invoice.periodEnd)}';

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
                    Text(invoice.invoiceNumber,
                        style: AppType.number(15,
                            color: AppColors.textNavy(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(period, style: AppType.body(12, color: kMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: invoice.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Text('Due ${formatDate(invoice.dueDate)}',
                  style: AppType.body(12, color: kMuted)),
              const Spacer(),
              Text(
                moneyWithCurrency(invoice.currency, invoice.amount),
                style: AppType.number(15, color: AppColors.textNavy(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Paid ${moneyWithCurrency(invoice.currency, invoice.amountPaid)}',
                style: AppType.body(12, color: kMuted, weight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text('·', style: AppType.body(12, color: kMuted)),
              const SizedBox(width: 8),
              Text(
                'Balance ${moneyWithCurrency(invoice.currency, invoice.balanceDue)}',
                style: AppType.body(12,
                    color: overdue ? kDanger : kMuted,
                    weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
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
              accent: ModuleAccent.brand),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label,
                style:
                    AppType.body(12.5, color: kMuted, weight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppType.body(13.5,
                  weight: FontWeight.w600,
                  color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}