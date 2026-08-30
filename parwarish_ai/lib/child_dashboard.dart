import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'lesson_screen.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  String _autismLevel = 'Mild';
  String _childId = '';
  bool _isLoading = true;
  bool _isUrdu = false;
  int _selectedIndex = 0;

  final Set<int> _completedScheduleTasks = {};
  bool _isPetHappy = false;
  Timer? _happyTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _happyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autismLevel = prefs.getString('autism_level') ?? 'Mild';
      _childId = prefs.getString('child_id') ?? '';
      _isLoading = false;
    });
  }

  void _triggerHappyPet() {
    setState(() => _isPetHappy = true);
    _happyTimer?.cancel();
    _happyTimer = Timer(const Duration(minutes: 2), () {
      if (mounted) setState(() => _isPetHappy = false);
    });
  }

  List<Map<String, dynamic>> _getAdaptiveModules() {
    if (_autismLevel == 'Severe') {
      return [
        {'title': _isUrdu ? 'احساسات' : 'Emotions', 'icon': Icons.sentiment_very_satisfied, 'colors': [const Color(0xFF43CBFF), const Color(0xFF9708CC)], 'video': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4', 'enPrompt': 'Can you show me a happy face?', 'urPrompt': 'کیا آپ مجھے خوش چہرہ دکھا سکتے ہیں؟', 'type': 'camera'},
        {'title': _isUrdu ? 'باتھ روم' : 'Toilet', 'icon': Icons.wc, 'colors': [const Color(0xFFFF9A44), const Color(0xFFFC6076)], 'video': 'https://www.w3schools.com/html/mov_bbb.mp4', 'enPrompt': 'What do we do after using the toilet?', 'urPrompt': 'باتھ روم استعمال کرنے کے بعد ہم کیا کرتے ہیں؟', 'type': 'voice'},
        {'title': _isUrdu ? 'پرسکون' : 'Calm Down', 'icon': Icons.self_improvement, 'colors': [const Color(0xFF00C9FF), const Color(0xFF92FE9D)], 'video': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4', 'enPrompt': 'Let us take a deep breath. Can you do it?', 'urPrompt': 'آئیے لمبی سانس لیں۔ کیا آپ کر سکتے ہیں؟', 'type': 'breathe'},
      ];
    } else if (_autismLevel == 'Moderate') {
      return [
        {'title': _isUrdu ? 'ہاتھ دھونا' : 'Wash Hands', 'icon': Icons.clean_hands, 'colors': [const Color(0xFF1CB5E0), const Color(0xFF000851)], 'video': 'https://www.w3schools.com/html/mov_bbb.mp4', 'enPrompt': 'What do we use to wash our hands?', 'urPrompt': 'ہم ہاتھ دھونے کے لیے کیا استعمال کرتے ہیں؟', 'type': 'voice'},
        {'title': _isUrdu ? 'کپڑے پہننا' : 'Dress Up', 'icon': Icons.checkroom, 'colors': [const Color(0xFFF12711), const Color(0xFFF5AF19)], 'video': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4', 'enPrompt': 'What are we wearing today?', 'urPrompt': 'آج ہم کیا پہن رہے ہیں؟', 'type': 'voice'},
        {'title': _isUrdu ? 'کھانا' : 'Eat', 'icon': Icons.restaurant, 'colors': [const Color(0xFF11998E), const Color(0xFF38EF7D)], 'video': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4', 'enPrompt': 'What is your favorite food?', 'urPrompt': 'آپ کا پسندیدہ کھانا کون سا ہے؟', 'type': 'voice'},
      ];
    } else {
      return [
        {'title': _isUrdu ? 'جوتے باندھنا' : 'Tie Shoes', 'icon': Icons.roller_skating, 'colors': [const Color(0xFFFF512F), const Color(0xFFDD2476)], 'video': 'https://www.w3schools.com/html/mov_bbb.mp4', 'enPrompt': 'Can you show me how to tie a knot?', 'urPrompt': 'کیا آپ مجھے گرہ باندھنا سکھا سکتے ہیں؟', 'type': 'voice'},
        {'title': _isUrdu ? 'بال بنانا' : 'Brush Hair', 'icon': Icons.face, 'colors': [const Color(0xFF8A2387), const Color(0xFFE94057)], 'video': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4', 'enPrompt': 'Where is the hairbrush?', 'urPrompt': 'ہیئر برش کہاں ہے؟', 'type': 'voice'},
        {'title': _isUrdu ? 'کھانا' : 'Eat Properly', 'icon': Icons.restaurant_menu, 'colors': [const Color(0xFF11998E), const Color(0xFF38EF7D)], 'video': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4', 'enPrompt': 'What should we say after eating?', 'urPrompt': 'کھانے کے بعد ہمیں کیا کہنا چاہیے؟', 'type': 'voice'},
        {'title': _isUrdu ? 'بیک پیک' : 'Pack Bag', 'icon': Icons.backpack, 'colors': [const Color(0xFFF7971E), const Color(0xFFFFD200)], 'video': 'https://www.w3schools.com/html/mov_bbb.mp4', 'enPrompt': 'What goes inside the school bag?', 'urPrompt': 'اسکول کے بیگ میں کیا جاتا ہے؟', 'type': 'voice'},
      ];
    }
  }

  Widget _buildLearnTab(int crossAxisCount, List<Map<String, dynamic>> modules) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: modules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: crossAxisCount == 1 ? 2.6 : 1.3,
      ),
      itemBuilder: (context, index) {
        final module = modules[index];
        return GestureDetector(
          onTap: () async {
            final lessonFinished = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LessonScreen(
                  lessonTitle: module['title'],
                  videoUrl: module['video'],
                  englishPrompt: module['enPrompt'],
                  urduPrompt: module['urPrompt'],
                  interactionType: module['type'],
                  isUrdu: _isUrdu,
                ),
              ),
            );
            if (lessonFinished == true) _triggerHappyPet();
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: module['colors'],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: module['colors'][0].withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Adds breathing room from the edges
              child: FittedBox(
                fit: BoxFit.scaleDown, // Shrinks content only if it overflows
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(module['icon'], size: crossAxisCount == 1 ? 65 : 50, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        module['title'],
                        style: TextStyle(
                            fontSize: crossAxisCount == 1 ? 28 : 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2
                        )
                    ),
                  ],
                ),
              ),
            ),
          ).animate().scale(duration: 400.ms, delay: (index * 100).ms, curve: Curves.easeOutBack),
        );
      },
    );
  }

  Widget _buildScheduleTab() {
    final schedule = [
      {'time': _isUrdu ? 'صبح' : 'Morning', 'task': _isUrdu ? 'جاگنا اور برش کرنا' : 'Wake up & Brush', 'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFFFF9A44)},
      {'time': _isUrdu ? 'دوپہر' : 'Afternoon', 'task': _isUrdu ? 'سیکھنے کا وقت' : 'Learning Time', 'icon': Icons.auto_stories_rounded, 'color': const Color(0xFF43CBFF)},
      {'time': _isUrdu ? 'شام' : 'Evening', 'task': _isUrdu ? 'کھیلنے کا وقت' : 'Play Time', 'icon': Icons.toys_rounded, 'color': const Color(0xFF38EF7D)},
      {'time': _isUrdu ? 'رات' : 'Night', 'task': _isUrdu ? 'سونے کا وقت' : 'Sleep', 'icon': Icons.nights_stay_rounded, 'color': const Color(0xFF8A2387)},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        final item = schedule[index];
        final isCompleted = _completedScheduleTasks.contains(index);

        return Card(
          elevation: 8,
          shadowColor: (item['color'] as Color).withOpacity(0.3),
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 32),
            ),
            title: Text(item['time'] as String, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black45, fontSize: 16)),
            subtitle: Text(
                item['task'] as String,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.black26 : Colors.black87
                )
            ),
            trailing: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 40,
                color: isCompleted ? const Color(0xFF38EF7D) : Colors.black12,
              ),
              onPressed: () {
                setState(() {
                  isCompleted ? _completedScheduleTasks.remove(index) : _completedScheduleTasks.add(index);
                });
              },
            ),
          ),
        ).animate().slideX(duration: 400.ms, delay: (index * 100).ms, begin: 0.5, end: 0).fade();
      },
    );
  }

  Widget _buildAchievementsTab(int currentStreak) {
    final badges = [
      {'title': _isUrdu ? 'پہلا قدم' : 'First Step', 'req': 1, 'icon': Icons.star_rounded, 'color': const Color(0xFFFFD200)},
      {'title': _isUrdu ? 'اچھا کام' : 'Good Job', 'req': 5, 'icon': Icons.thumb_up_rounded, 'color': const Color(0xFF43CBFF)},
      {'title': _isUrdu ? 'شاندار' : 'Superstar', 'req': 10, 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFFF512F)},
      {'title': _isUrdu ? 'چیمپئن' : 'Champion', 'req': 20, 'icon': Icons.military_tech_rounded, 'color': const Color(0xFF9708CC)},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.75),
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isUnlocked = currentStreak >= (badge['req'] as int);
        final activeColor = badge['color'] as Color;

        return Container(
          decoration: BoxDecoration(
            color: isUnlocked ? activeColor.withOpacity(0.1) : Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isUnlocked ? activeColor : Colors.transparent, width: 4),
            boxShadow: isUnlocked ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(badge['icon'] as IconData, size: 70, color: isUnlocked ? activeColor : Colors.black12),
                  const SizedBox(height: 12),
                  Text(badge['title'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isUnlocked ? Colors.black87 : Colors.black26)),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: isUnlocked ? activeColor : Colors.black12,
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: Text('⭐ ${badge['req']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ).animate().scale(duration: 400.ms, delay: (index * 100).ms);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF4F7FC), body: Center(child: CircularProgressIndicator(color: Color(0xFFFF512F))));
    }

    final modules = _getAdaptiveModules();
    int crossAxisCount = _autismLevel == 'Severe' ? 1 : 2;

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('children').doc(_childId).snapshots(),
        builder: (context, snapshot) {
          int streak = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            streak = snapshot.data!.get('current_streak') ?? 0;
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF4F7FC),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF2B2D42),
              title: Text(_isUrdu ? 'میرا ڈیش بورڈ' : 'My Dashboard', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: TextButton(
                    onPressed: () => setState(() => _isUrdu = !_isUrdu),
                    child: Text(_isUrdu ? 'ENG' : 'اردو', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: const BoxDecoration(
                      color: Color(0xFF2B2D42),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        padding: const EdgeInsets.all(5),
                        child: SizedBox(
                          width: 90, height: 90,
                          child: Lottie.network(
                            _isPetHappy
                                ? 'https://lottie.host/933ebf99-a681-42db-98db-c88f3a3ad024/9xVfW55oXN.json'
                                : 'https://lottie.host/40375535-6fa4-46c3-9fae-6ed9f30b777a/sH3c3B1hP8.json',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 60, color: Color(0xFFFF9A44)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isUrdu ? 'آپ کا دوست' : 'Your Buddy', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFF5AF19)]),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [BoxShadow(color: const Color(0xFFFF512F).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]
                            ),
                            child: Text('⭐ Streak: $streak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildLearnTab(crossAxisCount, modules),
                      _buildScheduleTab(),
                      _buildAchievementsTab(streak),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))]
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  selectedItemColor: const Color(0xFFFF512F),
                  unselectedItemColor: Colors.grey[400],
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  items: [
                    BottomNavigationBarItem(icon: const Padding(padding: EdgeInsets.only(bottom: 5), child: Icon(Icons.play_lesson_rounded, size: 28)), label: _isUrdu ? 'سیکھیں' : 'Learn'),
                    BottomNavigationBarItem(icon: const Padding(padding: EdgeInsets.only(bottom: 5), child: Icon(Icons.schedule_rounded, size: 28)), label: _isUrdu ? 'شیڈول' : 'Schedule'),
                    BottomNavigationBarItem(icon: const Padding(padding: EdgeInsets.only(bottom: 5), child: Icon(Icons.emoji_events_rounded, size: 28)), label: _isUrdu ? 'انعامات' : 'Badges'),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}