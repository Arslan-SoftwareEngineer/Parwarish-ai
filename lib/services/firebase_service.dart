import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parent_model.dart';
import '../models/child_model.dart';
import '../models/activity_log_model.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  FirebaseFirestore? _firestore;
  bool _isFirebaseReady = false;

  bool get isFirebaseReady => _isFirebaseReady;

  Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _isFirebaseReady = true;
        debugPrint('Firebase & Firestore ready');
      } else {
        _isFirebaseReady = false;
        debugPrint('Firebase not configured, running in resilient local/offline mode');
      }
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint('Firebase init fallback: $e');
    }
    await _seedInitialDemoDataIfEmpty();
  }

  // Local persistent storage keys for fallback
  static const String _prefParentsKey = 'local_parents_data';
  static const String _prefChildrenKey = 'local_children_data';
  static const String _prefLogsKey = 'local_activity_logs_data';

  // Seed sample children if storage is empty
  Future<void> _seedInitialDemoDataIfEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefChildrenKey)) {
      final initialChildren = [
        {
          'id': 'child_01',
          'parent_uid': 'parent_demo_01',
          'name': 'Aayan',
          'autism_level': 'Mild',
          'current_streak': 4,
          'last_login': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 'child_02',
          'parent_uid': 'parent_demo_01',
          'name': 'Zainab',
          'autism_level': 'Moderate',
          'current_streak': 2,
          'last_login': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 'child_03',
          'parent_uid': 'parent_demo_01',
          'name': 'Mustafa',
          'autism_level': 'Severe',
          'current_streak': 1,
          'last_login': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
      ];
      await prefs.setString(_prefChildrenKey, jsonEncode(initialChildren));

      // Seed initial activity logs
      final initialLogs = {
        'child_01': [
          {
            'id': 'log_01',
            'module_name': 'Tie Shoes Routine',
            'interaction_type': 'voice',
            'completed_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          },
          {
            'id': 'log_02',
            'module_name': 'Pack Bag Checklist',
            'interaction_type': 'camera',
            'completed_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
        ],
        'child_02': [
          {
            'id': 'log_03',
            'module_name': 'Wash Hands Steps',
            'interaction_type': 'voice',
            'completed_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
          },
        ],
        'child_03': [
          {
            'id': 'log_04',
            'module_name': 'Happy Emotion Mirror',
            'interaction_type': 'camera',
            'completed_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          },
        ],
      };
      await prefs.setString(_prefLogsKey, jsonEncode(initialLogs));
    }
  }

  // --- PARENTS ---
  Future<void> saveParent(ParentModel parent) async {
    if (_isFirebaseReady && _firestore != null) {
      try {
        await _firestore!.collection('parents').doc(parent.uid).set(parent.toMap(), SetOptions(merge: true));
        return;
      } catch (e) {
        debugPrint('Firestore saveParent error: $e');
      }
    }
    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefParentsKey);
    Map<String, dynamic> map = data != null ? jsonDecode(data) : {};
    map[parent.uid] = {
      'email': parent.email,
      'created_at': parent.createdAt.toIso8601String(),
    };
    await prefs.setString(_prefParentsKey, jsonEncode(map));
  }

  Future<ParentModel?> getParent(String uid) async {
    if (_isFirebaseReady && _firestore != null) {
      try {
        final doc = await _firestore!.collection('parents').doc(uid).get();
        if (doc.exists) {
          return ParentModel.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint('Firestore getParent error: $e');
      }
    }
    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefParentsKey);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey(uid)) {
        return ParentModel.fromMap(uid, map[uid]);
      }
    }
    return ParentModel(uid: uid, email: 'parent@parwarish.ai', createdAt: DateTime.now());
  }

  // --- CHILDREN ---
  Future<List<ChildModel>> getChildrenForParent(String parentUid) async {
    if (_isFirebaseReady && _firestore != null) {
      try {
        final query = await _firestore!
            .collection('children')
            .where('parent_uid', isEqualTo: parentUid)
            .get();
        if (query.docs.isNotEmpty) {
          return query.docs.map((doc) => ChildModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        debugPrint('Firestore getChildren error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefChildrenKey);
    if (data != null) {
      final list = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      return list.map((m) => ChildModel.fromMap(m['id'] as String, m)).toList();
    }
    return [];
  }

  Future<ChildModel> createChild({
    required String parentUid,
    required String name,
    required String autismLevel,
  }) async {
    final newId = 'child_${DateTime.now().millisecondsSinceEpoch}';
    final child = ChildModel(
      id: newId,
      parentUid: parentUid,
      name: name,
      autismLevel: autismLevel,
      currentStreak: 1,
      lastLogin: DateTime.now(),
    );

    if (_isFirebaseReady && _firestore != null) {
      try {
        await _firestore!.collection('children').doc(newId).set(child.toMap());
        return child;
      } catch (e) {
        debugPrint('Firestore createChild error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefChildrenKey);
    List<Map<String, dynamic>> list = data != null
        ? (jsonDecode(data) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];
    list.add({
      'id': child.id,
      'parent_uid': child.parentUid,
      'name': child.name,
      'autism_level': child.autismLevel,
      'current_streak': child.currentStreak,
      'last_login': child.lastLogin.toIso8601String(),
    });
    await prefs.setString(_prefChildrenKey, jsonEncode(list));
    return child;
  }

  Future<void> updateChildStreakAndLogin({
    required String childId,
    required int newStreak,
    required DateTime lastLogin,
  }) async {
    if (_isFirebaseReady && _firestore != null) {
      try {
        await _firestore!.collection('children').doc(childId).update({
          'current_streak': newStreak,
          'last_login': Timestamp.fromDate(lastLogin),
        });
        return;
      } catch (e) {
        debugPrint('Firestore updateChildStreak error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefChildrenKey);
    if (data != null) {
      List<Map<String, dynamic>> list = (jsonDecode(data) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      for (var item in list) {
        if (item['id'] == childId) {
          item['current_streak'] = newStreak;
          item['last_login'] = lastLogin.toIso8601String();
          break;
        }
      }
      await prefs.setString(_prefChildrenKey, jsonEncode(list));
    }
  }

  // --- ACTIVITY LOGS (Subcollection: children/{child_id}/activity_logs/{log_id}) ---
  Future<void> logActivity({
    required String childId,
    required String moduleName,
    required String interactionType,
  }) async {
    final newLogId = 'log_${DateTime.now().millisecondsSinceEpoch}';
    final completedAt = DateTime.now();

    final log = ActivityLogModel(
      id: newLogId,
      moduleName: moduleName,
      interactionType: interactionType,
      completedAt: completedAt,
    );

    if (_isFirebaseReady && _firestore != null) {
      try {
        await _firestore!
            .collection('children')
            .doc(childId)
            .collection('activity_logs')
            .doc(newLogId)
            .set(log.toMap());
        return;
      } catch (e) {
        debugPrint('Firestore logActivity error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefLogsKey);
    Map<String, dynamic> map = data != null ? jsonDecode(data) : {};
    List<dynamic> logs = map[childId] != null ? List<dynamic>.from(map[childId]) : [];
    logs.insert(0, {
      'id': log.id,
      'module_name': log.moduleName,
      'interaction_type': log.interactionType,
      'completed_at': log.completedAt.toIso8601String(),
    });
    map[childId] = logs;
    await prefs.setString(_prefLogsKey, jsonEncode(map));
  }

  Future<List<ActivityLogModel>> getActivityLogs(String childId) async {
    if (_isFirebaseReady && _firestore != null) {
      try {
        final query = await _firestore!
            .collection('children')
            .doc(childId)
            .collection('activity_logs')
            .orderBy('completed_at', descending: true)
            .get();
        if (query.docs.isNotEmpty) {
          return query.docs.map((doc) => ActivityLogModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        debugPrint('Firestore getActivityLogs error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefLogsKey);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey(childId)) {
        final list = (map[childId] as List).cast<Map<String, dynamic>>();
        return list.map((m) => ActivityLogModel.fromMap(m['id'] as String, m)).toList();
      }
    }
    return [];
  }
}
