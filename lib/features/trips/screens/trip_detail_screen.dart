import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/check_in.dart';
import '../../../core/models/trip.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../trip_service.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  final TripService service;

  const TripDetailScreen({
    super.key,
    required this.tripId,
    required this.service,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  final int _navIndex = 1;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchTrip(widget.tripId);
  }

  void _reload() => setState(() => _future = widget.service.fetchTrip(widget.tripId));

  Widget _buildHeader(Trip? trip) {
    return AppGradientHeader(
      eyebrow: 'Trip detail',
      title: trip?.tripNumber ?? 'Trip',
      gradient: ModuleAccent.ops.colors,
      subtitle: trip?.statusLabel,
      actions: [
        HeaderIconButton(
            icon: Icons.refresh_rounded, onTap: _reload, tooltip: 'Refresh'),
      ],
      trailing: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: HeaderIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
            tooltip: 'Back'),
      ),
    );
  }

  Widget _buildBottomNav() => const AppBottomNav(currentIndex: 1);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final trip = snapshot.data?['trip'] as Trip?;

        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(trip),
              Expanded(child: () {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeleton();
                }
                if (snapshot.hasError) {
                  return AppError(
                      message: snapshot.error.toString(), onRetry: _reload);
                }

                final t = trip!;
                final checkIns =
                    (snapshot.data!['checkIns'] as List<CheckIn>);
                final editable = t.status != 'completed' && t.status != 'cancelled';
                final costs = t.totalCosts ??
                    (t.fuelCost +
                        t.driverAllowance +
                        t.borderCosts +
                        t.roadFines +
                        t.guardFees);
                final profit = t.freightAmount - costs;

                final hasCargo =
                    t.cargoDescription != null && t.cargoDescription!.isNotEmpty;

                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RevealOnLoad(
                          delayMs: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Route',
                                eyebrow: 'Journey',
                                icon: Icons.alt_route_rounded,
                                accent: ModuleAccent.ops,
                              ),
                              _RouteCard(trip: t),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        RevealOnLoad(
                          delayMs: 70,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Costs & expenses',
                                eyebrow: 'Finance',
                                icon: Icons.account_balance_wallet_rounded,
                                accent: ModuleAccent.finance,
                              ),
                              AppCard(
                                child: Column(
                                  children: [
                                    _FinRow(label: 'Freight', value: formatCurrency(t.freightAmount), isHighlight: true),
                                    const _Divider(),
                                    _FinRow(label: 'Fuel cost',         value: formatCurrency(t.fuelCost)),
                                    _FinRow(label: 'Driver allowance',  value: formatCurrency(t.driverAllowance)),
                                    _FinRow(label: 'Border costs',      value: formatCurrency(t.borderCosts)),
                                    _FinRow(label: 'Road fines',        value: formatCurrency(t.roadFines)),
                                    _FinRow(label: 'Guard fees',        value: formatCurrency(t.guardFees)),
                                    const _Divider(),
                                    _FinRow(label: 'Total costs', value: formatCurrency(costs), isBold: true),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.isDark(context)
                                            ? (profit >= 0 ? kSuccess : kDanger).withValues(alpha: 0.15)
                                            : null,
                                        gradient: AppColors.isDark(context)
                                            ? null
                                            : LinearGradient(
                                                colors: profit >= 0
                                                    ? [const Color(0xFFDCFCE7), const Color(0xFFF0FDF4)]
                                                    : [const Color(0xFFFEE2E2), const Color(0xFFFFF5F5)],
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (profit >= 0 ? kSuccess : kDanger).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(children: [
                                            Icon(profit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                                size: 18, color: profit >= 0 ? kSuccess : kDanger),
                                            const SizedBox(width: 8),
                                            Text('Profit',
                                                style: AppType.body(14,
                                                    weight: FontWeight.w700,
                                                    color: AppColors.textPrimary(context))),
                                          ]),
                                          Text(
                                            formatCurrency(profit),
                                            style: AppType.number(15,
                                                color: profit >= 0 ? kSuccess : kDanger),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasCargo) ...[
                          const SizedBox(height: 18),
                          RevealOnLoad(
                            delayMs: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionHeader(
                                  title: 'Cargo',
                                  eyebrow: 'Manifest',
                                  icon: Icons.inventory_2_rounded,
                                  accent: ModuleAccent.ops,
                                ),
                                AppCard(
                                  child: Text(t.cargoDescription!,
                                      style: AppType.body(14,
                                          color: AppColors.textPrimary(context),
                                          height: 1.5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        RevealOnLoad(
                          delayMs: hasCargo ? 210 : 140,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: 'Check-ins (${checkIns.length})',
                                eyebrow: 'Notes',
                                icon: Icons.pin_drop_rounded,
                                accent: ModuleAccent.ops,
                              ),
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: checkIns.isEmpty
                                      ? [Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Text('No check-ins recorded yet.',
                                              style: AppType.body(14, color: kMuted)),
                                        )]
                                      : checkIns.take(10).map((c) => _CheckInTile(checkIn: c)).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (editable) ...[
                          const SizedBox(height: 22),
                          RevealOnLoad(
                            delayMs: hasCargo ? 280 : 210,
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final updated = await _showExpensesSheet(context, t);
                                  if (updated) _reload();
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: Text('Edit Expenses',
                                    style: AppType.body(15, weight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7A2800),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              }()),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          AppSkeleton.box(context, height: 22, width: 140, radius: 6),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 170, radius: 18),
          const SizedBox(height: 24),
          AppSkeleton.box(context, height: 22, width: 160, radius: 6),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 260, radius: 18),
          const SizedBox(height: 24),
          AppSkeleton.box(context, height: 22, width: 130, radius: 6),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 18),
        ],
      ),
    );
  }

  /// Shows the edit-expenses bottom sheet and returns true if data was saved.
  Future<bool> _showExpensesSheet(BuildContext context, Trip trip) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpensesSheet(trip: trip, service: widget.service),
    );
    return result == true;
  }
}

