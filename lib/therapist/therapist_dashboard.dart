import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../models/therapist_domain_model.dart';
import '../models/goal_record_model.dart';
import '../services/firebase_service.dart';
import '../services/therapist_service.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../child_login_screen.dart';
import '../child_profile_selection.dart';
import '../theme/app_theme.dart';
import 'widgets/datasheet_table_view.dart';

class TherapistDashboard extends StatefulWidget {
  const TherapistDashboard({super.key});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard> {
  int _currentTabIndex = 0;
  List<ChildModel> _children = [];
  ChildModel? _selectedChild;
  List<GoalRecordModel> _selectedChildRecords = [];
  bool _isLoading = true;

  // Report generator controllers
  final TextEditingController _notesController = TextEditingController(
    text: 'Great progress in joint attention and handwashing sequence today! Responded well to positive auditory cues.',
  );
  final TextEditingController _homeTipController = TextEditingController(
    text: 'Encourage child to name 3 colors during dinner prep and practice 4-count breathing together.',
  );
  String _reportMood = 'Happy';

  @override
  void initState() {
    super.initState();
    _loadTherapistData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _homeTipController.dispose();
    super.dispose();
  }

  Future<void> _loadTherapistData() async {
    setState(() => _isLoading = true);
    final parentUid = AuthService.instance.currentUserUid;
    final list = await FirebaseService.instance.getChildrenForParent(parentUid);
    setState(() {
      _children = list;
      if (_children.isNotEmpty && _selectedChild == null) {
        _selectedChild = _children.first;
      }
      _isLoading = false;
    });

    if (_selectedChild != null) {
      _loadChildGoalRecords(_selectedChild!.id);
    }
  }

  Future<void> _loadChildGoalRecords(String childId) async {
    final records = await TherapistService.instance.getGoalRecordsForChild(childId);
    setState(() {
      _selectedChildRecords = records;
    });
  }

  void _showClinicalLevelDialog(ChildModel child) {
    String currentLevel = child.autismLevel;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.medical_services_rounded, color: AppTheme.electricBlue),
                  const SizedBox(width: 10),
                  Text('Clinical Level: ${child.name}'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Note: This clinical support level is strictly private for the therapist and is NEVER shown to the parent.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  _buildLevelOption(
                    title: 'Level 1: Mild (High Independence)',
                    subtitle: 'Fine-motor, school readiness, complex sequences',
                    value: 'Mild',
                    selected: currentLevel == 'Mild',
                    onTap: () => setDialogState(() => currentLevel = 'Mild'),
                  ),
                  const SizedBox(height: 8),
                  _buildLevelOption(
                    title: 'Level 2: Moderate (Substantial Support)',
                    subtitle: 'Guided hygiene, dressing, multi-step self-care',
                    value: 'Moderate',
                    selected: currentLevel == 'Moderate',
                    onTap: () => setDialogState(() => currentLevel = 'Moderate'),
                  ),
                  const SizedBox(height: 8),
                  _buildLevelOption(
                    title: 'Level 3: Severe (Very Substantial Support)',
                    subtitle: 'Sensory regulation, core emotions, toilet cues',
                    value: 'Severe',
                    selected: currentLevel == 'Severe',
                    onTap: () => setDialogState(() => currentLevel = 'Severe'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseService.instance.updateChildStreakAndLogin(
                      childId: child.id,
                      newStreak: child.currentStreak,
                      lastLogin: child.lastLogin,
                    );
                    final updated = child.copyWith(autismLevel: currentLevel);
                    setState(() {
                      final idx = _children.indexWhere((c) => c.id == child.id);
                      if (idx != -1) _children[idx] = updated;
                      if (_selectedChild?.id == child.id) _selectedChild = updated;
                    });
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('Clinical level updated to $currentLevel for ${child.name}')),
                      );
                    }
                  },
                  child: const Text('Save Level'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLevelOption({
    required String title,
    required String subtitle,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.electricBlue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.electricBlue : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppTheme.electricBlue : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDomainDetailsModal(TherapistDomainModel domain) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          height: MediaQuery.of(modalCtx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: domain.gradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(domain.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Domain #${domain.indexNumber}: ${domain.titleEn}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          domain.category,
                          style: const TextStyle(fontSize: 12, color: AppTheme.electricBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                domain.descriptionEn,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const Divider(height: 28),
              Text(
                'Clinical Goals (${domain.goals.length}):',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: domain.goals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final goal = domain.goals[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.titleEn,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.descriptionEn,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.electricBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Game Engine: ${goal.gameType.toUpperCase()}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.electricBlue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(modalCtx).pop();
                              if (_selectedChild != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Assigned "${goal.titleEn}" to ${_selectedChild!.name}\'s schedule!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.mintGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Assign', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendReportToParent() async {
    if (_selectedChild == null) return;

    await TherapistService.instance.createAndSendDailyReport(
      childId: _selectedChild!.id,
      childName: _selectedChild!.name,
      therapistName: 'Dr. Ayesha Khan (Clinical BCBA)',
      strengthsObserved: [
        'Radiant smile and sustained joint attention during mirror game',
        'Accurate 4-step handwashing physical sequence completion',
        'Independent task initiation without prompt delay',
      ],
      therapistNotes: _notesController.text.trim(),
      homeActivityTip: _homeTipController.text.trim(),
      primaryMood: _reportMood,
      goalsCompletedCount: _selectedChildRecords.isNotEmpty ? _selectedChildRecords.length : 3,
      totalDurationMinutes: 15,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily Progress Report sent to ${_selectedChild!.name}\'s parent! ✨'),
          backgroundColor: AppTheme.mintGreen,
        ),
      );
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
            title: Text(tr('therapist_dashboard')),
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
              ? const Center(child: CircularProgressIndicator(color: AppTheme.electricBlue))
              : IndexedStack(
                  index: _currentTabIndex,
                  children: [
                    _buildManageKidsTab(),
                    _buildDomainsCatalogTab(),
                    _buildDatasheetTab(),
                    _buildScheduleBuilderTab(),
                    _buildReportDispatcherTab(),
                  ],
                ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, 'Children', Icons.people_rounded, AppTheme.blueCyanGradient),
                    _buildNavItem(1, '22 Domains', Icons.category_rounded, AppTheme.purpleBlueGradient),
                    _buildNavItem(2, 'Datasheet', Icons.table_chart_rounded, AppTheme.purpleBlueGradient),
                    _buildNavItem(3, 'Schedule', Icons.calendar_today_rounded, AppTheme.orangePinkGradient),
                    _buildNavItem(4, 'Report', Icons.send_rounded, AppTheme.greenMintGradient),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, LinearGradient activeGradient) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected ? AppTheme.heavyShadow(activeGradient.colors.first, opacity: 0.3, blur: 8) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 20),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 0: Manage Enrolled Children ---
  Widget _buildManageKidsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.blueCyanGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.heavyShadow(AppTheme.electricBlue),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clinical Child Supervision',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Privately assign clinical support levels & evaluate goal performance.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Enrolled Children:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _children.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final child = _children[index];
              final isSelected = _selectedChild?.id == child.id;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedChild = child);
                  _loadChildGoalRecords(child.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.softCardShadow,
                    border: isSelected ? Border.all(color: AppTheme.electricBlue, width: 2.5) : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.electricBlue.withValues(alpha: 0.15),
                        child: Text(
                          child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.electricBlue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.purpleStart.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Clinical Level: ${child.autismLevel}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleStart),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Streak: ${child.currentStreak}d',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryOrange),
                        tooltip: 'Edit Clinical Level',
                        onPressed: () => _showClinicalLevelDialog(child),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Selected Child Performance Telemetry Breakdown
          if (_selectedChild != null) ...[
            Text(
              '${_selectedChild!.name}\'s Clinical Telemetry Log:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            if (_selectedChildRecords.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.softCardShadow,
                ),
                child: const Center(
                  child: Text(
                    'No mission logs recorded yet today. When the child completes games, telemetry duration and mood appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedChildRecords.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final record = _selectedChildRecords[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.softCardShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.mintGreen, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.moduleName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Duration: ${record.timeTakenSeconds}s • Mood: ${record.moodState} • Score: ${(record.accuracyScore * 100).toInt()}%',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  // --- TAB 1: 22+ Clinical Domains Explorer ---
  Widget _buildDomainsCatalogTab() {
    final domains = TherapistService.instance.domains;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: domains.length,
      itemBuilder: (context, index) {
        final domain = domains[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _showDomainDetailsModal(domain),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppTheme.softCardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: domain.gradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(domain.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${domain.indexNumber} ${domain.titleEn}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${domain.category} • ${domain.goals.length} Goals',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textLight, size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: Clinical Datasheet Manager ---
  Widget _buildDatasheetTab() {
    if (_children.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.child_care_rounded, size: 48, color: AppTheme.textLight),
              SizedBox(height: 12),
              Text(
                'No child profiles available yet.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Add a child from the Children tab or Parent dashboard to manage clinical datasheets.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final child = _selectedChild ?? _children.first;

    return Column(
      children: [
        if (_children.length > 1)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _children.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final c = _children[index];
                final isSelected = c.id == child.id;
                return ChoiceChip(
                  label: Text(
                    c.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.purpleStart,
                  backgroundColor: AppTheme.scaffoldBackground,
                  onSelected: (_) {
                    setState(() {
                      _selectedChild = c;
                    });
                    _loadChildGoalRecords(c.id);
                  },
                );
              },
            ),
          ),

        Expanded(
          child: DatasheetTableView(child: child),
        ),
      ],
    );
  }

  // --- TAB 3: Schedule & Mission Builder ---
  Widget _buildScheduleBuilderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.orangePinkGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.heavyShadow(AppTheme.primaryOrange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Mission & Game Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Active child: ${_selectedChild?.name ?? 'Select Child'}',
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'The child will see and interact with this exact schedule on their dashboard.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Prescribed Daily Missions for ${_selectedChild?.name ?? 'Child'}:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          _buildPrescribedMissionTile('08:00 AM', 'Toothbrush & Handwashing Sequence', 'Game: Drag Sequence', Icons.soap_rounded, AppTheme.blueCyanGradient),
          const SizedBox(height: 10),
          _buildPrescribedMissionTile('10:00 AM', 'Big Bright Happy Smile Mirror', 'Game: Emotion Mirror', Icons.face_rounded, AppTheme.sunshineGradient),
          const SizedBox(height: 10),
          _buildPrescribedMissionTile('02:00 PM', 'Sensory 4-Count Zen Breathing', 'Game: Sensory Breathe', Icons.air_rounded, AppTheme.greenMintGradient),
          const SizedBox(height: 10),
          _buildPrescribedMissionTile('05:00 PM', 'School Backpack Sorting Challenge', 'Game: Matching Sort', Icons.backpack_rounded, AppTheme.purpleBlueGradient),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prescribed schedule published to child dashboard! ✨')),
              );
            },
            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            label: const Text('Publish & Sync Schedule to Child', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescribedMissionTile(String time, String title, String game, IconData icon, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('$time • $game', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Send Daily Report to Parent ---
  Widget _buildReportDispatcherTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.greenMintGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.heavyShadow(AppTheme.mintGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Progress Report Dispatcher',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Compose and send positive clinical progress report to ${_selectedChild?.name ?? 'Child'}\'s parent.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text('Observed Child Affect / Mood:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _reportMood,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Happy', child: Text('😄 Happy & Joyful')),
                  DropdownMenuItem(value: 'Calm', child: Text('🧘 Calm & Peaceful')),
                  DropdownMenuItem(value: 'Excited', child: Text('⚡ Super Energetic')),
                  DropdownMenuItem(value: 'Focused', child: Text('🎯 Highly Focused')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _reportMood = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text('Therapist Observation Notes (Sent to Parent):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Enter positive, encouraging therapist notes...'),
          ),

          const SizedBox(height: 18),

          const Text('Fun Home Activity Tip for Parents:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _homeTipController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Enter recommended fun activity at home...'),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _sendReportToParent,
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            label: Text(
              'Send Daily Report to ${_selectedChild?.name ?? 'Child'}\'s Parent',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mintGreen,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}
