import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/child_profile.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';
import 'parent_analytics_view.dart';
import '../welcome_screen.dart';

import '../../services/notification_service.dart';
import '../settings/parent_settings_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final List<ChildProfile> _localFallbackChildren = [
    ChildProfile(
      id: 'child_01',
      parentUid: 'parent_demo_01',
      name: 'Aayan',
      autismLevel: 'Mild',
      currentStreak: 4,
      lastLogin: DateTime.now().subtract(const Duration(days: 1)),
      struggleFlags: 1,
    ),
    ChildProfile(
      id: 'child_02',
      parentUid: 'parent_demo_01',
      name: 'Zainab',
      autismLevel: 'Moderate',
      currentStreak: 2,
      lastLogin: DateTime.now().subtract(const Duration(days: 1)),
      struggleFlags: 3,
    ),
    ChildProfile(
      id: 'child_03',
      parentUid: 'parent_demo_01',
      name: 'Bilal',
      autismLevel: 'Severe',
      currentStreak: 6,
      lastLogin: DateTime.now().subtract(const Duration(days: 2)),
      struggleFlags: 5,
    ),
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getChildrenStream() {
    try {
      if (Firebase.apps.isNotEmpty) {
        final currentUid =
            FirebaseAuth.instance.currentUser?.uid ?? AuthService.instance.currentUserUid;
        return FirebaseFirestore.instance
            .collection('children')
            .where('parent_uid', isEqualTo: currentUid)
            .snapshots();
      }
    } catch (e) {
      debugPrint('Firestore stream notice: $e');
    }
    return null;
  }

  Future<void> _handleLogout() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}
    await AuthService.instance.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return ValueListenableBuilder<List<ParentNotification>>(
          valueListenable: ParentNotificationService.instance.notificationsNotifier,
          builder: (context, notifs, _) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: Color(0xFF6A11CB)),
                  SizedBox(width: 8),
                  Text('Security & Child Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: notifs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No alerts at this time. All child activities are normal.', textAlign: TextAlign.center),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final n = notifs[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              n.type == 'settings_access_attempt'
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_outline_rounded,
                              color: n.type == 'settings_access_attempt'
                                  ? Colors.amber.shade700
                                  : const Color(0xFF6A11CB),
                            ),
                            title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(n.message, style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
              actions: [
                if (notifs.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ParentNotificationService.instance.markAllAsRead();
                      ParentNotificationService.instance.clearAll();
                      Navigator.of(dialogCtx).pop();
                    },
                    child: const Text('Clear All'),
                  ),
                ElevatedButton(
                  onPressed: () {
                    ParentNotificationService.instance.markAllAsRead();
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  LinearGradient _getCardGradient(int index) {
    final gradients = [
      AppTheme.orangePinkGradient,
      AppTheme.greenMintGradient,
      AppTheme.blueCyanGradient,
      AppTheme.purpleBlueGradient,
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final user = Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    final parentEmail = user?.email ?? AuthService.instance.currentUserEmail;

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.05),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parent Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  parentEmail,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              // Notification Bell with unread counter
              ValueListenableBuilder<int>(
                valueListenable: ParentNotificationService.instance.unreadCountNotifier,
                builder: (context, unread, _) {
                  return IconButton(
                    key: const Key('parent_notifications_btn'),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                    ),
                    tooltip: 'Notifications & Alerts',
                    onPressed: _showNotificationsDialog,
                  );
                },
              ),
              // Settings Button
              IconButton(
                key: const Key('parent_settings_btn'),
                icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ParentSettingsScreen()),
                  );
                },
              ),
              IconButton(
                key: const Key('logout_button'),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                tooltip: 'Log Out',
                onPressed: _handleLogout,
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
                  ),
                );
              } else {
                children = _localFallbackChildren;
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Overview banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleBlueGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A11CB).withOpacity(0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Telemetry & Clinical Insights',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap any child below to view real-time learning metrics and behavioral telemetry',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Child Profiles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.textLight.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${children.length} registered',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Child Cards List
                  ...children.asMap().entries.map((entry) {
                    final index = entry.key;
                    final child = entry.value;
                    final avatarGradient = _getCardGradient(index);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: Key('child_card_${child.id}'),
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentAnalyticsView(
                                childId: child.id,
                                childName: child.name,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.black.withOpacity(0.03)),
                          ),
                          child: Row(
                            children: [
                              // Avatar circle
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: avatarGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Name & Developmental Milestone Badge
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.stars_rounded, size: 13, color: Color(0xFF7C3AED)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Active Explorer',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF6D28D9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Telemetry Badges (Streak & Active Goals)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Streak badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.local_fire_department_rounded,
                                          size: 15,
                                          color: Color(0xFFF97316),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${child.currentStreak}d streak',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFEA580C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Active Goals badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified_rounded,
                                          size: 13,
                                          color: Color(0xFF2563EB),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Goals Active',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.textLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (100 * index).ms, duration: 400.ms)
                        .slideX(begin: 0.1, end: 0);
                  }),

                  const SizedBox(height: 12),
                  // Clinical Therapist Supervision Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF0D9488), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Child enrollment and personalized routines are supervised and configured by your certified therapist & clinic.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
