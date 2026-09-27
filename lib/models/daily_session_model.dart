import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an active goal assigned to a child by a therapist.
class ActiveGoalItem {
  final String goalId;
  final int domainId;
  final String domainName;
  final String goalTitle;
  final DateTime assignedAt;
  final String targetStatus; // 'active' | 'completed' | 'paused'

  const ActiveGoalItem({
    required this.goalId,
    required this.domainId,
    required this.domainName,
    required this.goalTitle,
    required this.assignedAt,
    this.targetStatus = 'active',
  });

  factory ActiveGoalItem.fromMap(Map<String, dynamic> map) {
    return ActiveGoalItem(
      goalId: (map['goal_id'] ?? map['goalId'] ?? '') as String,
      domainId: ((map['domain_id'] ?? map['domainId'] ?? 1) as num).toInt(),
      domainName: (map['domain_name'] ?? map['domainName'] ?? '') as String,
      goalTitle: (map['goal_title'] ?? map['goalTitle'] ?? '') as String,
      assignedAt: _parseDateTime(map['assigned_at'] ?? map['assignedAt']) ?? DateTime.now(),
      targetStatus: (map['target_status'] ?? map['targetStatus'] ?? 'active') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_id': goalId,
      'domain_id': domainId,
      'domain_name': domainName,
      'goal_title': goalTitle,
      'assigned_at': Timestamp.fromDate(assignedAt),
      'target_status': targetStatus,
    };
  }

  ActiveGoalItem copyWith({
    String? goalId,
    int? domainId,
    String? domainName,
    String? goalTitle,
    DateTime? assignedAt,
    String? targetStatus,
  }) {
    return ActiveGoalItem(
      goalId: goalId ?? this.goalId,
      domainId: domainId ?? this.domainId,
      domainName: domainName ?? this.domainName,
      goalTitle: goalTitle ?? this.goalTitle,
      assignedAt: assignedAt ?? this.assignedAt,
      targetStatus: targetStatus ?? this.targetStatus,
    );
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }
}

/// Represents an individual interaction module log within a daily therapy session.
class SessionLogItem {
  final String goalId;
  final String moduleName;
  final String interactionType; // 'touch_game' | 'voice' | 'camera' | 'breathe'
  final bool completed;
  final int durationSeconds;
  final int errantTaps;
  final String detectedMood;
  final DateTime timestamp;

  const SessionLogItem({
    required this.goalId,
    required this.moduleName,
    required this.interactionType,
    required this.completed,
    required this.durationSeconds,
    this.errantTaps = 0,
    required this.detectedMood,
    required this.timestamp,
  });

  factory SessionLogItem.fromMap(Map<String, dynamic> map) {
    return SessionLogItem(
      goalId: (map['goal_id'] ?? map['goalId'] ?? '') as String,
      moduleName: (map['module_name'] ?? map['moduleName'] ?? '') as String,
      interactionType: (map['interaction_type'] ?? map['interactionType'] ?? 'touch_game') as String,
      completed: (map['completed'] ?? false) as bool,
      durationSeconds: ((map['duration_seconds'] ?? map['durationSeconds'] ?? 0) as num).toInt(),
      errantTaps: ((map['errant_taps'] ?? map['errantTaps'] ?? 0) as num).toInt(),
      detectedMood: (map['detected_mood'] ?? map['detectedMood'] ?? 'Calm') as String,
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_id': goalId,
      'module_name': moduleName,
      'interaction_type': interactionType,
      'completed': completed,
      'duration_seconds': durationSeconds,
      'errant_taps': errantTaps,
      'detected_mood': detectedMood,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }
}

/// Official clinical daily report written by a therapist and shared with parents.
class TherapistReportModel {
  final String summary;
  final String strengths;
  final String areasOfConcern;
  final String homeRecommendations;
  final DateTime submittedAt;
  final String therapistName;
  final bool sharedWithParent;

  const TherapistReportModel({
    required this.summary,
    required this.strengths,
    required this.areasOfConcern,
    required this.homeRecommendations,
    required this.submittedAt,
    required this.therapistName,
    this.sharedWithParent = true,
  });

