import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_dashboard.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _verifyAndLogin() async {
    final code = _idController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('children').doc(code).get();

      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Code not found. Please check with parent.';
        });
        return;
      }

      // Save locally so child stays logged in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('child_id', code);
      await prefs.setString('role', 'child');
      await prefs.setString('autism_level', doc.data()?['autism_level'] ?? 'Mild');

      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, ${doc.data()?['name']}!')),
      );

      // Navigate to Dashboard and remove the login screen from history
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChildDashboard()),
      );
    } catch (e) {
      // The missing catch block is restored here
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Enter Child Code'),
        backgroundColor: const Color(0xFFFF8C00),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Color(0xFFFF8C00)),
            const SizedBox(height: 20),
            TextField(
              controller: _idController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'ABC123',
                counterText: '',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _verifyAndLogin,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Start Adventure!', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}