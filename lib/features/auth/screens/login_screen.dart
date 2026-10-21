import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/ui/typography.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/theme_notifier.dart';
import '../auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Biometric login state.
  final _bio = BiometricService();
  bool _biometricReady = false; // device-capable AND credentials enrolled
  bool _autoPrompted = false;
  IconData _biometricIcon = Icons.fingerprint;
  String _biometricLabel = 'Sign in with biometrics';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
    _initBiometric();
  }

  /// Detects whether biometric sign-in is both supported and enrolled, then
  /// (once) auto-prompts so a returning user can glance-and-go.
  Future<void> _initBiometric() async {
    final available = await _bio.isAvailable();
    final enabled = await widget.authService.storage.isBiometricEnabled();
    if (!mounted || !available || !enabled) return;

    final types = await _bio.availableTypes();
    final isFace = types.contains(BiometricType.face);
    if (!mounted) return;
    setState(() {
      _biometricReady = true;
      _biometricIcon = isFace ? Icons.face_rounded : Icons.fingerprint;
      _biometricLabel = isFace ? 'Sign in with Face ID' : 'Sign in with fingerprint';
    });

    if (!_autoPrompted) {
      _autoPrompted = true;
      _biometricLogin();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final login = _loginController.text.trim();
    final password = _passwordController.text;
    try {
      final result = await widget.authService.login(login, password);
      if (!mounted) return;
      // Offer to remember this login behind biometrics for next time.
      await _maybeOfferBiometric(login, password);
      if (!mounted) return;
      _goHome(result);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Unable to connect. Check your internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Drivers keep the dedicated driver home; staff & customers use the
  /// permission-driven shell.
  void _goHome(LoginResult result) {
    Navigator.pushReplacementNamed(
      context,
      result.accountType == 'driver' ? '/dashboard' : '/home',
    );
  }

  /// After a successful password login, asks once whether to enable biometric
  /// sign-in; if accepted, stores the credentials securely behind the device's
  /// Keychain/Keystore.
  Future<void> _maybeOfferBiometric(String login, String password) async {
    final storage = widget.authService.storage;
    if (await storage.isBiometricEnabled()) return;
    if (!await _bio.isAvailable()) return;
    if (!mounted) return;

    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint, color: kPrimary, size: 32),
        title: Text('Enable biometric sign-in?',
            style: AppType.display(18, color: AppColors.textNavy(ctx))),
        content: Text(
          'Sign in faster next time with your fingerprint or Face ID instead of typing your password.',
          style: AppType.body(14, color: kMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Not now', style: AppType.body(14, color: kMuted, weight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: kPrimary),
            child: Text('Enable', style: AppType.body(14, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (enable == true) {
      await storage.saveBiometricCredentials(login, password);
    }
  }

  /// Prompts the OS biometric sheet and, on success, signs in with the stored
  /// credentials. Stale credentials (e.g. after a password change) are dropped.
  Future<void> _biometricLogin() async {
    // Re-entrancy + race guard: set the busy flag SYNCHRONOUSLY (before the OS
    // sheet) so the Sign In button and a second biometric tap are disabled while
    // the prompt is up, preventing two concurrent /auth/login calls.
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _bio.authenticate(reason: 'Sign in to SH Malik Logistics');
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _isLoading = false;
        if (result.error != null) _errorMessage = result.error;
      });
      return;
    }

    final creds = await widget.authService.storage.getBiometricCredentials();
    if (!mounted) return;
    if (creds == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final loginResult = await widget.authService.login(creds.login, creds.password);
      if (!mounted) return;
      _goHome(loginResult);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 422) {
        await widget.authService.storage.clearBiometricCredentials();
        if (mounted) {
          setState(() {
            _biometricReady = false;
            _errorMessage = 'Saved sign-in is no longer valid. Please sign in with your password.';
          });
        }
      } else if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Unable to connect. Check your internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B3E), Color(0xFF1565C0), Color(0xFF0A2540)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Faint blueprint grid + radar rings — echoes AppGradientHeader.
          const Positioned.fill(
            child: CustomPaint(painter: _BlueprintPainter()),
          ),

          // Subtle circle accents
          Positioned(
            top: -80,
            right: -60,
            child: _GlowCircle(size: 260, opacity: 0.08),
          ),
          Positioned(
            bottom: size.height * 0.25,
            left: -100,
            child: _GlowCircle(size: 300, opacity: 0.06),
          ),

          // Content
          SafeArea(
            // Fills the screen when there's room; once the keyboard shrinks the
            // viewport the content keeps its natural height and scrolls.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                // Compact layout fits the screen, so no scrolling is needed; the
                // keyboard case collapses the logo/footer instead (see below).
                physics: const NeverScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        if (!keyboardOpen) ...[
                          const Spacer(flex: 2),
                          _buildLogoSection(),
                          const Spacer(flex: 3),
                        ] else
                          const Spacer(),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: _buildFormSheet(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Theme toggle — last in stack so it receives taps above content
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, child) => IconButton(
                  icon: Icon(
                    mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 22,
                  ),
                  tooltip: mode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
                  onPressed: toggleTheme,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          // Logo with frosted glass ring
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'SH MALIK LOGISTICS',
            textAlign: TextAlign.center,
            style: AppType.display(23, color: Colors.white, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              'LOGISTICS PORTAL',
              style: AppType.eyebrow(
                size: 11,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSheet() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Welcome back',
              style: AppType.display(25, color: AppColors.textNavy(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to your account',
              style: AppType.body(14, color: kMuted),
            ),
            const SizedBox(height: 20),

            _buildField(
              controller: _loginController,
              label: 'Email or Card ID',
              hint: 'msembe@shmaliklogistics.co.tz',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.emailAddress,
              action: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _passwordController,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              action: TextInputAction.done,
              onSubmit: (_) => _submit(),
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildError(),
            ],

            const SizedBox(height: 20),
            _buildActionRow(),
            if (!keyboardOpen) ...[
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    bool obscure = false,
    Widget? suffix,
    void Function(String)? onSubmit,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: action,
      onFieldSubmitted: onSubmit,
      style: AppType.body(15, color: AppColors.textNavy(context)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppType.body(13, color: kMuted),
        hintStyle: AppType.body(13, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: kMuted, size: 20),
        suffixIcon: suffix,
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

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kDanger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDanger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kDanger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppType.body(13, color: kDanger, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SH MALIK LOGISTICS',
                    style: AppType.eyebrow(
                      size: 10,
                      color: AppColors.textNavy(context).withValues(alpha: 0.5),
                    ).copyWith(letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COMPANY LIMITED',
              style: AppType.eyebrow(
                size: 9,
                color: kMuted.withValues(alpha: 0.45),
              ).copyWith(letterSpacing: 1.5),
            ),
            Text(
              'v1.0.0',
              style: AppType.body(
                9,
                color: kMuted.withValues(alpha: 0.45),
                weight: FontWeight.w600,
              ).copyWith(letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/landing', (r) => false),
            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: kPrimary),
            label: Text('Back to home',
                style: AppType.body(13.5, color: kPrimary, weight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text.rich(
              TextSpan(
                text: 'Powered by ',
                style: AppType.body(
                  11.5,
                  color: kMuted.withValues(alpha: 0.8),
                  weight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: 'Moinfotech',
                    style: AppType.body(
                      11.5,
                      color: kAccent,
                      weight: FontWeight.w800,
                    ).copyWith(letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Sign In button with the fingerprint / Face ID button merged on its right.
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(child: _buildButton()),
        if (_biometricReady) ...[
          const SizedBox(width: 12),
          Tooltip(
            message: _biometricLabel,
            child: SizedBox(
              width: 54,
              height: 54,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _biometricLogin,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: kPrimary.withValues(alpha: 0.12),
                  side: BorderSide(color: kPrimary.withValues(alpha: 0.45), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Icon(_biometricIcon, size: 28, color: kPrimary),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D1B3E),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF0D1B3E).withValues(alpha: 0.5),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Sign In',
                style: AppType.body(16, weight: FontWeight.w700)
                    .copyWith(letterSpacing: 0.5),
              ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Faint engineering grid + concentric radar rings — mirrors the texture used by
/// `AppGradientHeader` so the auth screen speaks the same "command" language.
class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Radar rings, anchored top-left near the hero.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.06);
    final center = Offset(size.width * 0.5, size.height * 0.22);
    for (final r in [70.0, 130.0, 200.0]) {
      canvas.drawCircle(center, r, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) => false;
}
