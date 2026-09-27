import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import 'auth/child_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, locale, _) {
        final tr = LocalizationService.instance.tr;
        final isUrdu = LocalizationService.instance.isUrdu;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Stack(
            children: [
              // Ambient Decorative Glows
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.electricBlue.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -60,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryOrange.withOpacity(0.12),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar with Language Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded, size: 16, color: AppTheme.mintGreen),
                                const SizedBox(width: 6),
                                Text(
                                  'Safe & Supervised',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Language switcher
                          InkWell(
                            key: const Key('language_toggle_btn'),
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              LocalizationService.instance.toggleLanguage();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.textLight.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language_rounded, size: 16, color: AppTheme.electricBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    isUrdu ? 'English' : 'اردو',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(flex: 1),

                      // App Branding
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                                .animate()
                                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                                .shimmer(delay: 800.ms, duration: 1500.ms),
                            const SizedBox(height: 18),
                            Text(
                              'Parwarish.ai',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [Color(0xFF1E293B), Color(0xFF6A11CB)],
                                  ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                isUrdu
                                    ? 'بچوں کے لیے تفریحی روٹینز اور والدین کے لیے جامع رہنمائی'
                                    : 'Adaptive Routine Mastery & Nurturing Parent Intelligence',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Two Primary High-Contrast Buttons
                      // 1. Parent Portal Button
                      _buildGatewayButton(
                        context: context,
                        key: const Key('parent_portal_btn'),
                        title: tr('parent_portal'),
                        subtitle: isUrdu
                            ? 'پیش رفت، شیڈول اور تھراپسٹ رپورٹ تک رسائی'
                            : 'Progress telemetry, clinical goals & therapy reports',
                        icon: Icons.supervisor_account_rounded,
                        gradient: AppTheme.purpleBlueGradient,
                        shadowColor: const Color(0xFF6A11CB).withOpacity(0.35),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChildLoginScreen(isParentLogin: true),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // 2. Child Space Button
                      _buildGatewayButton(
                        context: context,
                        key: const Key('child_space_btn'),
                        title: tr('child_space'),
                        subtitle: isUrdu
                            ? 'روٹین گیمز، سانس کی ورزش اور اینیمیشنز'
                            : 'Interactive routines, emotions mirror & companion pet',
                        icon: Icons.rocket_launch_rounded,
                        gradient: AppTheme.orangePinkGradient,
                        shadowColor: AppTheme.primaryPink.withOpacity(0.35),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChildLoginScreen(isParentLogin: false),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 450.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),

                      const Spacer(flex: 1),

                      // Footer note
                      Center(
                        child: Text(
                          'Empowering neurodivergent growth with privacy first',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGatewayButton({
    required BuildContext context,
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.88),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
