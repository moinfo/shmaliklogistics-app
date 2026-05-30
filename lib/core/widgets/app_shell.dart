import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/api_client.dart';
import '../auth/app_session.dart';
import '../services/auth_storage.dart';
import '../services/biometric_service.dart';
import '../ui/typography.dart';
import '../ui/ui_kit.dart';
import '../utils/app_theme.dart';
import '../utils/colors.dart';
import '../utils/theme_notifier.dart';
import '../../features/staff_ops/screens/ops_home_screen.dart';
import '../../features/staff_finance/screens/finance_home_screen.dart';
import '../../features/staff_hr/screens/hr_home_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import 'app_drawer.dart';
import 'command_nav_bar.dart';
import 'module_placeholder_screen.dart';
import 'module_registry.dart';

/// A single bottom-nav destination plus the screen it shows.
class _ShellTab {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;
  const _ShellTab(this.icon, this.selectedIcon, this.label, this.screen);
}

/// Permission-driven home for `staff` and `customer` accounts.
///
/// Drivers do NOT use this — they keep the dedicated `/dashboard` flow.
/// The tab set is assembled from [AppSession] account type + permissions, so a
/// Finance Officer and an Ops Manager see different tabs from the same app.
class AppShell extends StatefulWidget {
  final ApiClient apiClient;
  const AppShell({super.key, required this.apiClient});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final List<_ShellTab> _tabs = _buildTabs();

  // A drawer-opened module screen shown over the tabs (keeps the bottom nav;
  // the top bar shows a back arrow to return to the tabs). Null = on a tab.
  Widget? _moduleScreen;
  String? _moduleTitle;

  List<_ShellTab> _buildTabs() {
    final session = AppSession.instance;
    final api = widget.apiClient;
    final tabs = <_ShellTab>[];

    if (session.accountType == 'customer') {
      tabs.add(_ShellTab(Icons.dashboard_outlined, Icons.dashboard_rounded,
          'Home', CustomerHomeScreen(apiClient: api)));
    } else {
      // staff
      tabs.add(_ShellTab(Icons.insights_outlined, Icons.insights_rounded,
          'Overview', _OverviewTab(apiClient: api)));

      if (session.canAny(['trips.view', 'fleet.view'])) {
        tabs.add(_ShellTab(Icons.local_shipping_outlined,
            Icons.local_shipping_rounded, 'Ops', OpsHomeScreen(apiClient: api)));
      }
      if (session.canAny(['billing_invoices.view', 'billing_payments.view'])) {
        tabs.add(_ShellTab(Icons.receipt_long_outlined,
            Icons.receipt_long_rounded, 'Finance', FinanceHomeScreen(apiClient: api)));
      }
      if (session.canAny(['hr_leave.view', 'hr_advances.view', 'hr_loans.view'])) {
        tabs.add(_ShellTab(Icons.groups_outlined, Icons.groups_rounded, 'HR',
            HrHomeScreen(apiClient: api)));
      }
    }

    tabs.add(_ShellTab(Icons.person_outline_rounded, Icons.person_rounded,
        'Account', _AccountTab(apiClient: api)));
    return tabs;
  }

  /// Switch the active bottom tab by its label (used by the navigation drawer).
  /// Clears any open module overlay. No-op if the label is not a mounted tab.
  void _selectTabByLabel(String label) {
    final i = _tabs.indexWhere((t) => t.label == label);
    if (i >= 0) setState(() { _index = i; _moduleScreen = null; _moduleTitle = null; });
  }

  /// Show a drawer-opened module screen over the tabs. Uses the built screen
  /// from [kModuleScreens] when one exists, otherwise a clean placeholder — so
  /// every menu item lands somewhere with the bottom nav + a back arrow.
  void _openModule(String label, IconData icon) {
    final builder = kModuleScreens[label];
    setState(() {
      _moduleTitle = label;
      _moduleScreen = builder != null
          ? builder(widget.apiClient)
          : ModulePlaceholderScreen(title: label, icon: icon);
    });
  }

  void _closeModule() => setState(() { _moduleScreen = null; _moduleTitle = null; });

  void _onTabSelected(int i) =>
      setState(() { _index = i; _moduleScreen = null; _moduleTitle = null; });

