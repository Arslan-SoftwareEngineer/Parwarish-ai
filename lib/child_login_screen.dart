import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'parent_dashboard.dart';
import 'child_profile_selection.dart';
import 'therapist/therapist_dashboard.dart';
import 'theme/app_theme.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'parent@parwarish.ai');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');
  bool _isLoading = false;
  String _selectedRole = 'parent'; // 'parent', 'child', 'therapist'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await AuthService.instance.signInWithEmailPassword(
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRole,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      _routeToRoleDashboard();
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final success = await AuthService.instance.signInWithGoogle(role: _selectedRole);
    setState(() => _isLoading = false);

    if (success && mounted) {
      _routeToRoleDashboard();
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    final success = await AuthService.instance.signInWithApple(role: _selectedRole);
    setState(() => _isLoading = false);

    if (success && mounted) {
      _routeToRoleDashboard();
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() => _isLoading = true);
    await AuthService.instance.signInDemo(role: _selectedRole);
    setState(() => _isLoading = false);

    if (mounted) {
      _routeToRoleDashboard();
    }
  }

  void _routeToRoleDashboard() {
    if (_selectedRole == 'therapist') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TherapistDashboard()),
      );
    } else if (_selectedRole == 'parent') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ParentDashboard()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChildProfileSelection()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, lang, _) {
        final tr = LocalizationService.instance.tr;
        final isUrdu = LocalizationService.instance.isUrdu;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar: Language Toggle
                      Align(
                        alignment: Alignment.topRight,
                        child: OutlinedButton.icon(
                          onPressed: () => LocalizationService.instance.toggleLanguage(),
                          icon: const Icon(Icons.language_rounded, size: 18, color: AppTheme.primaryOrange),
                          label: Text(
                            isUrdu ? 'English' : 'اردو',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Logo & App Name Header
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            gradient: AppTheme.orangePinkGradient,
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.heavyShadow(AppTheme.primaryOrange, opacity: 0.4),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut)
                          .shimmer(duration: 1200.ms),

                      const SizedBox(height: 16),

                      Text(
                        tr('app_name'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 6),

                      Text(
                        tr('tagline'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Triple-Role Selector Tabs (Parent, Child, Therapist)
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppTheme.softCardShadow,
                        ),
                        child: Row(
                          children: [
                            // Parent Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRole = 'parent'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: _selectedRole == 'parent' ? AppTheme.orangePinkGradient : null,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    tr('parent_login'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _selectedRole == 'parent' ? Colors.white : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Child Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRole = 'child'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: _selectedRole == 'child' ? AppTheme.blueCyanGradient : null,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    tr('child_login'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _selectedRole == 'child' ? Colors.white : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Therapist Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRole = 'therapist'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: _selectedRole == 'therapist' ? AppTheme.purpleBlueGradient : null,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    isUrdu ? 'تھراپسٹ' : 'Therapist',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _selectedRole == 'therapist' ? Colors.white : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Input Fields
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: tr('email'),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryOrange),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: tr('password'),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryOrange),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sign In Button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleEmailLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRole == 'therapist'
                                ? AppTheme.purpleStart
                                : (_selectedRole == 'parent' ? AppTheme.primaryOrange : AppTheme.electricBlue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  tr('sign_in'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Social Logins Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Google Sign-In Button
                      OutlinedButton(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 26),
                            const SizedBox(width: 8),
                            Text(
                              tr('sign_in_with_google'),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Apple Sign-In Button
                      OutlinedButton(
                        onPressed: _isLoading ? null : _handleAppleLogin,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apple_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              tr('sign_in_with_apple'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Demo Quick Access Button
                      TextButton.icon(
                        onPressed: _isLoading ? null : _handleDemoLogin,
                        icon: const Icon(Icons.bolt_rounded, color: AppTheme.electricBlue),
                        label: Text(
                          tr('demo_login'),
                          style: const TextStyle(
                            color: AppTheme.electricBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
