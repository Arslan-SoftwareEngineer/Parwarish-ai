import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String moduleName;
  final String interactionType; // 'voice', 'camera', 'breathe'
  final DateTime completedAt;

  const ActivityLogModel({
    required this.id,
    required this.moduleName,
    required this.interactionType,
    required this.completedAt,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ActivityLogModel.fromMap(doc.id, data);
  }

  factory ActivityLogModel.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLogModel(
      id: id,
      moduleName: map['module_name'] as String? ?? 'General Routine',
      interactionType: map['interaction_type'] as String? ?? 'voice',
      completedAt: _parseTimestamp(map['completed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'module_name': moduleName,
      'interaction_type': interactionType,
      'completed_at': Timestamp.fromDate(completedAt),
    };
  }

  static DateTime _parseTimestamp(dynamic val) {
    if (val is Timestamp) {
      return val.toDate();
    } else if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    } else if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    return DateTime.now();
  }
}