  factory TherapistReportModel.fromMap(Map<String, dynamic> map) {
    return TherapistReportModel(
      summary: (map['summary'] ?? '') as String,
      strengths: (map['strengths'] ?? '') as String,
      areasOfConcern: (map['areas_of_concern'] ?? map['areasOfConcern'] ?? '') as String,
      homeRecommendations: (map['home_recommendations'] ?? map['homeRecommendations'] ?? '') as String,
      submittedAt: _parseDateTime(map['submitted_at'] ?? map['submittedAt']) ?? DateTime.now(),
      therapistName: (map['therapist_name'] ?? map['therapistName'] ?? 'Lead Clinical Therapist') as String,
      sharedWithParent: (map['shared_with_parent'] ?? map['sharedWithParent'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'summary': summary,
      'strengths': strengths,
      'areas_of_concern': areasOfConcern,
      'home_recommendations': homeRecommendations,
      'submitted_at': Timestamp.fromDate(submittedAt),
      'therapist_name': therapistName,
      'shared_with_parent': sharedWithParent,
    };
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }
}

/// Aggregated telemetry and logs for a child's daily session.
class DailySessionModel {
  final String date; // YYYY-MM-DD
  final int totalActiveSeconds;
  final String overallMoodDetected; // 'Happy' | 'Calm' | 'Frustrated' | 'Distracted'
  final double completionRate; // e.g. 0.85
  final int struggleIncidents;
  final List<SessionLogItem> sessionLogs;
  final TherapistReportModel? therapistReport;

  const DailySessionModel({
    required this.date,
    required this.totalActiveSeconds,
    required this.overallMoodDetected,
    required this.completionRate,
    required this.struggleIncidents,
    required this.sessionLogs,
    this.therapistReport,
  });

  factory DailySessionModel.fromMap(String date, Map<String, dynamic> map) {
    final rawLogs = map['session_logs'] as List<dynamic>? ?? [];
    final logs = rawLogs
        .map((item) => SessionLogItem.fromMap(item as Map<String, dynamic>))
        .toList();

    TherapistReportModel? report;
    if (map['therapist_report'] != null && map['therapist_report'] is Map) {
      report = TherapistReportModel.fromMap(map['therapist_report'] as Map<String, dynamic>);
    }

    return DailySessionModel(
      date: date,
      totalActiveSeconds: ((map['total_active_seconds'] ?? map['totalActiveSeconds'] ?? 0) as num).toInt(),
      overallMoodDetected: (map['overall_mood_detected'] ?? map['overallMoodDetected'] ?? 'Calm') as String,
      completionRate: ((map['completion_rate'] ?? map['completionRate'] ?? 0.0) as num).toDouble(),
      struggleIncidents: ((map['struggle_incidents'] ?? map['struggleIncidents'] ?? 0) as num).toInt(),
      sessionLogs: logs,
      therapistReport: report,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'total_active_seconds': totalActiveSeconds,
      'overall_mood_detected': overallMoodDetected,
      'completion_rate': completionRate,
      'struggle_incidents': struggleIncidents,
      'session_logs': sessionLogs.map((log) => log.toMap()).toList(),
      'therapist_report': therapistReport?.toMap(),
    };
  }

  DailySessionModel copyWith({
    String? date,
    int? totalActiveSeconds,
    String? overallMoodDetected,
    double? completionRate,
    int? struggleIncidents,
    List<SessionLogItem>? sessionLogs,
    TherapistReportModel? therapistReport,
  }) {
    return DailySessionModel(
      date: date ?? this.date,
      totalActiveSeconds: totalActiveSeconds ?? this.totalActiveSeconds,
      overallMoodDetected: overallMoodDetected ?? this.overallMoodDetected,
      completionRate: completionRate ?? this.completionRate,
      struggleIncidents: struggleIncidents ?? this.struggleIncidents,
      sessionLogs: sessionLogs ?? this.sessionLogs,
      therapistReport: therapistReport ?? this.therapistReport,
    );
  }
}
