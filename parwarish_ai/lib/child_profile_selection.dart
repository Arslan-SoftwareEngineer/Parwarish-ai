import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'child_dashboard.dart';

class ChildProfileSelection extends StatelessWidget {
  const ChildProfileSelection({super.key});

  Future<void> _selectProfile(BuildContext context, String childId, String autismLevel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_id', childId);
    await prefs.setString('autism_level', autismLevel);

    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChildDashboard()));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Who is playing?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').where('parent_uid', isEqualTo: user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF43CBFF)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No profiles found.\nAsk your parent to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return GestureDetector(
                onTap: () => _selectProfile(context, doc.id, doc['autism_level']),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF43CBFF), Color(0xFF9708CC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF9708CC).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.face_retouching_natural_rounded, size: 45, color: Colors.white),
                      ),
                      const SizedBox(height: 15),
                      Text(doc['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ).animate().scale(delay: (index * 100).ms, duration: 400.ms, curve: Curves.easeOutBack);
            },
          );
        },
      ),
    );
  }
}