import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String moduleName;
  final String interactionType; // 'camera', 'voice', 'breathe'
  final DateTime completedAt;
  final int durationSeconds;
  final int struggleCount;

  const ActivityLog({
    required this.id,
    required this.moduleName,
    required this.interactionType,
    required this.completedAt,
    this.durationSeconds = 0,
    this.struggleCount = 0,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ActivityLog.fromMap(doc.id, data);
  }

  factory ActivityLog.fromMap(String id, Map<String, dynamic> data) {
    return ActivityLog(
      id: id,
      moduleName: (data['module_name'] ?? data['moduleName'] ?? '') as String,
      interactionType: (data['interaction_type'] ?? data['interactionType'] ?? '') as String,
      completedAt: (data['completed_at'] as Timestamp?)?.toDate() ??
          (data['completedAt'] as Timestamp?)?.toDate() ??
          _parseDate(data['completed_at'] ?? data['completedAt']) ??
          DateTime.now(),
      durationSeconds: ((data['duration_seconds'] ?? data['durationSeconds'] ?? 0) as num).toInt(),
      struggleCount: ((data['struggle_count'] ?? data['struggleCount'] ?? 0) as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'module_name': moduleName,
      'interaction_type': interactionType,
      'completed_at': Timestamp.fromDate(completedAt),
      'duration_seconds': durationSeconds,
      'struggle_count': struggleCount,
    };
  }

  ActivityLog copyWith({
    String? id,
    String? moduleName,
    String? interactionType,
    DateTime? completedAt,
    int? durationSeconds,
    int? struggleCount,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      moduleName: moduleName ?? this.moduleName,
      interactionType: interactionType ?? this.interactionType,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      struggleCount: struggleCount ?? this.struggleCount,
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }
}
