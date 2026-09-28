import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/tts_service.dart';
import 'services/clinical_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/child/child_profile_selection.dart';
import 'screens/therapist/therapist_portal_screen.dart';
import 'screens/therapist/therapist_login_screen.dart';
import 'screens/auth/child_login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless aesthetics
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase (with graceful fallback)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase.initializeApp() warning: $e');
  }

  // Initialize Core Services
  await FirebaseService.instance.init();
  await LocalizationService.instance.init();
  await AuthService.instance.init();
  ClinicalService.instance.init();
  await TtsService.instance.init();
  await ThemeService.instance.init();
  await ParentNotificationService.instance.init();

  runApp(const ParwarishApp());
}

class ParwarishApp extends StatefulWidget {
  const ParwarishApp({super.key});

  @override
  State<ParwarishApp> createState() => _ParwarishAppState();
}

class _ParwarishAppState extends State<ParwarishApp> {
  String? _selectedDeviceSpace;
  bool _isInitChecked = false;

  @override
  void initState() {
    super.initState();
    _checkInitialSpace();
  }

  Future<void> _checkInitialSpace() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDeviceSpace = prefs.getString('selected_device_space') ??
          prefs.getString('default_device_mode');
      _isInitChecked = true;
    });
  }

  Widget _determineInitialScreen() {
    final role = AuthService.instance.userRole;

    if (role == 'therapist' || role == 'admin') {
      return const TherapistPortalScreen();
    }

    // Requirement 1: Once selected after installation, space must be chosen automatically every time
    if (_selectedDeviceSpace == 'parent' || role == 'parent') {
      if (AuthService.instance.isLoggedIn) {
        return const ParentDashboard();
      }
      return const ChildLoginScreen(isParentLogin: true);
    } else if (_selectedDeviceSpace == 'child' || role == 'child') {
      return ChildProfileSelection(parentUid: AuthService.instance.currentUserUid);
    }

    // First time after installation -> Welcome Screen with Guidelines
    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitChecked) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        LocalizationService.instance.currentLocale,
        ThemeService.instance.themeModeNotifier,
        ThemeService.instance.colorSchemeNotifier,
        ThemeService.instance.fontScaleNotifier,
      ]),
      builder: (context, _) {
        final scheme = ThemeService.instance.currentColorScheme;
        final mode = ThemeService.instance.currentThemeMode;
        final fontScale = ThemeService.instance.currentFontScale;

        return MaterialApp(
          title: 'Parwarish.ai',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.lightTheme(scheme: scheme).copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: AppTheme.darkTheme(scheme: scheme).copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(fontScale),
              ),
              child: child!,
            );
          },
          home: _determineInitialScreen(),
          routes: {
            '/therapist': (context) => const TherapistPortalScreen(),
            '/therapist_login': (context) => const TherapistLoginScreen(),
            '/parent': (context) => const ParentDashboard(),
            '/child_space': (context) => ChildProfileSelection(parentUid: AuthService.instance.currentUserUid),
            '/welcome': (context) => const WelcomeScreen(),
          },
        );
      },
    );
  }
}