  @override
  Widget build(BuildContext context) {
    final tabLabels = _tabs.map((t) => t.label).toSet();
    final inModule = _moduleScreen != null;
    final title = inModule ? (_moduleTitle ?? '') : _tabs[_index].label;

    return PopScope(
      // Intercept the system back gesture to leave a module without exiting the app.
      canPop: !inModule,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inModule) _closeModule();
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceVariant(context),
        // The transparent app bar floats over the screen's gradient header.
        extendBodyBehindAppBar: true,
        // Slim branded bar: hamburger on a tab, back arrow inside a module.
        // Feature screens render their own AppGradientHeader below.
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Builder(
            builder: (ctx) => AppBar(
              toolbarHeight: 52,
              elevation: 0,
              scrolledUnderElevation: 0,
              // Transparent + floating: the screen's AppGradientHeader draws
              // its gradient behind this bar (see extendBodyBehindAppBar), so
              // the bar and header read as one seamless surface.
              backgroundColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: inModule
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      tooltip: 'Back',
                      onPressed: _closeModule,
                    )
                  : IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      tooltip: 'Menu',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
              titleSpacing: 0,
              title: Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 26, fit: BoxFit.contain),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.display(16, color: Colors.white, letterSpacing: 0.2)),
                  ),
                ],
              ),
              actions: [
                // Quick access to the full menu even while inside a module.
                if (inModule)
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      tooltip: 'Menu',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        drawer: AppDrawer(
          activeTabLabel: inModule ? (_moduleTitle ?? '') : _tabs[_index].label,
          availableTabs: tabLabels,
          onSelectTab: _selectTabByLabel,
          onOpenModule: _openModule,
        ),
        // Tabs stay mounted underneath; a module screen overlays them so the
        // bottom nav and top bar persist. ShellChrome tells the screens' headers
        // to leave 52px for the floating app bar so the gradient runs behind it.
        body: ShellChrome(
          topInset: 8,
          child: Stack(
            children: [
              IndexedStack(
                index: _index,
                children: _tabs.map((t) => t.screen).toList(),
              ),
              if (inModule) Positioned.fill(child: _moduleScreen!),
            ],
          ),
        ),
        bottomNavigationBar: CommandNavBar(
          currentIndex: _index,
          onSelect: _onTabSelected,
          items: [
            for (final t in _tabs)
              CommandNavItem(icon: t.icon, selectedIcon: t.selectedIcon, label: t.label),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Staff cross-module overview tab — GET /staff/dashboard
// ---------------------------------------------------------------------------

class _OverviewTab extends StatefulWidget {
  final ApiClient apiClient;
  const _OverviewTab({required this.apiClient});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await widget.apiClient.get('/staff/dashboard') as Map<String, dynamic>;
      if (mounted) setState(() { _data = json; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load overview.'; _loading = false; });
    }
  }

  String _n(Map<String, dynamic>? m, String k) {
    final v = m?[k];
    final n = (v is num) ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;
    return '$n';
  }

  /// Time-of-day greeting shown above the name.
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  /// Human-readable role from the session slug (e.g. 'finance_officer' →
  /// 'Finance Officer'), falling back to the account type.
  String _roleLabel() {
    final s = AppSession.instance;
    if (s.role.isEmpty) return s.accountType == 'customer' ? 'Customer' : 'Staff';
    if (s.role == 'admin') return 'Administrator';
    return s.role
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final ops = _data?['ops'] as Map<String, dynamic>?;
    final finance = _data?['finance'] as Map<String, dynamic>?;
    final hr = _data?['hr'] as Map<String, dynamic>?;
    final name = AppSession.instance.name.isEmpty ? 'Team' : AppSession.instance.name;

    return Column(
      children: [
        AppGradientHeader(
          eyebrow: 'Command Center',
          subtitle: _greeting(),
          title: name,
          leading: _HeaderAvatar(name: name),
          footer: _RoleChip(label: _roleLabel()),
          actions: [HeaderIconButton(icon: Icons.refresh_rounded, onTap: _load, tooltip: 'Refresh')],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: kPrimary,
            child: _loading
                ? _buildSkeleton()
                : _error != null
                    ? ListView(children: [SizedBox(height: 80, child: AppError(message: _error!, onRetry: _load))])
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        children: [
                          if (ops != null)
                            _section('Operations', 'Fleet & dispatch', Icons.local_shipping_rounded, ModuleAccent.ops, 0, [
                              StatCard(label: 'Active Trips', value: _n(ops, 'active_trips'), icon: Icons.route_rounded, accent: ModuleAccent.ops),
                              StatCard(label: 'Fleet', value: _n(ops, 'fleet_count'), icon: Icons.commute_rounded, accent: ModuleAccent.ops),
                              StatCard(label: 'Drivers', value: _n(ops, 'drivers_count'), icon: Icons.badge_rounded, accent: ModuleAccent.ops),
                              StatCard(label: 'Alerts', value: _n(ops, 'alerts_count'), icon: Icons.warning_amber_rounded, accent: ModuleAccent.ops, danger: true),
                            ]),
                          if (finance != null)
                            _section('Finance', 'Billing & cash', Icons.account_balance_wallet_rounded, ModuleAccent.finance, 90, [
                              StatCard(label: 'Invoices', value: _n(finance, 'invoices_count'), icon: Icons.receipt_long_rounded, accent: ModuleAccent.finance),
                              StatCard(label: 'Outstanding', value: _n(finance, 'outstanding_count'), icon: Icons.pending_actions_rounded, accent: ModuleAccent.finance, danger: true),
                              StatCard(label: 'Overdue', value: _n(finance, 'overdue_count'), icon: Icons.event_busy_rounded, accent: ModuleAccent.finance, danger: true),
                            ]),
                          if (hr != null)
                            _section('Human Resources', 'People & approvals', Icons.groups_rounded, ModuleAccent.hr, 180, [
                              StatCard(label: 'Employees', value: _n(hr, 'employees_count'), icon: Icons.people_alt_rounded, accent: ModuleAccent.hr),
                              StatCard(label: 'Pending Approvals', value: _n(hr, 'pending_approvals'), icon: Icons.how_to_reg_rounded, accent: ModuleAccent.hr, danger: true),
                              StatCard(label: 'Pending Leave', value: _n(hr, 'pending_leave'), icon: Icons.beach_access_rounded, accent: ModuleAccent.hr),
                            ]),
                          if (ops == null && finance == null && hr == null)
                            const AppEmpty(icon: Icons.dashboard_customize_rounded, message: 'No dashboard sections available for your role.'),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  /// A titled section with a responsive 2-column grid of stat cards, revealed
  /// with a staggered fade-in.
  Widget _section(String title, String eyebrow, IconData icon, ModuleAccent accent,
      int delayMs, List<Widget> cards) {
    final cardWidth = (MediaQuery.sizeOf(context).width - 40 - 12) / 2;
    return RevealOnLoad(
      delayMs: delayMs,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: accent),
            const SizedBox(height: 2),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final c in cards) SizedBox(width: cardWidth, child: c)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    final w = (MediaQuery.sizeOf(context).width - 40 - 12) / 2;
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          for (var s = 0; s < 2; s++) ...[
            AppSkeleton.box(context, height: 22, width: 150, radius: 6),
            const SizedBox(height: 14),
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (var i = 0; i < 4; i++) AppSkeleton.box(context, height: 118, width: w, radius: 18),
            ]),
            const SizedBox(height: 26),
          ],
        ],
      ),
    );
  }
}

/// Frosted circular avatar (user initials) for the command header.
class _HeaderAvatar extends StatelessWidget {
  final String name;
  const _HeaderAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(initials.isEmpty ? '?' : initials,
          style: AppType.number(17, color: Colors.white)),
    );
  }
}

