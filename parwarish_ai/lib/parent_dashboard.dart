import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parent_analytics_view.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final User? parent = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  String _selectedLevel = 'Mild';

  void _showAddChildDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Child Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Child Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              decoration: InputDecoration(
                labelText: 'Autism Level',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              items: ['Mild', 'Moderate', 'Severe'].map((String level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9A44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('children').add({
                  'parent_uid': parent!.uid,
                  'name': _nameController.text.trim(),
                  'autism_level': _selectedLevel,
                  'created_at': FieldValue.serverTimestamp(),
                });
                _nameController.clear();
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Parent Dashboard', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.black87), onPressed: _logout),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('children')
            .where('parent_uid', isEqualTo: parent?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9A44)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.family_restroom_rounded, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text('No child profiles yet.', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ).animate().fadeIn(duration: 500.ms),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var childDoc = snapshot.data!.docs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF9A44), Color(0xFFFC6076)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF9A44).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.face_retouching_natural_rounded, color: Colors.white),
                  ),
                  title: Text(childDoc['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('Autism Level: ${childDoc['autism_level']}', style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ParentAnalyticsView(
                            childId: childDoc.id,
                            childName: childDoc['name'],
                          ),
                        ),
                      );
                    },
                ),
              ).animate().slideX(delay: (index * 100).ms, begin: 0.5, end: 0).fadeIn();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChildDialog,
        backgroundColor: const Color(0xFFFF9A44),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Child', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
    );
  }
}