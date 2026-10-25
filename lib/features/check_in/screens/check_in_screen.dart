import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/trip.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/ui/typography.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../check_in_service.dart';

// ---------------------------------------------------------------------------
// Status option descriptor
// ---------------------------------------------------------------------------

class _StatusOption {
  final String value;
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatusOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

const _statusOptions = [
  _StatusOption(value: 'ok',        label: 'All Good',   subtitle: 'Everything is on track',          color: kSuccess, icon: Icons.check_circle_rounded),
  _StatusOption(value: 'issue',     label: 'Issue',      subtitle: 'Minor problem, can continue',      color: kWarning, icon: Icons.warning_rounded),
  _StatusOption(value: 'emergency', label: 'Emergency',  subtitle: 'Urgent — needs immediate help',    color: kDanger,  icon: Icons.emergency_rounded),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CheckInScreen extends StatefulWidget {
  final ApiClient apiClient;
  final Trip? initialTrip;

  const CheckInScreen({super.key, required this.apiClient, this.initialTrip});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late final CheckInService _service;
  final int _navIndex = 2;

  List<Trip> _trips = [];
  Trip? _selectedTrip;
  String _selectedStatus = 'ok';
  double? _lat;
  double? _lng;
  bool _fetchingLocation = false;
  bool _loadingTrips = true;
  bool _submitting = false;
  String? _tripsError;

  final _locationCtrl  = TextEditingController();
  final _odometerCtrl  = TextEditingController();
  final _notesCtrl     = TextEditingController();
  final _formKey       = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _service = CheckInService(widget.apiClient);
    _selectedTrip = widget.initialTrip;
    _loadTrips();
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _odometerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------

  Future<void> _loadTrips() async {
    setState(() { _loadingTrips = true; _tripsError = null; });
    try {
      final trips = await _service.fetchActiveTrips();
      setState(() {
        _trips = trips;
        _loadingTrips = false;
        if (_selectedTrip != null) {
          final match = trips.where((t) => t.id == _selectedTrip!.id);
          _selectedTrip = match.isNotEmpty ? match.first : (trips.isNotEmpty ? trips.first : null);
        } else if (trips.isNotEmpty) {
          _selectedTrip = trips.first;
        }
      });
    } catch (e) {
      setState(() { _tripsError = e.toString(); _loadingTrips = false; });
    }
  }

  // -------------------------------------------------------------------------
  // GPS
  // -------------------------------------------------------------------------

  Future<void> _getLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { _showError('Location services are disabled. Please enable GPS.'); return; }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { _showError('Location permission denied.'); return; }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission is permanently denied. Enable it in Settings.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        if (_locationCtrl.text.isEmpty) {
          _locationCtrl.text = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        }
      });
    } catch (e) {
      _showError('Could not get location: $e');
    } finally {
      setState(() => _fetchingLocation = false);
    }
  }

  // -------------------------------------------------------------------------
  // Submission
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_selectedTrip == null) { _showError('Please select a trip first.'); return; }
    if (!(_formKey.currentState?.validate() ?? true)) return;

    setState(() => _submitting = true);
    try {
      final odometer = _odometerCtrl.text.trim().isEmpty ? null : int.tryParse(_odometerCtrl.text.trim());
      await _service.submitCheckIn(
        tripId: _selectedTrip!.id,
        status: _selectedStatus,
        lat: _lat,
        lng: _lng,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        odometerKm: odometer,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text('Check-in saved!', style: AppType.body(14, weight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Submission failed. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build helpers
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return AppGradientHeader(
      eyebrow: 'Check-in',
      title: 'Report Status',
      subtitle: 'Report your current status and location',
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        if (!_loadingTrips) ...[
          const SizedBox(width: 8),
          HeaderIconButton(
            icon: Icons.refresh_rounded,
            onTap: _loadTrips,
            tooltip: 'Refresh',
          ),
        ],
      ],
    );
  }

  Widget _buildBottomNav() => const AppBottomNav(currentIndex: 2);

  Widget _buildTripSelector() {
    if (_loadingTrips) {
      return AppSkeleton(child: AppSkeleton.box(context, height: 56, radius: 18));
    }
    if (_tripsError != null) {
      return AppCard(child: AppError(message: _tripsError!, onRetry: _loadTrips));
    }
    if (_trips.isEmpty) {
      return const AppCard(
        child: AppEmpty(
          icon: Icons.local_shipping_outlined,
          message: 'No active trips right now.\nContact your dispatcher if this looks wrong.',
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: DropdownButtonFormField<Trip>(
        // ignore: deprecated_member_use
        value: _selectedTrip, // reactive — initialValue doesn't update on setState
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(Icons.local_shipping_rounded, color: kPrimary, size: 22),
        ),
        hint: Text('Select a trip', style: AppType.body(14, color: kMuted)),
        items: _trips.map((trip) {
          return DropdownMenuItem<Trip>(
            value: trip,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(trip.tripNumber,
                    style: AppType.body(15,
                        weight: FontWeight.w700,
                        color: AppColors.textNavy(context))),
                Text('${trip.routeFrom} → ${trip.routeTo}',
                    style: AppType.body(12, color: kMuted),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
        onChanged: (t) => setState(() => _selectedTrip = t),
        selectedItemBuilder: (context) => _trips.map((trip) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${trip.tripNumber}  •  ${trip.routeFrom} → ${trip.routeTo}',
              overflow: TextOverflow.ellipsis,
              style: AppType.body(14,
                  weight: FontWeight.w600, color: AppColors.textNavy(context)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Column(
      children: _statusOptions.map((opt) {
        final selected = _selectedStatus == opt.value;
        final isEmergency = opt.value == 'emergency';
        final color = statusColor(opt.value);

        return GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedStatus = opt.value); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: isEmergency ? 0.12 : 0.08)
                  : AppColors.surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? color : AppColors.border(context), width: selected ? 2.5 : 1.5),
              boxShadow: selected
                  ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(opt.icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label,
                          style: AppType.display(16,
                              color: selected ? color : AppColors.textNavy(context))),
                      const SizedBox(height: 3),
                      Text(opt.subtitle,
                          style: AppType.body(12,
                              color: selected ? color.withValues(alpha: 0.80) : kMuted)),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.check_circle_rounded, color: color, size: 24),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGpsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetchingLocation ? null : _getLocation,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: _lat != null ? kSuccess : kPrimary, width: 1.5),
                foregroundColor: _lat != null ? kSuccess : kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _fetchingLocation
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_lat != null ? Icons.my_location_rounded : Icons.location_searching_rounded, size: 20),
              label: Text(
                _fetchingLocation ? 'Getting location…' : _lat != null ? 'Location captured' : 'Get Current Location',
                style: AppType.body(15, weight: FontWeight.w600),
              ),
            ),
          ),
          if (_lat != null && _lng != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, size: 14, color: kSuccess),
                  const SizedBox(width: 6),
                  Text(
                    '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                    style: AppType.number(12.5, weight: FontWeight.w700, color: kSuccess),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: _locationCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Location / Address (optional)',
              hintText: 'e.g. Morogoro Road, Tanzania',
              prefixIcon: const Icon(Icons.place_rounded, size: 20),
              filled: true,
              fillColor: AppColors.surfaceVariant(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalFields() {
    return AppCard(
      child: Column(
        children: [
          TextFormField(
            controller: _odometerCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppType.number(15, weight: FontWeight.w700, color: AppColors.textNavy(context)),
            decoration: InputDecoration(
              labelText: 'Odometer reading (km) — optional',
              hintText: 'e.g. 45200',
              prefixIcon: const Icon(Icons.speed_rounded, size: 20),
              suffixText: 'km',
              filled: true,
              fillColor: AppColors.surfaceVariant(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: AppType.body(14, color: AppColors.textNavy(context)),
            decoration: InputDecoration(
              labelText: 'Notes — optional',
              hintText: 'Anything the dispatcher should know…',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 52),
                child: Icon(Icons.notes_rounded, size: 20),
              ),
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surfaceVariant(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEmergency = _selectedStatus == 'emergency';
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_submitting || _selectedTrip == null) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEmergency ? kDanger : kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: isEmergency ? 6 : 2,
          shadowColor: isEmergency ? kDanger.withValues(alpha: 0.40) : kPrimary.withValues(alpha: 0.30),
        ),
        child: _submitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEmergency ? Icons.emergency_rounded : Icons.send_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isEmergency ? 'Send Emergency Alert' : 'Submit Check-In',
                    style: AppType.body(16, weight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _selectedStatus == 'emergency'
          ? Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kDanger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDanger.withValues(alpha: 0.40), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency_rounded, color: kDanger, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency selected',
                            style: AppType.display(14, color: kDanger)),
                        const SizedBox(height: 3),
                        Text('Your dispatcher will be notified immediately.',
                            style: AppType.body(12, color: kDanger)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
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
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  RevealOnLoad(
                    delayMs: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Trip',
                          eyebrow: 'Select',
                          icon: Icons.local_shipping_rounded,
                          accent: ModuleAccent.ops,
                        ),
                        _buildTripSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  RevealOnLoad(
                    delayMs: 70,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Status',
                          eyebrow: 'Report',
                          icon: Icons.flag_rounded,
                          accent: ModuleAccent.ops,
                        ),
                        _buildStatusCards(),
                        const SizedBox(height: 8),
                        _buildEmergencyBanner(),
                      ],
                    ),
                  ),
                  RevealOnLoad(
                    delayMs: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Location',
                          eyebrow: 'Where',
                          icon: Icons.place_rounded,
                          accent: ModuleAccent.ops,
                        ),
                        _buildGpsSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  RevealOnLoad(
                    delayMs: 210,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Details',
                          eyebrow: 'Optional',
                          icon: Icons.notes_rounded,
                          accent: ModuleAccent.ops,
                        ),
                        _buildOptionalFields(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  RevealOnLoad(delayMs: 280, child: _buildSubmitButton()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

