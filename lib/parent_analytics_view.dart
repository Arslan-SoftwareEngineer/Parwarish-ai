import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/child_model.dart';
import 'models/daily_report_model.dart';
import 'models/goal_record_model.dart';
import 'services/therapist_service.dart';
import 'services/localization_service.dart';
import 'theme/app_theme.dart';

class ParentAnalyticsView extends StatefulWidget {
  final ChildModel child;

  const ParentAnalyticsView({super.key, required this.child});

  @override
  State<ParentAnalyticsView> createState() => _ParentAnalyticsViewState();
}

class _ParentAnalyticsViewState extends State<ParentAnalyticsView> {
  List<DailyReportModel> _reports = [];
  List<GoalRecordModel> _goalRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final reports = await TherapistService.instance.getDailyReportsForChild(widget.child.id);
    final records = await TherapistService.instance.getGoalRecordsForChild(widget.child.id);
    setState(() {
      _reports = reports;
      _goalRecords = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final missionsCompleted = _goalRecords.isNotEmpty ? _goalRecords.length : 3;
    final totalPlayTimeMinutes = missionsCompleted * 5;

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, lang, _) {
        final tr = LocalizationService.instance.tr;
        final isUrdu = LocalizationService.instance.isUrdu;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            title: Text('${widget.child.name} - ${tr('analytics_title')}'),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Child Header Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: AppTheme.orangePinkGradient,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: AppTheme.heavyShadow(AppTheme.primaryOrange),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Text(
                                  widget.child.name.isNotEmpty ? widget.child.name[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.child.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isUrdu ? 'بہادر سپر چیمپیئن 🌟' : 'Super Star Explorer 🌟',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 20),

                        // Metrics Row
                        Row(
                          children: [
                            // Total Active Learning Time
                            Expanded(
                              child: _buildMetricCard(
                                title: tr('total_play_time'),
                                value: '$totalPlayTimeMinutes',
                                unit: tr('mins'),
                                icon: Icons.timer_rounded,
                                gradient: AppTheme.blueCyanGradient,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Missions Completed
                            Expanded(
                              child: _buildMetricCard(
                                title: tr('modules_completed'),
                                value: '$missionsCompleted',
                                unit: 'Missions',
                                icon: Icons.star_rounded,
                                gradient: AppTheme.greenMintGradient,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Current Streak
                            Expanded(
                              child: _buildMetricCard(
                                title: tr('current_streak'),
                                value: '${widget.child.currentStreak}',
                                unit: tr('days'),
                                icon: Icons.local_fire_department_rounded,
                                gradient: AppTheme.orangePinkGradient,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Daily Strengths Observed Section
                        Row(
                          children: [
                            const Icon(Icons.psychology_rounded, color: AppTheme.amberGold, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              tr('daily_strengths'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: AppTheme.softCardShadow,
                          ),
                          child: Column(
                            children: [
                              _buildStrengthRow(Icons.sentiment_very_satisfied_rounded, 'High Joy & Enthusiasm during mirror smile tasks', AppTheme.primaryOrange),
                              const Divider(height: 20),
                              _buildStrengthRow(Icons.clean_hands_rounded, 'Mastered step-by-step physical handwashing sequence', AppTheme.mintGreen),
                              const Divider(height: 20),
                              _buildStrengthRow(Icons.air_rounded, 'Peaceful sensory self-regulation during 4-count breathing', AppTheme.electricBlue),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Therapist Daily Reports Section
                        Row(
                          children: [
                            const Icon(Icons.note_alt_rounded, color: AppTheme.purpleStart, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              tr('daily_reports'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_reports.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: AppTheme.softCardShadow,
                            ),
                            child: Center(
                              child: Text(tr('no_reports_yet'), style: const TextStyle(color: AppTheme.textSecondary)),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _reports.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final report = _reports[index];

                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: AppTheme.softCardShadow,
                                  border: Border.all(color: AppTheme.purpleStart.withValues(alpha: 0.25), width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          report.therapistName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.mintGreen.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Mood: ${report.primaryMood} 😄',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.mintGreen),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
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
                                          const Icon(Icons.home_work_rounded, color: AppTheme.electricBlue, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${tr('home_tip')}: ${report.homeActivityTip}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStrengthRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.heavyShadow(gradient.colors.first, opacity: 0.3, blur: 14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
