import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/check_in.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/ui/typography.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Date formatting helpers (no intl package)
// ---------------------------------------------------------------------------

const _monthAbbr = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Formats as "dd MMM yyyy · HH:mm"
String _fmtDateTime(DateTime dt) {
  final d = dt.toLocal();
  return '${_pad2(d.day)} ${_monthAbbr[d.month]} ${d.year} · ${_pad2(d.hour)}:${_pad2(d.minute)}';
}

/// Formats an integer odometer value as "123,456 km"
String _fmtOdometer(int km) {
  final s = km.toString();
  final buf = StringBuffer();
  final offset = s.length % 3;
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (i - offset) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${buf.toString()} km';
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CheckInHistoryScreen extends StatefulWidget {
  final ApiClient apiClient;

  const CheckInHistoryScreen({super.key, required this.apiClient});

  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  List<CheckIn> _checkIns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // -------------------------------------------------------------------------
  // Data
  // -------------------------------------------------------------------------

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await widget.apiClient.get('/driver/check-ins');
      final envelope = json['check_ins'];
      final dataList = (envelope != null ? envelope['data'] as List? : null) ?? [];
      final checkIns = dataList
          .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _checkIns = checkIns;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load check-in history. Please try again.';
        _loading = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Build helpers
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return AppGradientHeader(
      eyebrow: 'Check-in',
      title: 'History',
      subtitle: 'Your past check-in records',
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        if (!_loading) ...[
          const SizedBox(width: 8),
          HeaderIconButton(
            icon: Icons.refresh_rounded,
            onTap: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildSkeleton();
    }

    if (_error != null) {
      return AppError(message: _error!, onRetry: _loadHistory);
    }

    if (_checkIns.isEmpty) {
      return const AppEmpty(
        icon: Icons.history_toggle_off_rounded,
        message:
            'No check-ins yet.\nYour records will appear here once you submit your first check-in.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _checkIns.length,
      itemBuilder: (context, index) => RevealOnLoad(
        delayMs: (index * 60).clamp(0, 300),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CheckInCard(checkIn: _checkIns[index]),
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
          for (var i = 0; i < 5; i++) ...[
            AppSkeleton.box(context, height: 96, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Main build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check-in card
// ---------------------------------------------------------------------------

class _CheckInCard extends StatelessWidget {
  final CheckIn checkIn;

  const _CheckInCard({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(checkIn.status);

    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Row 1: status badge + timestamp ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusPill(label: checkIn.statusLabel, color: color),
              const Spacer(),
              // Timestamp
              Text(
                _fmtDateTime(checkIn.checkedInAt),
                style: AppType.body(11, color: kMuted),
              ),
            ],
          ),

          // ---- Trip number + route ----
          if (checkIn.tripNumber != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_shipping_rounded,
                    size: 15, color: kMuted),
                const SizedBox(width: 6),
                Text(
                  checkIn.tripNumber!,
                  style: AppType.body(14,
                      weight: FontWeight.w700,
                      color: AppColors.textNavy(context)),
                ),
                if (checkIn.routeFrom != null && checkIn.routeTo != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${checkIn.routeFrom} → ${checkIn.routeTo}',
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body(12,
                          color: kMuted, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ],

          // ---- Divider ----
          if (checkIn.location != null ||
              checkIn.odometerKm != null ||
              checkIn.notes != null) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.border(context), height: 1),
            const SizedBox(height: 10),
          ],

            // ---- Location ----
            if (checkIn.location != null)
              _DetailRow(
                icon: Icons.place_rounded,
                text: checkIn.location!,
              ),

            // ---- Odometer ----
            if (checkIn.odometerKm != null) ...[
              if (checkIn.location != null) const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.speed_rounded,
                text: _fmtOdometer(checkIn.odometerKm!),
              ),
            ],

            // ---- Notes ----
            if (checkIn.notes != null) ...[
              if (checkIn.location != null || checkIn.odometerKm != null)
                const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.notes_rounded,
                text: checkIn.notes!,
                maxLines: 2,
              ),
            ],
          ],
        ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small detail row (icon + text)
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _DetailRow({
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: kMuted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppType.body(12, color: kMuted),
          ),
        ),
      ],
    );
  }
}
