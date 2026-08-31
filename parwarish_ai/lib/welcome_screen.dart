import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'child_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B2D42), Color(0xFF8D99AE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 80, color: Color(0xFFFFD200))
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 1.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
              const SizedBox(height: 20),
              const Text(
                'Parwarish.ai',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),
              const SizedBox(height: 10),
              const Text(
                'Who is logging in?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 60),
              _buildRoleCard(
                context: context,
                title: 'I am a Child',
                icon: Icons.face_retouching_natural_rounded,
                colors: [const Color(0xFF43CBFF), const Color(0xFF9708CC)],
                role: 'child',
                delay: 500,
              ),
              const SizedBox(height: 25),
              _buildRoleCard(
                context: context,
                title: 'I am a Parent',
                icon: Icons.admin_panel_settings_rounded,
                colors: [const Color(0xFFFF9A44), const Color(0xFFFC6076)],
                role: 'parent',
                delay: 700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required BuildContext context, required String title, required IconData icon, required List<Color> colors, required String role, required int delay}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChildLoginScreen(role: role))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: colors[0].withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    ).animate().scale(delay: delay.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}