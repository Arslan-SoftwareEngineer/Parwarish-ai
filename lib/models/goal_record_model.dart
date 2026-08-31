import 'package:cloud_firestore/cloud_firestore.dart';

class GoalRecordModel {
  final String id;
  final String childId;
  final String domainId;
  final String goalId;
  final String moduleName;
  final String gameType;
  final int timeTakenSeconds;
  final double accuracyScore; // 0.0 to 1.0
  final String moodState; // 'Happy', 'Calm', 'Focused', 'Excited', 'Frustrated', 'Tired'
  final DateTime completedAt;

  const GoalRecordModel({
    required this.id,
    required this.childId,
    required this.domainId,
    required this.goalId,
    required this.moduleName,
    required this.gameType,
    required this.timeTakenSeconds,
    required this.accuracyScore,
    required this.moodState,
    required this.completedAt,
  });

  factory GoalRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return GoalRecordModel.fromMap(doc.id, data);
  }

  factory GoalRecordModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalRecordModel(
      id: id,
      childId: map['child_id'] as String? ?? '',
      domainId: map['domain_id'] as String? ?? 'dom_01',
      goalId: map['goal_id'] as String? ?? '',
      moduleName: map['module_name'] as String? ?? 'Interactive Mission',
      gameType: map['game_type'] as String? ?? 'drag_sequence',
      timeTakenSeconds: (map['time_taken_seconds'] as num?)?.toInt() ?? 60,
      accuracyScore: (map['accuracy_score'] as num?)?.toDouble() ?? 1.0,
      moodState: map['mood_state'] as String? ?? 'Happy',
      completedAt: _parseTimestamp(map['completed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'domain_id': domainId,
      'goal_id': goalId,
      'module_name': moduleName,
      'game_type': gameType,
      'time_taken_seconds': timeTakenSeconds,
      'accuracy_score': accuracyScore,
      'mood_state': moodState,
      'completed_at': Timestamp.fromDate(completedAt),
    };
  }

  static DateTime _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }
}
