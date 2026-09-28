import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import '../models/child_profile.dart';
import '../models/daily_session_model.dart';

/// Thrown when an unauthorized user (such as a parent) attempts a restricted clinical action.
class ClinicalAccessDeniedException implements Exception {
  final String message;
  const ClinicalAccessDeniedException([this.message = 'Access Denied: Parents do not have permission to perform clinical actions. Only verified Therapists and Clinical Administrators are authorized.']);

  @override
  String toString() => 'ClinicalAccessDeniedException: $message';
}

class ClinicalService {
  static final ClinicalService instance = ClinicalService._internal();
  ClinicalService._internal() {
    _initializeSeedData();
  }

  FirebaseFirestore? _firestore;

  // In-memory mock & fallback clinical data store
  final Map<String, ChildProfile> _mockChildren = {};
  final Map<String, Map<String, DailySessionModel>> _mockDailySessions = {}; // childId -> { date -> DailySession }

  void init() {
    try {
      if (FirebaseService.instance.isFirebaseReady) {
        _firestore = FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('ClinicalService init warning: $e');
    }
  }

  /// Strict Gatekeeping: Verify caller is therapist or admin
  void verifyClinicalAuthority(String callerRole) {
    if (callerRole != 'therapist' && callerRole != 'admin') {
      throw const ClinicalAccessDeniedException();
    }
  }

  // ==========================================
  // CHILDREN DIRECTORY & MANAGEMENT (CRUD)
  // ==========================================

  /// Fetch list of assigned children
  Future<List<ChildProfile>> fetchChildren({String? therapistUid}) async {
    try {
      if (_firestore != null) {
        Query query = _firestore!.collection('children');
        if (therapistUid != null && therapistUid.isNotEmpty) {
          query = query.where('assigned_therapist_uid', isEqualTo: therapistUid);
        }
        final snapshot = await query.get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => ChildProfile.fromFirestore(doc)).toList();
        }
      }
    } catch (e) {
      debugPrint('Firestore fetchChildren fallback: $e');
    }
    return _mockChildren.values.toList();
  }

  /// Create a new child profile (STRICT: Therapist / Admin ONLY)
  Future<ChildProfile> createChild({
    required String name,
    required DateTime dateOfBirth,
    required String parentUid,
    required String autismLevel,
    required String createdByUid,
    required String callerRole,
    String? assignedTherapistUid,
  }) async {
    verifyClinicalAuthority(callerRole);

    final childId = 'child_${DateTime.now().millisecondsSinceEpoch}';
    final newChild = ChildProfile(
      id: childId,
      name: name.trim(),
      dateOfBirth: dateOfBirth,
      parentUid: parentUid.trim().isEmpty ? 'parent_demo_01' : parentUid.trim(),
      autismLevel: autismLevel,
      currentStreak: 0,
      struggleFlags: 0,
      createdBy: createdByUid,
      assignedTherapistUid: assignedTherapistUid ?? createdByUid,
      activeGoals: [
        // Assign default baseline goal from Receptive Language & ADL
        ActiveGoalItem(
          goalId: 'g_08_01',
          domainId: 8,
          domainName: 'ADL: Personal Hygiene',
          goalTitle: 'Hand Washing 4-Stage Routine',
          assignedAt: DateTime.now(),
        ),
      ],
    );

    // Save to Firestore
    try {
      if (_firestore != null) {
        await _firestore!.collection('children').doc(childId).set(newChild.toMap());
      }
    } catch (e) {
      debugPrint('Firestore createChild error: $e');
    }

    _mockChildren[childId] = newChild;
    return newChild;
  }

  /// Update autism spectrum classification (STRICT: Therapist / Admin ONLY)
  Future<void> updateChildAutismLevel({
    required String childId,
    required String newLevel,
    required String callerRole,
  }) async {
    verifyClinicalAuthority(callerRole);

    try {
      if (_firestore != null) {
        await _firestore!.collection('children').doc(childId).update({
          'autism_level': newLevel,
        });
      }
    } catch (e) {
      debugPrint('Firestore updateChildAutismLevel error: $e');
    }

    if (_mockChildren.containsKey(childId)) {
      _mockChildren[childId] = _mockChildren[childId]!.copyWith(autismLevel: newLevel);
    }
  }

  /// Delete / Archive child profile and telemetry (STRICT: Therapist / Admin ONLY)
  Future<void> deleteChild({
    required String childId,
    required String callerRole,
  }) async {
    verifyClinicalAuthority(callerRole);

    try {
      if (_firestore != null) {
        await _firestore!.collection('children').doc(childId).delete();
      }
    } catch (e) {
      debugPrint('Firestore deleteChild error: $e');
    }

    _mockChildren.remove(childId);
    _mockDailySessions.remove(childId);
  }

  // ==========================================
  // GOAL ASSIGNMENT STUDIO
  // ==========================================

  /// Push clinical goals to child record for mobile app consumption
  Future<void> pushGoalsToChild({
    required String childId,
    required List<ActiveGoalItem> goals,
    required String callerRole,
  }) async {
    verifyClinicalAuthority(callerRole);

    try {
      if (_firestore != null) {
        await _firestore!.collection('children').doc(childId).update({
          'active_goals': goals.map((g) => g.toMap()).toList(),
        });
      }
    } catch (e) {
      debugPrint('Firestore pushGoalsToChild error: $e');
    }

    if (_mockChildren.containsKey(childId)) {
      _mockChildren[childId] = _mockChildren[childId]!.copyWith(activeGoals: goals);
    } else {
      _mockChildren[childId] = ChildProfile(
        id: childId,
        parentUid: 'parent_demo_01',
        name: 'Child',
        autismLevel: 'Moderate',
        currentStreak: 0,
        activeGoals: goals,
      );
    }
  }

  /// Fetch goals currently active for child
  Future<List<ActiveGoalItem>> fetchChildGoals(String childId) async {
    try {
      if (_firestore != null) {
        final doc = await _firestore!.collection('children').doc(childId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final raw = data['active_goals'] as List<dynamic>? ?? [];
          return raw.map((item) => ActiveGoalItem.fromMap(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Firestore fetchChildGoals fallback: $e');
    }

    return _mockChildren[childId]?.activeGoals ?? [];
  }

  // ==========================================
  // DAILY TELEMETRY & SESSION INSPECTOR
  // ==========================================

  /// Fetch or construct daily session telemetry for a specific date (YYYY-MM-DD)
  Future<DailySessionModel> fetchDailySession({
    required String childId,
    required String dateString,
  }) async {
    try {
      if (_firestore != null) {
        final doc = await _firestore!
            .collection('children')
            .doc(childId)
            .collection('daily_sessions')
            .doc(dateString)
            .get();
        if (doc.exists) {
          return DailySessionModel.fromMap(dateString, doc.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Firestore fetchDailySession fallback: $e');
    }

    // Fallback to in-memory store
    final childSessions = _mockDailySessions[childId] ?? {};
    if (childSessions.containsKey(dateString)) {
      return childSessions[dateString]!;
    }

    // Default simulated session when no logs exist yet
    final defaultSession = DailySessionModel(
      date: dateString,
      totalActiveSeconds: 1420, // ~23 mins
      overallMoodDetected: 'Happy',
      completionRate: 0.85,
      struggleIncidents: 2,
      sessionLogs: [
        SessionLogItem(
          goalId: 'g_08_01',
          moduleName: 'Wash Hands Game',
          interactionType: 'touch_game',
          completed: true,
          durationSeconds: 240,
          errantTaps: 1,
          detectedMood: 'Calm',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        SessionLogItem(
          goalId: 'g_07_01',
          moduleName: 'Breathing Flower Game',
          interactionType: 'breathe',
          completed: true,
          durationSeconds: 180,
          errantTaps: 0,
          detectedMood: 'Happy',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        SessionLogItem(
          goalId: 'g_16_01',
          moduleName: 'Laundry Sort Game',
          interactionType: 'touch_game',
          completed: true,
          durationSeconds: 320,
          errantTaps: 3,
          detectedMood: 'Distracted',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SessionLogItem(
          goalId: 'g_06_02',
          moduleName: 'Emotion Mirror Studio',
          interactionType: 'camera',
          completed: false,
          durationSeconds: 150,
          errantTaps: 0,
          detectedMood: 'Frustrated',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
      therapistReport: null,
    );

    _mockDailySessions.putIfAbsent(childId, () => {})[dateString] = defaultSession;
    return defaultSession;
  }

  // ==========================================
  // DAILY REPORT GENERATOR & PARENT MESSENGER
  // ==========================================

  /// Finalize and publish an official clinical report sent to parent mobile app
  Future<void> publishTherapistReport({
    required String childId,
    required String dateString,
    required TherapistReportModel report,
    required String callerRole,
  }) async {
    verifyClinicalAuthority(callerRole);

    try {
      if (_firestore != null) {
        await _firestore!
            .collection('children')
            .doc(childId)
            .collection('daily_sessions')
            .doc(dateString)
            .set({
          'therapist_report': report.toMap(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore publishTherapistReport error: $e');
    }

    final childSessions = _mockDailySessions.putIfAbsent(childId, () => {});
    final existingSession = childSessions[dateString] ??
        DailySessionModel(
          date: dateString,
          totalActiveSeconds: 1200,
          overallMoodDetected: 'Happy',
          completionRate: 0.8,
          struggleIncidents: 1,
          sessionLogs: [],
        );

    childSessions[dateString] = existingSession.copyWith(therapistReport: report);
  }

  // ==========================================
  // SEED DATA INITIALIZATION
  // ==========================================
  void _initializeSeedData() {
    final today = _formatDate(DateTime.now());
    final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));

    // Seed Children
    _mockChildren['child_01'] = ChildProfile(
      id: 'child_01',
      name: 'Aayan',
      parentUid: 'parent_demo_01',
      assignedTherapistUid: 'therapist_demo_01',
      dateOfBirth: DateTime(2019, 4, 12),
      autismLevel: 'Mild',
      currentStreak: 4,
      struggleFlags: 1,
      createdBy: 'therapist_demo_01',
      activeGoals: [
        ActiveGoalItem(
          goalId: 'g_07_01',
          domainId: 7,
          domainName: 'Sensory Regulation',
          goalTitle: 'Paced Deep Breathing (4-7-8)',
          assignedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ActiveGoalItem(
          goalId: 'g_08_01',
          domainId: 8,
          domainName: 'ADL: Personal Hygiene',
          goalTitle: 'Hand Washing 4-Stage Routine',
          assignedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        ActiveGoalItem(
          goalId: 'g_16_01',
          domainId: 16,
          domainName: 'Cognitive Sorting & Seriation',
          goalTitle: 'Multi-Color Laundry Sorting',
          assignedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ],
    );

    _mockChildren['child_02'] = ChildProfile(
      id: 'child_02',
      name: 'Zainab',
      parentUid: 'parent_demo_02',
      assignedTherapistUid: 'therapist_demo_01',
      dateOfBirth: DateTime(2018, 9, 20),
      autismLevel: 'Moderate',
      currentStreak: 7,
      struggleFlags: 3,
      createdBy: 'therapist_demo_01',
      activeGoals: [
        ActiveGoalItem(
          goalId: 'g_01_01',
          domainId: 1,
          domainName: 'Receptive Language',
          goalTitle: 'Identifying Objects by Name',
          assignedAt: DateTime.now().subtract(const Duration(days: 14)),
        ),
        ActiveGoalItem(
          goalId: 'g_06_02',
          domainId: 6,
          domainName: 'Emotional Recognition & Expression',
          goalTitle: 'Facial Expression Mimicking',
          assignedAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
      ],
    );

    _mockChildren['child_03'] = ChildProfile(
      id: 'child_03',
      name: 'Hamza',
      parentUid: 'parent_demo_03',
      assignedTherapistUid: 'therapist_demo_01',
      dateOfBirth: DateTime(2020, 1, 15),
      autismLevel: 'Severe',
      currentStreak: 2,
      struggleFlags: 5,
      createdBy: 'therapist_demo_01',
      activeGoals: [
        ActiveGoalItem(
          goalId: 'g_07_01',
          domainId: 7,
          domainName: 'Sensory Regulation',
          goalTitle: 'Paced Deep Breathing (4-7-8)',
          assignedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ActiveGoalItem(
          goalId: 'g_20_01',
          domainId: 20,
          domainName: 'Self-Advocacy & Functional Communication',
          goalTitle: 'Requesting "Help Please"',
          assignedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
    );

    // Seed Telemetry Sessions
    _mockDailySessions['child_01'] = {
      today: DailySessionModel(
        date: today,
        totalActiveSeconds: 1560, // 26 mins
        overallMoodDetected: 'Happy',
        completionRate: 0.90,
        struggleIncidents: 1,
        sessionLogs: [
          SessionLogItem(
            goalId: 'g_08_01',
            moduleName: 'Wash Hands Game',
            interactionType: 'touch_game',
            completed: true,
            durationSeconds: 240,
            errantTaps: 1,
            detectedMood: 'Happy',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          SessionLogItem(
            goalId: 'g_07_01',
            moduleName: 'Breathing Flower Game',
            interactionType: 'breathe',
            completed: true,
            durationSeconds: 180,
            errantTaps: 0,
            detectedMood: 'Calm',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          SessionLogItem(
            goalId: 'g_16_01',
            moduleName: 'Laundry Sort Game',
            interactionType: 'touch_game',
            completed: true,
            durationSeconds: 340,
            errantTaps: 2,
            detectedMood: 'Happy',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
        therapistReport: TherapistReportModel(
          summary: 'Aayan showed exceptional engagement during fine-motor sorting and hygiene sequences today.',
          strengths: 'Excellent response to visual expand/contract cues in Breathing Flower.',
          areasOfConcern: 'Mild impulsivity noted during laundry color transition, resolved with pacing prompt.',
          homeRecommendations: 'Reinforce 4-stage hand washing with real soap and timer before dinner.',
          submittedAt: DateTime.now().subtract(const Duration(hours: 1)),
          therapistName: 'Dr. Ayesha Khan, BCBA-D',
          sharedWithParent: true,
        ),
      ),
      yesterday: DailySessionModel(
        date: yesterday,
        totalActiveSeconds: 1320,
        overallMoodDetected: 'Calm',
        completionRate: 0.82,
        struggleIncidents: 2,
        sessionLogs: [
          SessionLogItem(
            goalId: 'g_08_01',
            moduleName: 'Wash Hands Game',
            interactionType: 'touch_game',
            completed: true,
            durationSeconds: 260,
            errantTaps: 2,
            detectedMood: 'Calm',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          ),
        ],
        therapistReport: null,
      ),
    };
  }

  static String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
