import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/child_profile.dart';
import '../../models/child_model.dart';
import '../../services/streak_service.dart';
import '../../services/localization_service.dart';
import 'child_dashboard.dart';
import '../../theme/app_theme.dart';
import '../welcome_screen.dart';

class ChildProfileSelection extends StatefulWidget {
  final String parentUid;

  const ChildProfileSelection({
    super.key,
    this.parentUid = 'parent_demo_01',
  });

  @override
  State<ChildProfileSelection> createState() => _ChildProfileSelectionState();
}

class _ChildProfileSelectionState extends State<ChildProfileSelection> {
  bool _isProcessing = false;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getChildrenStream() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance
            .collection('children')
            .where('parent_uid', isEqualTo: widget.parentUid)
            .snapshots();
      }
    } catch (e) {
      debugPrint('Firestore stream error: $e');
    }
    return null;
  }

  /// Fallback demo children if Firestore collection is empty or offline
  List<ChildProfile> _getFallbackChildren() {
    return [
      ChildProfile(
        id: 'child_demo_01',
        parentUid: widget.parentUid,
        name: 'Aayan',
        autismLevel: 'Mild',
        currentStreak: 4,
        lastLogin: DateTime.now().subtract(const Duration(days: 1)),
        struggleFlags: 0,
      ),
      ChildProfile(
        id: 'child_demo_02',
        parentUid: widget.parentUid,
        name: 'Zainab',
        autismLevel: 'Moderate',
        currentStreak: 2,
        lastLogin: DateTime.now().subtract(const Duration(days: 1)),
        struggleFlags: 1,
      ),
    ];
  }

  /// Determine deterministic secret buddy for each child
  String _getChildSecretBuddy(String childName) {
    switch (childName.toLowerCase()) {
      case 'aayan':
        return '🚀';
      case 'zainab':
        return '🌟';
      default:
        return '🦁';
    }
  }

  String _getChildSecretBuddyName(String childName) {
    switch (childName.toLowerCase()) {
      case 'aayan':
        return 'Rocket Buddy';
      case 'zainab':
        return 'Star Buddy';
      default:
        return 'Lion Buddy';
    }
  }

  /// Childish login unlock modal to prevent siblings from clicking each other's profile
  void _showSecretBuddyLoginDialog(ChildProfile child) {
    final expectedBuddy = _getChildSecretBuddy(child.name);
    final buddyOptions = [
      {'emoji': '🚀', 'name': 'Rocket Buddy'},
      {'emoji': '🌟', 'name': 'Star Buddy'},
      {'emoji': '🦁', 'name': 'Lion Buddy'},
      {'emoji': '🐬', 'name': 'Dolphin Buddy'},
    ];

    bool rememberDevice = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A11CB).withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Playful Child Greeting
                    Text(
                      '👋 Hi ${child.name}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap your Secret Buddy to unlock your space! 🎈',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4 playful buddy choices
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: buddyOptions.map((buddy) {
                        final emoji = buddy['emoji']!;
                        final isCorrect = emoji == expectedBuddy;

                        return InkWell(
                          key: Key('buddy_choice_$emoji'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            if (isCorrect) {
                              Navigator.of(dialogCtx).pop();
                              if (rememberDevice) {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('default_device_mode', 'child');
                                await prefs.setString('active_child_id', child.id);
                                await prefs.setString('active_child_name', child.name);
                              }
                              await _onChildSelected(child);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  content: Text(
                                    'Oops! That belongs to a sibling! Pick ${child.name}\'s buddy (${_getChildSecretBuddyName(child.name)})!',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 38),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  buddy['name']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // "Always open directly on this device" checkbox
                    CheckboxListTile(
                      value: rememberDevice,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF6A11CB),
                      title: Text(
                        'Keep ${child.name} logged in directly on this device',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          rememberDevice = val ?? true;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    // Parental Gate bypass
                    TextButton.icon(
                      icon: const Icon(Icons.lock_rounded, size: 14, color: AppTheme.textSecondary),
                      label: const Text(
                        'Parent Gate Bypass',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        _showParentalGate();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Parental Gate: quick adult verification to switch mode or bypass
  void _showParentalGate() {
    int num1 = 7;
    int num2 = 4;
    int answer = num1 + num2;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (gateCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF6A11CB)),
              SizedBox(width: 8),
              Text('Parent Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please solve this simple math question to proceed to Parent Portal:'),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '$num1 + $num2 = ?',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF6A11CB)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Answer',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(gateCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A11CB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (int.tryParse(controller.text.trim()) == answer) {
                  Navigator.of(gateCtx).pop();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('default_device_mode', 'parent');
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect answer. Access denied.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// When child card is tapped:
  /// 1. Call StreakService.checkAndUpdateStreak() with child ID & doc ref
  /// 2. Save child_id, child_name to SharedPreferences
  /// 3. Navigate to ChildDashboard
  Future<void> _onChildSelected(ChildProfile child) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    int updatedStreak = child.currentStreak;

    try {
      if (Firebase.apps.isNotEmpty) {
        final childDocRef =
            FirebaseFirestore.instance.collection('children').doc(child.id);
        updatedStreak = await StreakService.checkAndUpdateStreak(
          childId: child.id,
          childDocRef: childDocRef,
        );
      } else {
        updatedStreak = StreakService.calculateNewStreak(
          lastLogin: child.lastLogin ?? DateTime.now().subtract(const Duration(days: 1)),
          currentStreak: child.currentStreak,
        );
      }
    } catch (e) {
      debugPrint('Firestore streak update fallback: $e');
      updatedStreak = StreakService.calculateNewStreak(
        lastLogin: child.lastLogin ?? DateTime.now().subtract(const Duration(days: 1)),
        currentStreak: child.currentStreak,
      );
    }

    // Save child_id and child_name to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_id', child.id);
    await prefs.setString('child_name', child.name);
    await prefs.setString('autism_level', child.autismLevel);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChildDashboard(
            child: ChildModel(
              id: child.id,
              parentUid: child.parentUid,
              name: child.name,
              autismLevel: child.autismLevel,
              currentStreak: updatedStreak,
              lastLogin: DateTime.now(),
            ),
          ),
        ),
      );
    }
  }

  LinearGradient _getAvatarGradient(int index) {
    final gradients = [
      AppTheme.orangePinkGradient,
      AppTheme.blueCyanGradient,
      AppTheme.purpleBlueGradient,
      AppTheme.greenMintGradient,
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = LocalizationService.instance.isUrdu;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
            ),
            title: Text(
              isUrdu ? 'پروفائل منتخب کریں' : 'Who is Learning Today?',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.shield_outlined, color: AppTheme.textSecondary),
                tooltip: 'Parent Portal Gate',
                onPressed: _showParentalGate,
              ),
            ],
          ),
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getChildrenStream(),
              builder: (context, snapshot) {
                List<ChildProfile> children = [];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  children = snapshot.data!.docs.map((doc) {
                    return ChildProfile.fromFirestore(doc);
                  }).toList();
                } else if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                    ),
                  );
                } else {
                  // If query returns empty or Firestore is offline/unconfigured
                  children = _getFallbackChildren();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Friendly subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          isUrdu
                            ? 'اپنے بچے کا پروفائل منتخب کریں تاکہ تعلیمی روٹین شروع کی جا سکے'
                            : 'Select a child profile to resume gamified routines & streak progress',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Animated GridView of Child Cards
                      Expanded(
                        child: GridView.builder(
                          key: const Key('children_grid_view'),
                          itemCount: children.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemBuilder: (context, index) {
                            final child = children[index];
                            final gradient = _getAvatarGradient(index);

                            return _buildChildCard(
                              child: child,
                              gradient: gradient,
                              index: index,
                            );
                          },
                        ),
                      ),

                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryOrange),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildCard({
    required ChildProfile child,
    required LinearGradient gradient,
    required int index,
  }) {
    final buddy = _getChildSecretBuddy(child.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('child_card_${child.id}'),
        onTap: () => _showSecretBuddyLoginDialog(child),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with secret buddy badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Text(buddy, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Child Name
              Text(
                child.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Dignified Learner Badge & Streak Badge (No autism level)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, size: 12, color: Color(0xFF16A34A)),
                        SizedBox(width: 2),
                        Text(
                          'Star Explorer',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 12, color: Color(0xFFF97316)),
                        const SizedBox(width: 2),
                        Text(
                          '${child.currentStreak}d',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (100 * index).ms, duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }
}
