import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/tts_service.dart';
import 'services/clinical_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/child/child_profile_selection.dart';
import 'screens/therapist/therapist_portal_screen.dart';
import 'screens/therapist/therapist_login_screen.dart';
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

  runApp(const ParwarishApp());
}

class ParwarishApp extends StatelessWidget {
  const ParwarishApp({super.key});

  Widget _determineInitialScreen() {
    final role = AuthService.instance.userRole;
    final defaultMode = AuthService.instance.defaultDeviceMode;
    if (role == 'therapist' || role == 'admin') {
      return const TherapistPortalScreen();
    } else if (role == 'parent' || defaultMode == 'parent') {
      return const ParentDashboard();
    } else if (role == 'child' || defaultMode == 'child') {
      return ChildProfileSelection(parentUid: AuthService.instance.currentUserUid);
    }
    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'Parwarish.ai',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData.copyWith(
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
          home: _determineInitialScreen(),
          routes: {
            '/therapist': (context) => const TherapistPortalScreen(),
            '/therapist_login': (context) => const TherapistLoginScreen(),
            '/parent': (context) => const ParentDashboard(),
            '/welcome': (context) => const WelcomeScreen(),
          },
        );
      },
    );
  }
}
