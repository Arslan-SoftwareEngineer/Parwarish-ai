import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'child_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ParwarishApp());
}

class ParwarishApp extends StatelessWidget {
  const ParwarishApp({super.key});

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role'); // Will return 'child', 'parent', or null
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parwarish.ai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF4CA1AF)),
      home: FutureBuilder<String?>(
        future: _getUserRole(),
        builder: (context, snapshot) {
          // 1. Still checking storage
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFF4CA1AF))),
            );
          }

          // 2. Found a saved role
          final role = snapshot.data;
          if (role == 'child') {
            return const ChildDashboard();
          } else if (role == 'parent') {
            // We will build ParentDashboard later, routing to Welcome for now
            return const WelcomeScreen();
          }

          // 3. First time opening the app
          return const WelcomeScreen();
        },
      ),
    );
  }
}