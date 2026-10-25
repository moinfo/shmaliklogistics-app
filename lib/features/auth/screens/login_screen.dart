import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
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

    final result = await _bio.authenticate(reason: 'Sign in to Trans-Mas Logistics');
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
    final size = MediaQuery.sizeOf(context);

    // Computed directly from viewInsets rather than relying on Scaffold's
    // resizeToAvoidBottomInset — on this engine/Android combo the Scaffold's
    // body constraints weren't actually shrinking when the keyboard opened
    // (resizeToAvoidBottomInset is disabled below so we don't double-handle
    // the inset), causing a real RenderFlex overflow instead of the intended
    // in-place shrink.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;
    // When the keyboard is open it already obstructs down to the bottom of
    // the screen, so viewInsets.bottom covers that case; only fall back to
    // the system nav bar's own inset when the keyboard is closed, to avoid
    // double-subtracting both.
    final bottomInset =
        keyboardInset > 0 ? keyboardInset : MediaQuery.paddingOf(context).bottom;
    final availableHeight = size.height - topInset - bottomInset;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1E0800),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E0800), Color(0xFFEA580C), Color(0xFF1E0800)],
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

          // Content, positioned below the status bar and above the keyboard
          // (topInset/bottomInset already account for both, so no SafeArea
          // here — it would double-subtract). Centered when it fits; when the
          // keyboard leaves too little room for the logo + form together
          // (Spacer/Expanded cannot be used safely with a scroll fallback —
          // they require a bounded main-axis size, which conflicts with
          // letting the ScrollView grow past it), it scrolls smoothly instead
          // of overflowing: ConstrainedBox's minHeight lets the Column center
          // within the available space when content fits, while the Column
          // itself (no flex children) simply reports its natural height when
          // it doesn't, which the ScrollView then scrolls to.
          Positioned(
            top: topInset,
            left: 0,
            right: 0,
            height: availableHeight,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogoSection(),
                    const SizedBox(height: 28),
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
            'TRANS-MAS LOGISTICS',
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: LiquidGlass(
        radius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
        sigma: GlassTokens.blurSigmaSheet,
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
                margin: const EdgeInsets.only(bottom: 28),
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
            const SizedBox(height: 32),

            _buildField(
              controller: _loginController,
              label: 'Email or Card ID',
              hint: 'msembe@transmaslogistics.co.tz',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.emailAddress,
              action: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

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

            const SizedBox(height: 28),
            _buildButtonRow(),
            const SizedBox(height: 28),
            _buildFooter(),
          ],
        ),
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
        // Translucent fill so the frosted sheet bleeds through and the input
        // reads as a recessed pane of glass rather than a solid pill.
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.45),
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

  /// Sign In button with a biometric quick-access icon docked inside its own
  /// right alongside it in the same row (when biometrics are enrolled),
  /// instead of a separate "or" section below.
  ///
  /// Always returns the same Row shape (even with biometrics unready) so the
  /// widget at this Column slot never changes type mid-animation — swapping
  /// between a bare button and a differently-shaped widget here previously
  /// crashed with a `!semantics.parentDataDirty` assertion when
  /// `_biometricReady` flipped true during the entrance fade/slide.
  Widget _buildButtonRow() {
    return SizedBox(
      height: 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildButton()),
          if (_biometricReady) ...[
            const SizedBox(width: 12),
            _buildBiometricButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Semantics(
      button: true,
      label: _biometricLabel,
      child: SizedBox(
        width: 54,
        child: Material(
          color: const Color(0xFF1E0800).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _isLoading ? null : _biometricLogin,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimary.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Icon(_biometricIcon, size: 24, color: kPrimary),
              ),
            ),
          ),
        ),
      ),
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
                    'TRANS-MAS LOGISTICS',
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
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Powered by Moinfotech',
            style: AppType.body(
              10,
              color: kMuted.withValues(alpha: 0.4),
              weight: FontWeight.w600,
            ).copyWith(letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E0800),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF1E0800).withValues(alpha: 0.5),
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
