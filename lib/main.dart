import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/tts_service.dart';
import 'child_login_screen.dart';
import 'parent_dashboard.dart';
import 'child_profile_selection.dart';
import 'therapist/therapist_dashboard.dart';
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
  await TtsService.instance.init();

  runApp(const ParwarishApp());
}

class ParwarishApp extends StatelessWidget {
  const ParwarishApp({super.key});

  Widget _determineInitialScreen() {
    final role = AuthService.instance.userRole;
    if (role == 'therapist') {
      return const TherapistDashboard();
    } else if (role == 'parent') {
      return const ParentDashboard();
    } else if (role == 'child') {
      return const ChildProfileSelection();
    }
    return const ChildLoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'Parwarish.ai',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          home: _determineInitialScreen(),
        );
      },
    );
  }
}
