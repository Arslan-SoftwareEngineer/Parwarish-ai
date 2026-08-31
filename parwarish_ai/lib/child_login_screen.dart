import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'child_profile_selection.dart';
import 'parent_dashboard.dart';

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
  bool _isLogin = true;

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential;

      if (_isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

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
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChildProfileSelection()));
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboard()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Explicitly instantiating with scopes forces the analyzer to link the factory constructor
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _handleSocialAuthSuccess(userCredential);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final OAuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _handleSocialAuthSuccess(userCredential);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Apple Sign-In failed: $e')));
    }
  }

  Future<void> _handleSocialAuthSuccess(UserCredential userCredential) async {
    if (widget.role == 'parent') {
      final parentDoc = await FirebaseFirestore.instance.collection('parents').doc(userCredential.user!.uid).get();
      if (!parentDoc.exists) {
        await FirebaseFirestore.instance.collection('parents').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', widget.role);

    if (widget.role == 'child') {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChildProfileSelection()));
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboard()));
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

              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                  style: TextStyle(color: themeColors[1], fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Or continue with', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                ],
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    child: const Text('G', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                    onTap: _signInWithGoogle,
                  ),
                  const SizedBox(width: 25),
                  _buildSocialButton(
                    child: const Icon(Icons.apple_rounded, size: 34, color: Colors.black),
                    onTap: _signInWithApple,
                  ),
                ],
              ).animate().scale(delay: 900.ms, duration: 400.ms, curve: Curves.easeOutBack),
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

  Widget _buildSocialButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: child,
      ),
    );
  }
}