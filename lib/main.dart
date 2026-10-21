import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'core/services/auth_storage.dart';
import 'core/utils/app_theme.dart';
import 'core/utils/secret_tap.dart';
import 'core/utils/theme_notifier.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/trips/screens/trips_screen.dart';
import 'features/check_in/screens/check_in_screen.dart';
import 'features/inspection/screens/inspection_screen.dart';
import 'features/check_in/screens/check_in_history_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedTheme();
  runApp(const ShMalikApp());
}

class ShMalikApp extends StatefulWidget {
  const ShMalikApp({super.key});

  @override
  State<ShMalikApp> createState() => _ShMalikAppState();
}

class _ShMalikAppState extends State<ShMalikApp> {
  late final AuthStorage _authStorage;
  late final ApiClient _apiClient;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authStorage = AuthStorage();
    _apiClient = ApiClient(_authStorage);
    _authService = AuthService(api: _apiClient, storage: _authStorage);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, child) => MaterialApp(
        title: 'SH Malik Driver',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        builder: (context, child) => SecretTapDetector(child: child!),
        initialRoute: '/',
        routes: {
          '/':                  (_) => SplashScreen(authStorage: _authStorage),
          '/login':             (_) => LoginScreen(authService: _authService),
          '/home':              (_) => AppShell(apiClient: _apiClient),
          '/dashboard':         (_) => const DashboardScreen(),
          '/trips':             (_) => const TripsScreen(),
          '/check_in':          (_) => CheckInScreen(apiClient: _apiClient),
          '/inspection':        (_) => InspectionScreen(apiClient: _apiClient),
          '/check_in_history':  (_) => CheckInHistoryScreen(apiClient: _apiClient),
          '/profile':           (_) => ProfileScreen(apiClient: _apiClient),
        },
      ),
    );
  }
}
