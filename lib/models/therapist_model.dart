import 'package:cloud_firestore/cloud_firestore.dart';

class TherapistModel {
  final String uid;
  final String name;
  final String email;
  final String specialization;
  final DateTime createdAt;

  const TherapistModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.specialization,
    required this.createdAt,
  });

  factory TherapistModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return TherapistModel(
      uid: doc.id,
      name: data['name'] as String? ?? 'Dr. Specialist',
      email: data['email'] as String? ?? '',
      specialization: data['specialization'] as String? ?? 'Pediatric BCBA & Occupational Therapist',
      createdAt: _parseTimestamp(data['created_at']),
    );
  }

  factory TherapistModel.fromMap(String uid, Map<String, dynamic> map) {
    return TherapistModel(
      uid: uid,
      name: map['name'] as String? ?? 'Dr. Specialist',
      email: map['email'] as String? ?? '',
      specialization: map['specialization'] as String? ?? 'Pediatric BCBA & Occupational Therapist',
      createdAt: _parseTimestamp(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'specialization': specialization,
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
