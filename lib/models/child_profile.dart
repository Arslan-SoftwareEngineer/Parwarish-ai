import 'package:cloud_firestore/cloud_firestore.dart';
import 'daily_session_model.dart';

class ChildProfile {
  final String id;
  final String parentUid;
  final String name;
  final String autismLevel; // 'Mild', 'Moderate', 'Severe'
  final int currentStreak;
  final DateTime? lastLogin;
  final int struggleFlags;

  // Therapist Portal Extensions
  final String assignedTherapistUid;
  final DateTime? dateOfBirth;
  final String createdBy;
  final List<ActiveGoalItem> activeGoals;

  const ChildProfile({
    required this.id,
    required this.parentUid,
    required this.name,
    required this.autismLevel,
    required this.currentStreak,
    this.lastLogin,
    this.struggleFlags = 0,
    this.assignedTherapistUid = '',
    this.dateOfBirth,
    this.createdBy = '',
    this.activeGoals = const [],
  });

  factory ChildProfile.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ChildProfile.fromMap(doc.id, data);
  }

  factory ChildProfile.fromMap(String id, Map<String, dynamic> data) {
    final rawGoals = data['active_goals'] as List<dynamic>? ?? [];
    final goals = rawGoals
        .map((g) => ActiveGoalItem.fromMap(g as Map<String, dynamic>))
        .toList();

    return ChildProfile(
      id: id,
      parentUid: (data['parent_uid'] ?? data['parentUid'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      autismLevel: _normalizeAutismLevel(data['autism_level'] ?? data['autismLevel']),
      currentStreak: ((data['current_streak'] ?? data['currentStreak'] ?? 0) as num).toInt(),
      lastLogin: (data['last_login'] as Timestamp?)?.toDate() ??
          (data['lastLogin'] as Timestamp?)?.toDate() ??
          _parseDate(data['last_login'] ?? data['lastLogin']),
      struggleFlags: ((data['struggle_flags'] ?? data['struggleFlags'] ?? 0) as num).toInt(),
      assignedTherapistUid: (data['assigned_therapist_uid'] ?? data['assignedTherapistUid'] ?? '') as String,
      dateOfBirth: (data['date_of_birth'] as Timestamp?)?.toDate() ??
          (data['dateOfBirth'] as Timestamp?)?.toDate() ??
          _parseDate(data['date_of_birth'] ?? data['dateOfBirth']),
      createdBy: (data['created_by'] ?? data['createdBy'] ?? '') as String,
      activeGoals: goals,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parent_uid': parentUid,
      'name': name,
      'autism_level': autismLevel,
      'current_streak': currentStreak,
      'last_login': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'struggle_flags': struggleFlags,
      'assigned_therapist_uid': assignedTherapistUid,
      'date_of_birth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'created_by': createdBy,
      'active_goals': activeGoals.map((g) => g.toMap()).toList(),
    };
  }

  ChildProfile copyWith({
    String? id,
    String? parentUid,
    String? name,
    String? autismLevel,
    int? currentStreak,
    DateTime? lastLogin,
    int? struggleFlags,
    String? assignedTherapistUid,
    DateTime? dateOfBirth,
    String? createdBy,
    List<ActiveGoalItem>? activeGoals,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      parentUid: parentUid ?? this.parentUid,
      name: name ?? this.name,
      autismLevel: autismLevel ?? this.autismLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      lastLogin: lastLogin ?? this.lastLogin,
      struggleFlags: struggleFlags ?? this.struggleFlags,
      assignedTherapistUid: assignedTherapistUid ?? this.assignedTherapistUid,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdBy: createdBy ?? this.createdBy,
      activeGoals: activeGoals ?? this.activeGoals,
    );
  }

  static String _normalizeAutismLevel(dynamic val) {
    if (val == null) return 'Mild';
    final str = val.toString().trim().toLowerCase();
    if (str == 'severe') return 'Severe';
    if (str == 'moderate') return 'Moderate';
    return 'Mild';
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }
}