// ---------------------------------------------------------------------------
// Route card
// ---------------------------------------------------------------------------

class _RouteCard extends StatelessWidget {
  final Trip trip;
  const _RouteCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(trip.status);
    return AppCard(
      accentColor: color,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Align(
            alignment: Alignment.centerRight,
            child: StatusPill(label: trip.statusLabel, color: color),
          ),
          const SizedBox(height: 12),

          // Route
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FROM', style: AppType.eyebrow(size: 9.5, color: kMuted)),
                    const SizedBox(height: 3),
                    Text(
                      trip.routeFrom,
                      style: AppType.display(18, color: AppColors.textNavy(context)),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: kPrimary, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TO', style: AppType.eyebrow(size: 9.5, color: kMuted)),
                    const SizedBox(height: 3),
                    Text(
                      trip.routeTo,
                      style: AppType.display(18, color: AppColors.textNavy(context)),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dates row
          Row(
            children: [
              _DateChip(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'Departure',
                  value: formatDate(trip.departureDate)),
              const SizedBox(width: 12),
              _DateChip(
                  icon: Icons.flag_rounded,
                  label: 'Arrival',
                  value: formatDate(trip.arrivalDate)),
              if (trip.vehiclePlate != null) ...[
                const SizedBox(width: 12),
                _DateChip(
                    icon: Icons.directions_car_rounded,
                    label: 'Vehicle',
                    value: trip.vehiclePlate!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DateChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: kMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppType.body(10, color: kMuted, weight: FontWeight.w600)),
                  Text(value,
                      style: AppType.body(12,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary(context)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Financial row widgets
// ---------------------------------------------------------------------------

class _FinRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isHighlight;

  const _FinRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppType.body(13,
                color: isBold ? AppColors.textPrimary(context) : kMuted,
                weight: isBold ? FontWeight.w700 : FontWeight.w500),
          ),
          Text(
            value,
            style: AppType.number(13.5,
                weight: isBold || isHighlight ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight ? kPrimary : AppColors.textPrimary(context)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 14, thickness: 0.5);
}

// ---------------------------------------------------------------------------
// Check-in tile
// ---------------------------------------------------------------------------

class _CheckInTile extends StatelessWidget {
  final CheckIn checkIn;
  const _CheckInTile({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(checkIn.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(label: checkIn.statusLabel, color: color),
                    const Spacer(),
                    Text(
                      formatDateTime(checkIn.checkedInAt),
                      style: AppType.body(11, color: kMuted),
                    ),
                  ],
                ),
                if (checkIn.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 12, color: kMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          checkIn.location!,
                          style: AppType.body(12, color: kMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (checkIn.notes != null &&
                    checkIn.notes!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    checkIn.notes!,
                    style: AppType.body(12, color: kMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit expenses bottom sheet
// ---------------------------------------------------------------------------

class _ExpensesSheet extends StatefulWidget {
  final Trip trip;
  final TripService service;

  const _ExpensesSheet({required this.trip, required this.service});

  @override
  State<_ExpensesSheet> createState() => _ExpensesSheetState();
}

class _ExpensesSheetState extends State<_ExpensesSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roadFinesCtrl;
  late final TextEditingController _guardFeesCtrl;
  late final TextEditingController _borderCostsCtrl;
  late final TextEditingController _otherCostsCtrl;
  late final TextEditingController _notesCtrl;
  bool _saving = false;
  String? _pickedFilePath;
  String? _pickedFileName;
  String? _pickedMimeType;
  bool _uploadingReceipt = false;

  @override
  void initState() {
    super.initState();
    _roadFinesCtrl =
        TextEditingController(text: widget.trip.roadFines.toStringAsFixed(0));
    _guardFeesCtrl =
        TextEditingController(text: widget.trip.guardFees.toStringAsFixed(0));
    _borderCostsCtrl =
        TextEditingController(text: widget.trip.borderCosts.toStringAsFixed(0));
    _otherCostsCtrl =
        TextEditingController(text: widget.trip.otherCosts.toStringAsFixed(0));
    _notesCtrl = TextEditingController(text: widget.trip.notes ?? '');
  }

  @override
  void dispose() {
    _roadFinesCtrl.dispose();
    _guardFeesCtrl.dispose();
    _borderCostsCtrl.dispose();
    _otherCostsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await widget.service.updateExpenses(
        widget.trip.id,
        roadFines: double.tryParse(_roadFinesCtrl.text) ?? 0,
        guardFees: double.tryParse(_guardFeesCtrl.text) ?? 0,
        borderCosts: double.tryParse(_borderCostsCtrl.text) ?? 0,
        otherCosts: double.tryParse(_otherCostsCtrl.text) ?? 0,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      // Upload receipt if a file was picked
      if (_pickedFilePath != null) {
        setState(() => _uploadingReceipt = true);
        try {
          await widget.service.uploadExpenseReceipt(
              widget.trip.id, _pickedFilePath!, _pickedMimeType ?? 'application/octet-stream');
        } catch (_) {} // non-fatal: expenses saved, receipt upload is best-effort
        if (mounted) setState(() => _uploadingReceipt = false);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: kDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: false,
      withReadStream: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFilePath = result.files.single.path;
        _pickedFileName = result.files.single.name;
        final ext = result.files.single.extension?.toLowerCase() ?? '';
        _pickedMimeType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Edit Expenses',
              style: AppType.display(19, color: AppColors.textNavy(context)),
            ),
            const SizedBox(height: 4),
            Text(
              widget.trip.tripNumber,
              style: AppType.number(13, color: kMuted),
            ),
            const SizedBox(height: 20),

            _NumField(
              controller: _roadFinesCtrl,
              label: 'Road Fines (TZS)',
              hint: '0',
            ),
            const SizedBox(height: 12),
            _NumField(
              controller: _guardFeesCtrl,
              label: 'Guard Fees (TZS)',
              hint: '0',
            ),
            const SizedBox(height: 12),
            _NumField(
              controller: _borderCostsCtrl,
              label: 'Border Costs (TZS)',
              hint: '0',
            ),
            const SizedBox(height: 12),
            _NumField(
              controller: _otherCostsCtrl,
              label: 'Other Costs (TZS)',
              hint: '0',
            ),
            const SizedBox(height: 12),

            // Notes field
            TextFormField(
              controller: _notesCtrl,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional remarks...',
                filled: true,
                fillColor: AppColors.surfaceVariant(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            // Receipt attachment
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing receipt from server
                  if (widget.trip.expenseReceiptUrl != null && _pickedFilePath == null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file_rounded, size: 16, color: kMuted),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Receipt attached', style: AppType.body(13, color: kMuted))),
                          TextButton(
                            onPressed: _pickFile,
                            child: Text('Replace', style: AppType.body(12, color: kPrimary, weight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    )
                  // Newly picked file
                  else if (_pickedFilePath != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16, color: kSuccess),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_pickedFileName ?? 'File selected', overflow: TextOverflow.ellipsis, style: AppType.body(13, color: kMuted))),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: kMuted),
                            onPressed: () => setState(() { _pickedFilePath = null; _pickedFileName = null; }),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )
                  // No receipt yet
                  else
                    InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload_file_rounded, size: 20, color: kMuted),
                            const SizedBox(width: 8),
                            Text('Attach Receipt / Document', style: AppType.body(14, color: kMuted, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_saving || _uploadingReceipt) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kPrimary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppType.body(15, weight: FontWeight.w700),
                ),
                child: (_saving || _uploadingReceipt)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Expenses'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _NumField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (v) {
        if (v == null || v.isEmpty) return null; // allow empty (treated as 0)
        if (double.tryParse(v) == null) return 'Enter a valid number';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceVariant(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
