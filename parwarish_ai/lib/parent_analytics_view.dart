import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentAnalyticsView extends StatelessWidget {
  final String childId;
  final String childName;

  const ParentAnalyticsView({super.key, required this.childId, required this.childName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text('$childName\'s Progress', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatCard(title: 'Total Play Time', value: '14h 30m', icon: Icons.timer_rounded, delay: 100),
          const SizedBox(height: 15),
          _buildStatCard(title: 'Modules Completed', value: '24', icon: Icons.task_alt_rounded, delay: 200),
          const SizedBox(height: 15),
          _buildStatCard(title: 'Behavioral Score', value: '85%', icon: Icons.trending_up_rounded, delay: 300),
          const SizedBox(height: 30),
          const Text('Recent Milestones', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87))
              .animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 15),
          _buildMilestoneTile('Completed "Greetings" Module', '2 days ago', 500),
          _buildMilestoneTile('Maintained Focus for 15 mins', '4 days ago', 600),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required int delay}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF9A44), Color(0xFFFC6076)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFFF9A44).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        ],
      ),
    ).animate().slideX(delay: delay.ms, begin: 0.5, end: 0).fadeIn();
  }

  Widget _buildMilestoneTile(String title, String subtitle, int delay) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFFFC6076), child: Icon(Icons.star_rounded, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    ).animate().slideY(delay: delay.ms, begin: 0.3, end: 0).fadeIn();
  }
}