import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  final String uid;
  final String email;
  final DateTime createdAt;

  const ParentModel({
    required this.uid,
    required this.email,
    required this.createdAt,
  });

  factory ParentModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ParentModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      createdAt: _parseTimestamp(data['created_at']),
    );
  }

  factory ParentModel.fromMap(String uid, Map<String, dynamic> map) {
    return ParentModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      createdAt: _parseTimestamp(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'created_at': Timestamp.fromDate(createdAt),
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