/// Frosted role pill shown below the name in the command header.
class _RoleChip extends StatelessWidget {
  final String label;
  const _RoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(label, style: AppType.body(11.5, color: Colors.white, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account tab — identity + theme toggle + logout (staff & customer)
// ---------------------------------------------------------------------------

class _AccountTab extends StatelessWidget {
  final ApiClient apiClient;
  const _AccountTab({required this.apiClient});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kDanger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await apiClient.post('/auth/logout', {});
    } catch (_) {
      // Proceed with local logout even if the server call fails.
    }
    AppSession.instance.clear();
    await AuthStorage().clearToken();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    }
  }

  static const _appVersion = 'v1.0.0';

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Trans-Mas Logistics',
      applicationVersion: _appVersion,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset('assets/images/logo.png', width: 44, height: 44, fit: BoxFit.contain),
      ),
      children: [
        const SizedBox(height: 8),
        Text('Operations command for fleet, finance and people.',
            style: AppType.body(13, color: kMuted)),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: Text(
          'For assistance, contact your system administrator or the Trans-Mas '
          'support team. Full module management is available on the web portal.',
          style: AppType.body(14, color: AppColors.textPrimary(ctx)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final typeLabel = {
      'staff': 'Staff',
      'customer': 'Customer',
      'driver': 'Driver',
    }[session.accountType] ?? session.accountType;
    final initial = session.name.isEmpty ? '?' : session.name[0].toUpperCase();
    final roleLabel = session.role.isEmpty
        ? ''
        : session.role
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');

    return Column(
      children: [
        AppGradientHeader(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          eyebrow: 'Trans-Mas Logistics',
          title: 'Account',
          trailing: const SizedBox.shrink(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Transform.translate(
                offset: const Offset(0, -28),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D1B3E), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppColors.surface(context), width: 4),
                        boxShadow: [
                          BoxShadow(color: kPrimary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: Text(initial,
                            style: GoogleFonts.manrope(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(session.name.isEmpty ? 'Account' : session.name,
                        style: GoogleFonts.manrope(
                            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textNavy(context))),
                    if (session.email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(session.email,
                          style: AppType.body(13, color: kMuted)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        StatusPill(label: typeLabel.toUpperCase(), color: kPrimary),
                        if (roleLabel.isNotEmpty)
                          StatusPill(
                              label: roleLabel,
                              color: kAccent,
                              icon: Icons.verified_user_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('PREFERENCES', style: AppType.eyebrow(size: 10, color: kMuted)),
                ),
              ),
              _Tile(
                icon: themeNotifier.value == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                label: themeNotifier.value == ThemeMode.dark ? 'Light mode' : 'Dark mode',
                onTap: toggleTheme,
              ),
              const _BiometricTile(),
              const SizedBox(height: 12),
              _Tile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () => _showHelp(context),
              ),
              const SizedBox(height: 12),
              _Tile(
                icon: Icons.info_outline_rounded,
                label: 'About',
                trailingText: _appVersion,
                onTap: () => _showAbout(context),
              ),
              const SizedBox(height: 20),
              _Tile(icon: Icons.logout_rounded, label: 'Sign out', danger: true, onTap: () => _logout(context)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final String? trailingText;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.label, required this.onTap, this.danger = false, this.trailingText});

  @override
  Widget build(BuildContext context) {
    final color = danger ? kDanger : AppColors.textNavy(context);
    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
            const Spacer(),
            if (trailingText != null) ...[
              Text(trailingText!, style: AppType.body(13, color: kMuted, weight: FontWeight.w600)),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, color: kMuted, size: 20),
          ]),
        ),
      ),
    );
  }
}

/// A switch row to turn biometric sign-in on/off. Self-hides when the device
/// has no biometric hardware and none is currently enrolled. Enabling must be
/// done at sign-in (the password isn't held in-session), so the switch only
/// performs the disable; flipping it on points the user back to the login screen.
class _BiometricTile extends StatefulWidget {
  const _BiometricTile();

  @override
  State<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends State<_BiometricTile> {
  final _bio = BiometricService();
  final _storage = AuthStorage();
  bool _available = false;
  bool _enabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await _bio.isAvailable();
    final enabled = await _storage.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled;
      _loaded = true;
    });
  }

  Future<void> _onChanged(bool value) async {
    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign out and sign in again, then tap “Enable” to turn on biometric login.',
            style: AppType.body(13, color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disable biometric sign-in?',
            style: AppType.display(18, color: AppColors.textNavy(ctx))),
        content: Text('You’ll need to enter your password next time you sign in.',
            style: AppType.body(14, color: kMuted, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppType.body(14, color: kMuted, weight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: kDanger),
            child: Text('Disable', style: AppType.body(14, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _storage.clearBiometricCredentials();
    if (mounted) setState(() => _enabled = false);
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to offer if the device can't do biometrics and none is enrolled.
    if (!_loaded || (!_available && !_enabled)) return const SizedBox.shrink();
    final color = AppColors.textNavy(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(children: [
          Icon(Icons.fingerprint, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Biometric sign-in',
                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          ),
          Switch(value: _enabled, activeThumbColor: kPrimary, onChanged: _onChanged),
        ]),
      ),
    );
  }
}
