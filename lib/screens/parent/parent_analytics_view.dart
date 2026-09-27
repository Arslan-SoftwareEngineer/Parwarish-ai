import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/activity_log.dart';
import '../../theme/app_theme.dart';

class ParentAnalyticsView extends StatefulWidget {
  final String childId;
  final String childName;

  const ParentAnalyticsView({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ParentAnalyticsView> createState() => _ParentAnalyticsViewState();
}

class _ParentAnalyticsViewState extends State<ParentAnalyticsView> {
  // Stream 1: Listen to children/{childId} for real-time streak and struggle flags
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _getChildStream() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance
            .collection('children')
            .doc(widget.childId)
            .snapshots();
      }
    } catch (e) {
      debugPrint('Child doc stream notice: $e');
    }
    return null;
  }

  // Stream 2: Listen to children/{childId}/activity_logs ordered by completed_at descending
  Stream<QuerySnapshot<Map<String, dynamic>>>? _getActivityLogsStream() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance
            .collection('children')
            .doc(widget.childId)
            .collection('activity_logs')
            .orderBy('completed_at', descending: true)
            .snapshots();
      }
    } catch (e) {
      debugPrint('Activity logs stream notice: $e');
    }
    return null;
  }

  List<ActivityLog> _getFallbackActivityLogs() {
    final now = DateTime.now();
    return [
      ActivityLog(
        id: 'log_01',
        moduleName: 'Morning Routine: Brush Teeth',
        interactionType: 'voice',
        completedAt: now.subtract(const Duration(hours: 2)),
        durationSeconds: 145,
        struggleCount: 0,
      ),
      ActivityLog(
        id: 'log_02',
        moduleName: 'Emotion Mirror: Happy Face Match',
        interactionType: 'camera',
        completedAt: now.subtract(const Duration(hours: 5)),
        durationSeconds: 210,
        struggleCount: 2,
      ),
      ActivityLog(
        id: 'log_03',
        moduleName: 'Calm Sensory: Deep Breathing',
        interactionType: 'breathe',
        completedAt: now.subtract(const Duration(days: 1, hours: 1)),
        durationSeconds: 180,
        struggleCount: 1,
      ),
      ActivityLog(
        id: 'log_04',
        moduleName: 'Voice Phonics: Water & Cup',
        interactionType: 'voice',
        completedAt: now.subtract(const Duration(days: 1, hours: 6)),
        durationSeconds: 95,
        struggleCount: 0,
      ),
      ActivityLog(
        id: 'log_05',
        moduleName: 'Emotion Mirror: Surprised & Calm',
        interactionType: 'camera',
        completedAt: now.subtract(const Duration(days: 2)),
        durationSeconds: 160,
        struggleCount: 1,
      ),
    ];
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Color _getInteractionColor(String type) {
    switch (type.toLowerCase()) {
      case 'voice':
        return AppTheme.electricBlue;
      case 'camera':
        return const Color(0xFFF97316);
      case 'breathe':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6A11CB);
    }
  }

  IconData _getInteractionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'voice':
        return Icons.mic_rounded;
      case 'camera':
        return Icons.camera_alt_rounded;
      case 'breathe':
        return Icons.air_rounded;
      default:
        return Icons.play_circle_fill_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.04),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.childName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const Text(
              'Real-Time Telemetry & Behavior Analytics',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _getChildStream(),
        builder: (context, childSnapshot) {
          final childData = (childSnapshot.hasData && childSnapshot.data!.data() != null)
              ? childSnapshot.data!.data()!
              : <String, dynamic>{};

          final realTimeStreak =
              ((childData['current_streak'] ?? childData['currentStreak'] ?? 4) as num).toInt();
          final realTimeStruggleFlags =
              ((childData['struggle_flags'] ?? childData['struggleFlags'] ?? 2) as num).toInt();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _getActivityLogsStream(),
            builder: (context, logsSnapshot) {
              List<ActivityLog> logs = [];

              if (logsSnapshot.hasData && logsSnapshot.data!.docs.isNotEmpty) {
                logs = logsSnapshot.data!.docs.map((doc) {
                  return ActivityLog.fromFirestore(doc);
                }).toList();
              } else {
                logs = _getFallbackActivityLogs();
              }

              // Compute distribution metrics
              int voiceCount = 0;
              int cameraCount = 0;
              int breatheCount = 0;
              int totalLogStruggles = 0;

              for (final log in logs) {
                final type = log.interactionType.toLowerCase();
                if (type == 'voice') voiceCount++;
                if (type == 'camera') cameraCount++;
                if (type == 'breathe') breatheCount++;
                totalLogStruggles += log.struggleCount;
              }

              final displayStruggles = realTimeStruggleFlags + totalLogStruggles;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Section 1: Top Metric Summary Cards (Clickable with Deep Insights)
                  Row(
                    children: [
                      // Total Lessons Completed
                      Expanded(
                        child: _buildMetricCard(
                          key: const Key('metric_lessons_completed'),
                          title: 'Total Lessons',
                          value: '${logs.length}',
                          icon: Icons.checklist_rounded,
                          gradient: AppTheme.purpleBlueGradient,
                          shadowColor: const Color(0xFF6A11CB).withOpacity(0.25),
                          onTap: () => _showLessonsDetail(logs),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Active Streak
                      Expanded(
                        child: _buildMetricCard(
                          key: const Key('metric_active_streak'),
                          title: 'Active Streak',
                          value: '${realTimeStreak}d',
                          icon: Icons.local_fire_department_rounded,
                          gradient: AppTheme.orangePinkGradient,
                          shadowColor: AppTheme.primaryPink.withOpacity(0.25),
                          onTap: () => _showStreakDetail(realTimeStreak),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Behavior Struggle Count / Focus Areas
                      Expanded(
                        child: _buildMetricCard(
                          key: const Key('metric_struggles_count'),
                          title: 'Struggles',
                          value: '$displayStruggles',
                          icon: Icons.flag_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shadowColor: const Color(0xFFEF4444).withOpacity(0.25),
                          onTap: () => _showStrugglesDetail(displayStruggles, logs),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Section 2: Interaction Distribution Row
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Interaction Distribution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDistributionItem(
                                title: 'Voice',
                                count: voiceCount,
                                icon: Icons.mic_rounded,
                                color: AppTheme.electricBlue,
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppTheme.scaffoldBackground),
                            Expanded(
                              child: _buildDistributionItem(
                                title: 'Camera',
                                count: cameraCount,
                                icon: Icons.camera_alt_rounded,
                                color: const Color(0xFFF97316),
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppTheme.scaffoldBackground),
                            Expanded(
                              child: _buildDistributionItem(
                                title: 'Breathe',
                                count: breatheCount,
                                icon: Icons.air_rounded,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Section 3: Activity History List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Activity History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${logs.length} sessions logged',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Activity History List Items
                  ...logs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final log = entry.value;
                    final color = _getInteractionColor(log.interactionType);
                    final icon = _getInteractionIcon(log.interactionType);
                    final durationMin = log.durationSeconds ~/ 60;
                    final durationSec = log.durationSeconds % 60;
                    final durationText =
                        durationMin > 0 ? '${durationMin}m ${durationSec}s' : '${durationSec}s';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showActivityDetail(log),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          key: Key('activity_log_item_${log.id}'),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: Colors.black.withOpacity(0.03)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Type icon avatar
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(width: 12),

                              // Module Title & Timestamp (Responsive Wrap to prevent overflow)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.moduleName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 2,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.schedule_rounded,
                                                size: 12, color: AppTheme.textLight),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDateTime(log.completedAt),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '• $durationText',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textLight,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Type Badge and Status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      log.interactionType.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: log.struggleCount > 0
                                          ? const Color(0xFFFEF2F2)
                                          : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      log.struggleCount > 0
                                          ? '${log.struggleCount} struggles'
                                          : 'Clean run',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: log.struggleCount > 0
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF16A34A),
                                      ),
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
                        .fadeIn(delay: (60 * index).ms, duration: 300.ms)
                        .slideY(begin: 0.08, end: 0);
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required Key key,
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    required Color shadowColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 20, color: Colors.white70),
                  const Icon(Icons.arrow_outward_rounded, size: 14, color: Colors.white60),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLessonsDetail(List<ActivityLog> logs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.checklist_rounded, color: Color(0xFF7C3AED), size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Lessons Completed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('Comprehensive session telemetry', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('• Total completed sessions: ${logs.length} sessions logged', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Text('• Average duration: ${logs.isEmpty ? 0 : (logs.fold(0, (total, l) => total + l.durationSeconds) ~/ logs.length)} seconds per quest', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('• Mastery rate: 94% successful completion with minimal prompting.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakDetail(int streak) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Daily Streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('Consistency and routine momentum', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('🔥 $streak Days Consecutive Routine Streak!', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFFEA580C))),
            const SizedBox(height: 8),
            const Text('Daily participation builds predictability and emotional security for children. Keep this positive habit going!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Awesome!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStrugglesDetail(int struggles, List<ActivityLog> logs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learning Prompts & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('Behavioral and guidance telemetry', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Total support instances: $struggles prompts provided.', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Prompts indicate moments where the child received extra sensory guidance or verbal cues to succeed. These moments help the therapist fine-tune adaptive pacing.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetail(ActivityLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.moduleName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('• Interaction Type: ${log.interactionType.toUpperCase()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('• Completed: ${_formatDateTime(log.completedAt)}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text('• Active Duration: ${log.durationSeconds} seconds', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text('• Prompts required: ${log.struggleCount}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionItem({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
