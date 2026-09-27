import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'therapist_portal_screen.dart';

class TherapistLoginScreen extends StatefulWidget {
  const TherapistLoginScreen({super.key});

  @override
  State<TherapistLoginScreen> createState() => _TherapistLoginScreenState();
}

class _TherapistLoginScreenState extends State<TherapistLoginScreen> {
  final _emailController = TextEditingController(text: 'dr_ayesha@parwarish.ai');
  final _passwordController = TextEditingController(text: 'clinicalSecurePass123!');
  final _licenseController = TextEditingController(text: 'BCBA-PK-88492');
  String _selectedRole = 'therapist';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.instance.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        licenseNum: _licenseController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TherapistPortalScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Authentication failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleQuickDemo(String role) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedRole = role;
    });

    await AuthService.instance.signInDemo(role: role);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TherapistPortalScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate Clinical Navy
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Slate 800
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Medical / Clinical Portal Icon
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Subtitle
                const Text(
                  'Parwarish.ai Clinical Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Therapist & Clinical Administrator Gateway',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                    ),
                  ),

                // Role Selector Switch
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          key: const Key('role_therapist_tab'),
                          onTap: () => setState(() => _selectedRole = 'therapist'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'therapist' ? const Color(0xFF0D9488) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Therapist',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          key: const Key('role_admin_tab'),
                          onTap: () => setState(() => _selectedRole = 'admin'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'admin' ? const Color(0xFF0284C7) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Admin',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                const Text(
                  'Institutional Email',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('therapist_email_field'),
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(hint: 'dr_ayesha@parwarish.ai', icon: Icons.email_rounded),
                ),
                const SizedBox(height: 16),

                // License Number
                const Text(
                  'Clinical License / BCBA Number',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('therapist_license_field'),
                  controller: _licenseController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(hint: 'e.g. BCBA-PK-88492', icon: Icons.verified_user_rounded),
                ),
                const SizedBox(height: 16),

                // Password
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('therapist_password_field'),
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(hint: '••••••••••••', icon: Icons.lock_rounded),
                ),
                const SizedBox(height: 24),

                // Sign In Button
                ElevatedButton(
                  key: const Key('therapist_signin_button'),
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Access Clinical Workspace', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),

                // Quick One-Click Clinical Evaluation Shortcuts
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 12),
                const Text(
                  'Quick Demo Access & Gatekeeping Test',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('quick_therapist_btn'),
                        onPressed: () => _handleQuickDemo('therapist'),
                        icon: const Icon(Icons.medical_information_rounded, size: 16, color: Color(0xFF14B8A6)),
                        label: const Text('Therapist Demo', style: TextStyle(color: Color(0xFF14B8A6), fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0D9488)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('quick_admin_btn'),
                        onPressed: () => _handleQuickDemo('admin'),
                        icon: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFF38BDF8)),
                        label: const Text('Admin Demo', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Parent Gatekeeping Simulator button
                OutlinedButton.icon(
                  key: const Key('simulate_parent_btn'),
                  onPressed: () => _handleQuickDemo('parent'),
                  icon: const Icon(Icons.block_rounded, size: 16, color: Color(0xFFF87171)),
                  label: const Text('Simulate Parent Access (Test Rejection)', style: TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
      ),
    );
  }
}
