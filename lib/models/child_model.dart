import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String parentUid;
  final String name;
  final String autismLevel; // 'Mild', 'Moderate', 'Severe'
  final int currentStreak;
  final DateTime lastLogin;

  const ChildModel({
    required this.id,
    required this.parentUid,
    required this.name,
    required this.autismLevel,
    required this.currentStreak,
    required this.lastLogin,
  });

  factory ChildModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ChildModel.fromMap(doc.id, data);
  }

  factory ChildModel.fromMap(String id, Map<String, dynamic> map) {
    return ChildModel(
      id: id,
      parentUid: map['parent_uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      autismLevel: _normalizeAutismLevel(map['autism_level'] as String?),
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      lastLogin: _parseTimestamp(map['last_login']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parent_uid': parentUid,
      'name': name,
      'autism_level': autismLevel,
      'current_streak': currentStreak,
      'last_login': Timestamp.fromDate(lastLogin),
    };
  }

  ChildModel copyWith({
    String? id,
    String? parentUid,
    String? name,
    String? autismLevel,
    int? currentStreak,
    DateTime? lastLogin,
  }) {
    return ChildModel(
      id: id ?? this.id,
      parentUid: parentUid ?? this.parentUid,
      name: name ?? this.name,
      autismLevel: autismLevel ?? this.autismLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  static String _normalizeAutismLevel(String? val) {
    if (val == null) return 'Mild';
    final lower = val.trim().toLowerCase();
    if (lower == 'severe') return 'Severe';
    if (lower == 'moderate') return 'Moderate';
    return 'Mild';
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
