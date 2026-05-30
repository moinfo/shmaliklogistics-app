import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/driver.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/theme_notifier.dart';
import '../../mod_payroll/widgets/hr_cards.dart';
import '../models/driver_profile.dart';
import '../profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final ApiClient apiClient;
  const ProfileScreen({super.key, required this.apiClient});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _service;
  DriverProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ProfileService(widget.apiClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.fetchProfile();
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load profile.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 28),
            eyebrow: 'Driver profile',
            title: _profile?.driver.name ?? 'Profile',
            trailing: _profile != null ? _buildAvatar(_profile!.driver) : const SizedBox.shrink(),
            actions: [
              HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Expanded(
            child: _loading
                ? _buildLoading(context)
                : _error != null
                    ? AppError(
                        message: _error!,
                        onRetry: () {
                          setState(() { _loading = true; _error = null; });
                          _loadProfile();
                        },
                      )
                    : _buildBody(context),
          ),
        ],
      ),
    );
  }

  // ─── Avatar (header trailing) ──────────────────────────────────────────────

  Widget _buildAvatar(Driver driver) {
    final initials = _initials(driver.name);
    if (driver.photoUrl != null) {
      final fullUrl = ApiClient.storageUrl + driver.photoUrl!;
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            fullUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsCircle(initials),
          ),
        ),
      );
    }
    return _initialsCircle(initials);
  }

  Widget _initialsCircle(String initials) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
      ),
      child: Center(
        child: Text(initials, style: AppType.display(22, color: Colors.white)),
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    final profile = _profile!;
    final driver = profile.driver;
    final statusColor = _statusColor(driver.status);

    final sections = <Widget>[
      // Status / license-class summary pills.
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusPill(
            label: _statusLabel(driver.status),
            color: statusColor,
            icon: Icons.circle,
          ),
          if (driver.licenseClasses != null && driver.licenseClasses!.isNotEmpty)
            ...driver.licenseClasses!.map(
              (c) => StatusPill(label: 'Class $c', color: kPrimary, icon: Icons.badge_outlined),
            )
          else if (driver.licenseClass != null)
            StatusPill(label: 'Class ${driver.licenseClass}', color: kPrimary, icon: Icons.badge_outlined),
        ],
      ),

      // Personal info.
      _Group(
        eyebrow: 'Identity',
        title: 'Personal Info',
        icon: Icons.person_outline_rounded,
        rows: [
          _InfoRow(label: 'Phone', value: driver.phone, isNumber: true),
          if (driver.phoneAlt != null)
            _InfoRow(label: 'Alt Phone', value: driver.phoneAlt!, isNumber: true),
          _InfoRow(label: 'Email', value: driver.loginEmail ?? driver.email ?? '—'),
          if (driver.nationalId != null)
            _InfoRow(label: 'National ID', value: driver.nationalId!, isNumber: true),
          if (driver.cardId != null)
            _InfoRow(label: 'Card ID', value: driver.cardId!, isNumber: true),
          if (driver.address != null) _InfoRow(label: 'Address', value: driver.address!),
          if (driver.birthRegion != null)
            _InfoRow(label: 'Birth Region', value: driver.birthRegion!),
          if (driver.birthDistrict != null)
            _InfoRow(label: 'Birth District', value: driver.birthDistrict!, isLast: true),
        ],
      ),

      // License.
      _Group(
        eyebrow: 'Credentials',
        title: 'License',
        icon: Icons.badge_outlined,
        rows: [
          _InfoRow(label: 'License No.', value: driver.licenseNumber ?? '—', isNumber: true),
          if (driver.licenseClasses != null && driver.licenseClasses!.isNotEmpty)
            _InfoRow(label: 'License Classes', value: driver.licenseClasses!.join(', '))
          else
            _InfoRow(label: 'License Class', value: driver.licenseClass ?? '—'),
          _InfoRow(
            label: 'Expiry',
            value: driver.licenseExpiry != null
                ? DateFormat('dd MMM yyyy').format(driver.licenseExpiry!)
                : '—',
            valueColor: _expiryColor(driver.licenseExpiry),
            isNumber: true,
            isLast: true,
          ),
        ],
      ),

      // Emergency contact (conditional).
      if (driver.emergencyContactName != null || driver.emergencyContactPhone != null)
        _Group(
          eyebrow: 'In case of',
          title: 'Emergency Contact',
          icon: Icons.emergency_outlined,
          accent: ModuleAccent.danger,
          rows: [
            if (driver.emergencyContactName != null)
              _InfoRow(label: 'Name', value: driver.emergencyContactName!),
            if (driver.emergencyContactPhone != null)
              _InfoRow(label: 'Phone', value: driver.emergencyContactPhone!, isNumber: true, isLast: true),
          ],
        ),

      // Assigned vehicle.
      _Group(
        eyebrow: 'Fleet',
        title: 'Assigned Vehicle',
        icon: Icons.local_shipping_outlined,
        accent: ModuleAccent.ops,
        rows: driver.vehicle == null
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('No vehicle assigned', style: AppType.body(14, color: kMuted)),
                ),
              ]
            : [
                _InfoRow(label: 'Plate', value: driver.vehicle!.plate, isNumber: true),
                _InfoRow(
                  label: 'Make & Model',
                  value: '${driver.vehicle!.make} ${driver.vehicle!.modelName}',
                ),
                if (driver.vehicle!.type != null)
                  _InfoRow(label: 'Type', value: driver.vehicle!.type!, isLast: true),
              ],
      ),

      // ── Payroll (own data) ──────────────────────────────────────────────
      if (profile.salary != null)
        _Group(
          eyebrow: 'Payroll',
          title: 'Remuneration',
          icon: Icons.payments_outlined,
          accent: ModuleAccent.finance,
          rows: [
            if (profile.position != null)
              _InfoRow(label: 'Role', value: profile.position!),
            _InfoRow(
              label: 'Monthly Salary',
              value: _money(profile.salary, profile.salaryCurrency),
              isNumber: true,
              isLast: profile.bonus == null || profile.bonus! <= 0,
            ),
            if (profile.bonus != null && profile.bonus! > 0)
              _InfoRow(
                label: 'Standing Bonus',
                value: _money(profile.bonus, profile.salaryCurrency),
                isNumber: true,
                isLast: true,
              ),
          ],
        ),
      if (profile.payroll != null) ..._payrollCards(profile),

      // Security.
      _Group(
        eyebrow: 'Account',
        title: 'Security',
        icon: Icons.lock_outline_rounded,
        accent: ModuleAccent.hr,
        rows: [
          _TappableRow(
            label: 'Change Password',
            onTap: () => _showChangePasswordSheet(context),
          ),
        ],
      ),

      // Appearance.
      _Group(
        eyebrow: 'Display',
        title: 'Appearance',
        icon: Icons.palette_outlined,
        accent: ModuleAccent.hr,
        rows: const [_AppearanceRow()],
      ),

      // App info.
      _Group(
        eyebrow: 'About',
        title: 'App Info',
        icon: Icons.info_outline_rounded,
        rows: const [
          _InfoRow(label: 'Version', value: '1.0.0', isNumber: true),
          _InfoRow(label: 'Support', value: 'support@transmaslogistics.co.tz', isLast: true),
        ],
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => RevealOnLoad(
        delayMs: (i * 60).clamp(0, 300),
        child: sections[i],
      ),
    );
  }

  /// The driver's own payroll cards, reusing the shared HR widgets. Each is a
  /// section item (wrapped by the list's RevealOnLoad), so only non-empty
  /// sections are added.
  List<Widget> _payrollCards(DriverProfile profile) {
    final p = profile.payroll!;
    final cur = profile.salaryCurrency;
    return [
      if (p.allowances.isNotEmpty)
        HrAllowancesCard(allowances: p.allowances, total: p.allowancesTotal, currency: cur),
      if (p.bonus != null && p.bonus!.hasContent)
        HrBonusCard(bonus: p.bonus!, currency: cur),
      if (p.latestSlip != null) HrPayslipCard(slip: p.latestSlip!, currency: cur),
      if (p.hasLiabilities)
        HrLiabilitiesCard(advances: p.advances, loans: p.loans),
    ];
  }

  Widget _buildLoading(BuildContext context) {
    return AppSkeleton(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          AppSkeleton.box(context, height: 30, width: 160, radius: 20),
          const SizedBox(height: 20),
          AppSkeleton.box(context, height: 200),
          const SizedBox(height: 16),
          AppSkeleton.box(context, height: 150),
          const SizedBox(height: 16),
          AppSkeleton.box(context, height: 120),
        ],
      ),
    );
  }

  // ─── Change Password Sheet ────────────────────────────────────────────────

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(service: _service),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Currency-prefixed money for the remuneration rows (whole shillings).
  String _money(double? amount, String? currency) {
    if (amount == null) return '—';
    final cur = (currency == null || currency.isEmpty) ? 'TZS' : currency;
    return '$cur ${NumberFormat('#,###').format(amount)}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'on_trip':
        return 'On Trip';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    final isActive = status == 'active' || status == 'on_trip';
    return isActive ? kSuccess : kWarning;
  }

  Color? _expiryColor(DateTime? expiry) {
    if (expiry == null) return null;
    final now = DateTime.now();
    if (expiry.isBefore(now)) return kDanger;
    if (expiry.isBefore(now.add(const Duration(days: 30)))) return kWarning;
    return null;
  }
}

