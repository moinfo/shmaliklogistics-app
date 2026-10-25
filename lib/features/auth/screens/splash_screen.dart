import 'package:flutter/material.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/ui/typography.dart';
import '../../../core/utils/colors.dart';

class SplashScreen extends StatefulWidget {
  final AuthStorage authStorage;

  const SplashScreen({super.key, required this.authStorage});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final hasToken = await widget.authStorage.hasToken();
    if (!mounted) return;

    if (!hasToken) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Rehydrate the in-memory session from secure storage.
    final accountType = await widget.authStorage.getAccountType();
    final permissions = await widget.authStorage.getPermissions();
    final name = await widget.authStorage.getName();
    final email = await widget.authStorage.getEmail();
    final role = await widget.authStorage.getRole();
    if (!mounted) return;
    AppSession.instance.set(
      accountType: accountType,
      permissions: permissions,
      name: name,
      email: email,
      role: role,
    );

    Navigator.pushReplacementNamed(
      context,
      accountType == 'driver' ? '/dashboard' : '/home',
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'TRANS-MAS LOGISTICS',
                textAlign: TextAlign.center,
                style: AppType.display(23, color: Colors.white, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                'LOGISTICS PLATFORM',
                style: AppType.eyebrow(
                  size: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}