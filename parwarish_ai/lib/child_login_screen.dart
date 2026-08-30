import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'child_dashboard.dart';

class ChildLoginScreen extends StatefulWidget {
  final String role;
  const ChildLoginScreen({super.key, required this.role});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; // Tracks whether the user is logging in or signing up

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential;

      if (_isLogin) {
        // Log in existing user
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Register new user
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Initialize a basic parent document in Firestore to prepare for the Parent Dashboard API
        if (widget.role == 'parent') {
          await FirebaseFirestore.instance.collection('parents').doc(userCredential.user!.uid).set({
            'email': _emailController.text.trim(),
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', widget.role);

      if (widget.role == 'child') {
        var doc = await FirebaseFirestore.instance.collection('children')
            .where('parent_uid', isEqualTo: userCredential.user!.uid)
            .limit(1)
            .get();

        if (doc.docs.isNotEmpty) {
          await prefs.setString('child_id', doc.docs.first.id);
          await prefs.setString('autism_level', doc.docs.first.get('autism_level') ?? 'Mild');
        }

        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChildDashboard()));
      } else {
        // Parent Dashboard placeholder
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parent Dashboard coming soon!')));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isChild = widget.role == 'child';
    List<Color> themeColors = isChild
        ? [const Color(0xFF43CBFF), const Color(0xFF9708CC)]
        : [const Color(0xFFFF9A44), const Color(0xFFFC6076)];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: themeColors[0])),
      extendBodyBehindAppBar: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isChild ? Icons.face_retouching_natural_rounded : Icons.admin_panel_settings_rounded, size: 100, color: themeColors[0])
                  .animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),

              Text(
                  isChild
                      ? (_isLogin ? 'Child Login' : 'Child Sign Up')
                      : (_isLogin ? 'Parent Login' : 'Parent Sign Up'),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: themeColors[1])
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, end: 0),

              const SizedBox(height: 40),
              _buildTextField(controller: _emailController, icon: Icons.email_rounded, label: 'Email', delay: 400),
              const SizedBox(height: 20),
              _buildTextField(controller: _passwordController, icon: Icons.lock_rounded, label: 'Password', isObscure: true, delay: 500),
              const SizedBox(height: 40),

              _isLoading
                  ? CircularProgressIndicator(color: themeColors[0])
                  : GestureDetector(
                onTap: _authenticate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: themeColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: themeColors[0].withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Center(
                      child: Text(
                          _isLogin ? 'Login' : 'Sign Up',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)
                      )
                  ),
                ),
              ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 20),

              // Toggle Button for Login/Sign Up
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                  style: TextStyle(color: themeColors[1], fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required IconData icon, required String label, bool isObscure = false, required int delay}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF2B2D42), width: 2)),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }
}