// ─── Section group: SectionHeader + AppCard rows ─────────────────────────────

class _Group extends StatelessWidget {
  final String title;
  final String eyebrow;
  final IconData icon;
  final ModuleAccent accent;
  final List<Widget> rows;

  const _Group({
    required this.title,
    required this.eyebrow,
    required this.icon,
    required this.rows,
    this.accent = ModuleAccent.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: accent),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ],
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  final bool isNumber;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppType.body(13, color: kMuted, weight: FontWeight.w500)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: isNumber
                      ? AppType.number(14.5, color: valueColor ?? AppColors.textNavy(context))
                      : AppType.body(14,
                          color: valueColor ?? AppColors.textNavy(context),
                          weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: AppColors.border(context)),
      ],
    );
  }
}

// ─── Tappable Row ────────────────────────────────────────────────────────────

class _TappableRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TappableRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppType.body(14, color: AppColors.textNavy(context), weight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Appearance Row ──────────────────────────────────────────────────────────

class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Dark Mode',
              style: AppType.body(14, color: AppColors.textNavy(context), weight: FontWeight.w600),
            ),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) => Switch(
              value: mode == ThemeMode.dark,
              activeThumbColor: kPrimary,
              onChanged: (_) => toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Change Password Bottom Sheet ────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  final ProfileService service;
  const _ChangePasswordSheet({required this.service});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.service.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password updated successfully',
            style: AppType.body(14, color: Colors.white),
          ),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to connect. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 32),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Change Password',
                style: AppType.display(20, color: AppColors.textNavy(context)),
              ),
              const SizedBox(height: 20),

              // Current Password
              _buildPasswordField(
                controller: _currentCtrl,
                label: 'Current Password',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                action: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // New Password
              _buildPasswordField(
                controller: _newCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                action: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirm New Password
              _buildPasswordField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                action: TextInputAction.done,
                onSubmit: (_) => _submit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              // Error banner
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kDanger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: kDanger.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: kDanger, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppType.body(13, color: kDanger, weight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B3E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF0D1B3E).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : Text(
                          'Update Password',
                          style: AppType.body(15, color: Colors.white, weight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    TextInputAction action = TextInputAction.next,
    void Function(String)? onSubmit,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onFieldSubmitted: onSubmit,
      style: AppType.body(15, color: AppColors.textNavy(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppType.body(13, color: kMuted),
        prefixIcon:
            const Icon(Icons.lock_outline_rounded, color: kMuted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: kMuted,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant(context),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDanger, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
