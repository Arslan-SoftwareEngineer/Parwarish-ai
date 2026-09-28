import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/localization_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth/child_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _handleSpaceSelection(BuildContext context, {required bool isParent}) async {
    final mode = isParent ? 'parent' : 'child';
    final prefs = await SharedPreferences.getInstance();
    // 1-Time Space Selection Configuration
    await prefs.setString('selected_device_space', mode);
    await AuthService.instance.setDefaultDeviceMode(mode);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChildLoginScreen(isParentLogin: isParent),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, locale, _) {
        final tr = LocalizationService.instance.tr;
        final isUrdu = LocalizationService.instance.isUrdu;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                child: SingleChildScrollView(
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
                              color: Theme.of(context).cardColor,
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
                                color: Theme.of(context).cardColor,
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

                      const SizedBox(height: 16),

                      // App Branding
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                                .animate()
                                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                                .shimmer(delay: 700.ms, duration: 1400.ms),
                            const SizedBox(height: 14),
                            Text(
                              'Parwarish.ai',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [Color(0xFF1E293B), Color(0xFF6A11CB)],
                                  ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                              ),
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                isUrdu
                                    ? 'بچوں کے لیے تفریحی روٹینز اور والدین کے لیے جامع رہنمائی'
                                    : 'Adaptive Routine Mastery & Nurturing Parent Intelligence',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // First-time Installation Guidelines Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isUrdu
                                        ? 'پہلی بار انسٹالیشن کی رہنمائی (اہم)'
                                        : 'First-Time Installation Guidelines',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isUrdu
                                  ? 'براہ کرم اس ڈیوائس کے لیے چائلڈ اسپیس یا پیرنٹ پورٹل کا انتخاب کریں۔ یہ انتخاب صرف ایک بار فراہم کیا جاتا ہے۔ اس کے بعد ایپ ہر بار خودکار طریقے سے آپ کی منتخب کردہ اسپیس کھولے گی۔ والدین بعد میں سیٹنگز میں پیرنٹ پاس ورڈ کے ذریعے اسپیس تبدیل کر سکتے ہیں۔'
                                  : 'Please choose whether this device is for Child Space or Parent Portal. This setup is provided ONCE on this device. Afterwards, the app will automatically open directly into your chosen space every time you launch it. Parents can modify this later inside Settings using parent credentials.',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                      const SizedBox(height: 20),

                      // Two Primary High-Contrast Buttons
                      // 1. Parent Portal Button
                      _buildGatewayButton(
                        context: context,
                        key: const Key('parent_portal_btn'),
                        title: tr('parent_portal'),
                        subtitle: isUrdu
                            ? 'پیش رفت، شیڈول اور تھراپسٹ رپورٹ تک رسائی (خودکار لاگ ان سیٹ اپ)'
                            : 'Set this device permanently as Parent Portal & Analytics',
                        icon: Icons.supervisor_account_rounded,
                        gradient: AppTheme.purpleBlueGradient,
                        shadowColor: const Color(0xFF6A11CB).withOpacity(0.35),
                        onTap: () => _handleSpaceSelection(context, isParent: true),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 14),

                      // 2. Child Space Button
                      _buildGatewayButton(
                        context: context,
                        key: const Key('child_space_btn'),
                        title: tr('child_space'),
                        subtitle: isUrdu
                            ? 'روٹین گیمز، سانس کی ورزش اور اینیمیشنز (بچے کا ڈیوائس)'
                            : 'Set this device permanently as Child Space for routines & games',
                        icon: Icons.rocket_launch_rounded,
                        gradient: AppTheme.orangePinkGradient,
                        shadowColor: AppTheme.primaryPink.withOpacity(0.35),
                        onTap: () => _handleSpaceSelection(context, isParent: false),
                      ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 20),

                      // Footer note
                      Center(
                        child: Text(
                          'Empowering neurodivergent growth with privacy first',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.88),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
