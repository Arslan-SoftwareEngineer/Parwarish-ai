import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/child_model.dart';
import 'models/daily_report_model.dart';
import 'services/firebase_service.dart';
import 'services/therapist_service.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'parent_analytics_view.dart';
import 'child_profile_selection.dart';
import 'child_login_screen.dart';
import 'theme/app_theme.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  List<ChildModel> _children = [];
  List<DailyReportModel> _recentReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final uid = AuthService.instance.currentUserUid;
    final list = await FirebaseService.instance.getChildrenForParent(uid);

    List<DailyReportModel> reports = [];
    if (list.isNotEmpty) {
      reports = await TherapistService.instance.getDailyReportsForChild(list.first.id);
    }

    setState(() {
      _children = list;
      _recentReports = reports;
      _isLoading = false;
    });
  }

  void _showAddChildDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final tr = LocalizationService.instance.tr;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.orangePinkGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                tr('add_child'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add your child’s name to start their joyful learning adventure:',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: tr('child_name'),
                  prefixIcon: const Icon(Icons.favorite_rounded, color: AppTheme.primaryOrange),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final parentUid = AuthService.instance.currentUserUid;
                await FirebaseService.instance.createChild(
                  parentUid: parentUid,
                  name: nameController.text.trim(),
                  autismLevel: 'Mild', // default baseline, therapist adjusts privately
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                _loadDashboardData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(tr('save_child')),
            ),
          ],
        );
      },
    );
  }

  LinearGradient _getPositiveGradient(int index) {
    switch (index % 3) {
      case 0:
        return AppTheme.orangePinkGradient;
      case 1:
        return AppTheme.blueCyanGradient;
      default:
        return AppTheme.greenMintGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, lang, _) {
        final tr = LocalizationService.instance.tr;
        final isUrdu = LocalizationService.instance.isUrdu;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            title: Text(tr('parent_dashboard')),
            actions: [
              IconButton(
                tooltip: 'Toggle Language',
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Text(
                    isUrdu ? 'EN' : 'اردو',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryOrange),
                  ),
                ),
                onPressed: () => LocalizationService.instance.toggleLanguage(),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) async {
                  if (val == 'switch_child') {
                    await AuthService.instance.cacheUserRole('child');
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ChildProfileSelection()),
                      );
                    }
                  } else if (val == 'logout') {
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ChildLoginScreen()),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'switch_child',
                    child: Row(
                      children: [
                        const Icon(Icons.child_care_rounded, color: AppTheme.electricBlue, size: 20),
                        const SizedBox(width: 10),
                        Text(tr('switch_role')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Text(tr('logout')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Positive Encouragement Header Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: AppTheme.sunshineGradient,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: AppTheme.heavyShadow(AppTheme.amberGold, opacity: 0.35),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('child_profiles'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isUrdu ? 'آپ کے بچوں کی روزانہ کی خوبیاں اور ادراک' : 'Celebrating daily milestones and unique strengths!',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // Section Title: Children Cards
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('child_profiles'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            Text(
                              '${_children.length} Active',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_children.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.softCardShadow,
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.sentiment_satisfied_rounded, size: 48, color: AppTheme.textLight),
                                  const SizedBox(height: 12),
                                  Text(
                                    tr('no_children_yet'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _children.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.92,
                            ),
                            itemBuilder: (context, index) {
                              final child = _children[index];
                              final gradient = _getPositiveGradient(index);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ParentAnalyticsView(child: child),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: gradient,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: AppTheme.heavyShadow(gradient.colors.first, opacity: 0.32, blur: 14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.white,
                                            child: Text(
                                              child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                                              style: TextStyle(
                                                color: gradient.colors.first,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.local_fire_department_rounded, color: AppTheme.amberGold, size: 14),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${child.currentStreak}d',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            child.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isUrdu ? 'شاندار چیمپیئن ✨' : 'Super Champion ✨',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.assessment_outlined, color: Colors.white, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                tr('analytics_title'),
                                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 28),

                        // Section Title: Daily Reports from Therapist
                        Row(
                          children: [
                            const Icon(Icons.mark_email_read_rounded, color: AppTheme.mintGreen, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              tr('daily_reports'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_recentReports.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.softCardShadow,
                            ),
                            child: Text(
                              tr('no_reports_yet'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentReports.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final report = _recentReports[index];

                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: AppTheme.softCardShadow,
                                  border: Border.all(color: AppTheme.mintGreen.withValues(alpha: 0.35), width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppTheme.mintGreen,
                                              child: Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              report.therapistName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.amberGold.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Mood: ${report.primaryMood} 😄',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryOrange),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      report.therapistNotes,
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.scaffoldBackground,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.lightbulb_rounded, color: AppTheme.amberGold, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Home Tip: ${report.homeActivityTip}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
                            },
                          ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddChildDialog,
            backgroundColor: AppTheme.primaryOrange,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              tr('add_child'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
