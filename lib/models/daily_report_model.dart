import 'package:cloud_firestore/cloud_firestore.dart';

class DailyReportModel {
  final String id;
  final String childId;
  final String childName;
  final DateTime reportDate;
  final String therapistName;
  final int goalsCompletedCount;
  final int totalDurationMinutes;
  final String primaryMood; // 'Happy', 'Calm', 'Focused', 'Excited'
  final List<String> strengthsObserved;
  final String therapistNotes;
  final String homeActivityTip;
  final DateTime createdAt;

  const DailyReportModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.reportDate,
    required this.therapistName,
    required this.goalsCompletedCount,
    required this.totalDurationMinutes,
    required this.primaryMood,
    required this.strengthsObserved,
    required this.therapistNotes,
    required this.homeActivityTip,
    required this.createdAt,
  });

  factory DailyReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DailyReportModel.fromMap(doc.id, data);
  }

  factory DailyReportModel.fromMap(String id, Map<String, dynamic> map) {
    return DailyReportModel(
      id: id,
      childId: map['child_id'] as String? ?? '',
      childName: map['child_name'] as String? ?? 'Hero',
      reportDate: _parseTimestamp(map['report_date']),
      therapistName: map['therapist_name'] as String? ?? 'Dr. Specialist',
      goalsCompletedCount: (map['goals_completed_count'] as num?)?.toInt() ?? 0,
      totalDurationMinutes: (map['total_duration_minutes'] as num?)?.toInt() ?? 0,
      primaryMood: map['primary_mood'] as String? ?? 'Happy',
      strengthsObserved: (map['strengths_observed'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      therapistNotes: map['therapist_notes'] as String? ?? 'Wonderful progress today!',
      homeActivityTip: map['home_activity_tip'] as String? ?? 'Practice gentle hand gestures before bedtime.',
      createdAt: _parseTimestamp(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'child_name': childName,
      'report_date': Timestamp.fromDate(reportDate),
      'therapist_name': therapistName,
      'goals_completed_count': goalsCompletedCount,
      'total_duration_minutes': totalDurationMinutes,
      'primary_mood': primaryMood,
      'strengths_observed': strengthsObserved,
      'therapist_notes': therapistNotes,
      'home_activity_tip': homeActivityTip,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }
}
