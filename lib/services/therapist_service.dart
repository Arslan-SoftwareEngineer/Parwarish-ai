import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import '../models/therapist_domain_model.dart';
import '../models/goal_record_model.dart';
import '../models/daily_report_model.dart';
import '../models/schedule_item_model.dart';
import '../models/therapist_datasheet_model.dart';
import '../theme/app_theme.dart';

class TherapistService {
  static final TherapistService instance = TherapistService._internal();
  TherapistService._internal();

  static const String _prefGoalRecordsKey = 'local_goal_records_data';
  static const String _prefDailyReportsKey = 'local_daily_reports_data';
  static const String _prefChildSchedulesKey = 'local_child_schedules_data';
  static const String _prefDatasheetEntriesKey = 'local_datasheet_entries_data';
  static const String _prefClinicalSummaryKey = 'local_clinical_summaries_data';

  // 22 Clinical Domains catalog
  List<TherapistDomainModel> get domains => TherapistDomainModel.allDomains;

  TherapistDomainModel? getDomainById(String id) {
    try {
      return domains.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  TherapistGoalModel? getGoalById(String goalId) {
    for (var domain in domains) {
      for (var goal in domain.goals) {
        if (goal.id == goalId) return goal;
      }
    }
    return null;
  }

  // --- GOAL TELEMETRY & RECORDS ---
  Future<void> logGoalRecord(GoalRecordModel record) async {
    // 1. Log to Firestore
    if (FirebaseService.instance.isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(record.childId)
            .collection('goal_records')
            .doc(record.id)
            .set(record.toMap());
      } catch (e) {
        debugPrint('Firestore logGoalRecord error: $e');
      }
    }

    // 2. Local fallback storage
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefGoalRecordsKey);
    Map<String, dynamic> map = data != null ? jsonDecode(data) : {};
    List<dynamic> list = map[record.childId] != null ? List<dynamic>.from(map[record.childId]) : [];
    list.insert(0, {
      'id': record.id,
      'child_id': record.childId,
      'domain_id': record.domainId,
      'goal_id': record.goalId,
      'module_name': record.moduleName,
      'game_type': record.gameType,
      'time_taken_seconds': record.timeTakenSeconds,
      'accuracy_score': record.accuracyScore,
      'mood_state': record.moodState,
      'completed_at': record.completedAt.toIso8601String(),
    });
    map[record.childId] = list;
    await prefs.setString(_prefGoalRecordsKey, jsonEncode(map));

    // Also mirror to activity_logs for backward compatibility
    await FirebaseService.instance.logActivity(
      childId: record.childId,
      moduleName: record.moduleName,
      interactionType: record.gameType,
    );
  }

  Future<List<GoalRecordModel>> getGoalRecordsForChild(String childId) async {
    if (FirebaseService.instance.isFirebaseReady) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('children')
            .doc(childId)
            .collection('goal_records')
            .orderBy('completed_at', descending: true)
            .get();
        if (query.docs.isNotEmpty) {
          return query.docs.map((doc) => GoalRecordModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        debugPrint('Firestore getGoalRecords error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefGoalRecordsKey);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey(childId)) {
        final list = (map[childId] as List).cast<Map<String, dynamic>>();
        return list.map((m) => GoalRecordModel.fromMap(m['id'] as String, m)).toList();
      }
    }
    return [];
  }

  // --- DAILY PROGRESS REPORTS (Therapist to Parent) ---
  Future<DailyReportModel> createAndSendDailyReport({
    required String childId,
    required String childName,
    required String therapistName,
    required List<String> strengthsObserved,
    required String therapistNotes,
    required String homeActivityTip,
    required String primaryMood,
    required int goalsCompletedCount,
    required int totalDurationMinutes,
  }) async {
    final reportId = 'rep_${DateTime.now().millisecondsSinceEpoch}';
    final report = DailyReportModel(
      id: reportId,
      childId: childId,
      childName: childName,
      reportDate: DateTime.now(),
      therapistName: therapistName,
      goalsCompletedCount: goalsCompletedCount,
      totalDurationMinutes: totalDurationMinutes,
      primaryMood: primaryMood,
      strengthsObserved: strengthsObserved,
      therapistNotes: therapistNotes,
      homeActivityTip: homeActivityTip,
      createdAt: DateTime.now(),
    );

    if (FirebaseService.instance.isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('therapist_reports')
            .doc(reportId)
            .set(report.toMap());
      } catch (e) {
        debugPrint('Firestore createDailyReport error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefDailyReportsKey);
    Map<String, dynamic> map = data != null ? jsonDecode(data) : {};
    List<dynamic> list = map[childId] != null ? List<dynamic>.from(map[childId]) : [];
    list.insert(0, {
      'id': report.id,
      'child_id': report.childId,
      'child_name': report.childName,
      'report_date': report.reportDate.toIso8601String(),
      'therapist_name': report.therapistName,
      'goals_completed_count': report.goalsCompletedCount,
      'total_duration_minutes': report.totalDurationMinutes,
      'primary_mood': report.primaryMood,
      'strengths_observed': report.strengthsObserved,
      'therapist_notes': report.therapistNotes,
      'home_activity_tip': report.homeActivityTip,
      'created_at': report.createdAt.toIso8601String(),
    });
    map[childId] = list;
    await prefs.setString(_prefDailyReportsKey, jsonEncode(map));

    return report;
  }

  Future<List<DailyReportModel>> getDailyReportsForChild(String childId) async {
    if (FirebaseService.instance.isFirebaseReady) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('therapist_reports')
            .where('child_id', isEqualTo: childId)
            .orderBy('report_date', descending: true)
            .get();
        if (query.docs.isNotEmpty) {
          return query.docs.map((doc) => DailyReportModel.fromFirestore(doc)).toList();
        }
      } catch (e) {
        debugPrint('Firestore getDailyReports error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefDailyReportsKey);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey(childId)) {
        final list = (map[childId] as List).cast<Map<String, dynamic>>();
        return list.map((m) => DailyReportModel.fromMap(m['id'] as String, m)).toList();
      }
    }

    // Default friendly welcome report from therapist if empty
    return [
      DailyReportModel(
        id: 'rep_default_01',
        childId: childId,
        childName: 'Explorer',
        reportDate: DateTime.now(),
        therapistName: 'Dr. Ayesha Khan (Clinical BCBA)',
        goalsCompletedCount: 3,
        totalDurationMinutes: 15,
        primaryMood: 'Happy',
        strengthsObserved: [
          'Excellent eye contact during mirror routines',
          'Fast and accurate handwashing step ordering',
          'Calm and joyful engagement with visual companion',
        ],
        therapistNotes:
            'A wonderful session today! The child demonstrated great confidence with tactile drag-and-drop sequencing and showed radiant smiles during the emotion mirror game.',
        homeActivityTip:
            'Practice high-fives and enthusiastic verbal cheers after handwashing before dinner.',
        createdAt: DateTime.now(),
      ),
    ];
  }

  // --- SCHEDULE PLANNING (Therapist assigns goals & games) ---
  Future<void> saveAssignedScheduleForChild(String childId, List<ScheduleItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefChildSchedulesKey);
    Map<String, dynamic> map = data != null ? jsonDecode(data) : {};
    map[childId] = items.map((item) => {
      'id': item.id,
      'title_en': item.titleEn,
      'title_ur': item.titleUr,
      'time': item.time,
      'is_completed': item.isCompleted,
    }).toList();
    await prefs.setString(_prefChildSchedulesKey, jsonEncode(map));
  }

  Future<List<ScheduleItemModel>?> getAssignedScheduleForChild(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefChildSchedulesKey);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey(childId)) {
        final list = (map[childId] as List).cast<Map<String, dynamic>>();
        return list.map((m) => ScheduleItemModel(
          id: m['id'] as String,
          titleEn: m['title_en'] as String,
          titleUr: m['title_ur'] as String,
          time: m['time'] as String,
          icon: _getScheduleIcon(m['title_en'] as String),
          gradient: _getScheduleGradient(m['title_en'] as String),
          isCompleted: m['is_completed'] as bool? ?? false,
        )).toList();
      }
    }
    return null;
  }

  static IconData _getScheduleIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('brush') || lower.contains('teeth') || lower.contains('wash')) return Icons.water_drop_rounded;
    if (lower.contains('potty') || lower.contains('toilet')) return Icons.wc_rounded;
    if (lower.contains('dress') || lower.contains('clothes')) return Icons.checkroom_rounded;
    if (lower.contains('breathe') || lower.contains('calm')) return Icons.air_rounded;
    if (lower.contains('bag') || lower.contains('school')) return Icons.backpack_rounded;
    if (lower.contains('smile') || lower.contains('emotion')) return Icons.sentiment_very_satisfied_rounded;
    return Icons.star_rounded;
  }

  static LinearGradient _getScheduleGradient(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('smile') || lower.contains('morning')) return AppTheme.sunshineGradient;
    if (lower.contains('wash') || lower.contains('brush')) return AppTheme.blueCyanGradient;
    if (lower.contains('breathe') || lower.contains('calm')) return AppTheme.greenMintGradient;
    if (lower.contains('dress') || lower.contains('potty')) return AppTheme.orangePinkGradient;
    return AppTheme.purpleBlueGradient;
  }

  // --- CLINICAL DATASHEET & SESSION RECORDS ---

  Future<void> saveDatasheetEntry(DatasheetSessionEntry entry) async {
    // 1. Firestore sync
    if (FirebaseService.instance.isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(entry.childId)
            .collection('datasheet_entries')
            .doc(entry.id)
            .set(entry.toMap());
      } catch (e) {
        debugPrint('Firestore saveDatasheetEntry error: $e');
      }
    }

    // 2. Local persistence
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefDatasheetEntriesKey);
    Map<String, dynamic> map = data != null ? jsonDecode(data) : {};
    List<dynamic> list = map[entry.childId] != null ? List<dynamic>.from(map[entry.childId]) : [];

    final existingIdx = list.indexWhere((item) => item['id'] == entry.id);
    final entryMap = {
      'id': entry.id,
      'child_id': entry.childId,
      'child_name': entry.childName,
      'date': entry.date.toIso8601String(),
      'session_type': entry.sessionType,
      'domain_id': entry.domainId,
      'domain_title': entry.domainTitle,
      'goal_id': entry.goalId,
      'goal_title': entry.goalTitle,
      'prompt_level': entry.promptLevel,
      'trials_attempted': entry.trialsAttempted,
      'trials_successful': entry.trialsSuccessful,
      'mastery_percentage': entry.masteryPercentage,
      'sensory_state': entry.sensoryState,
      'behavioral_notes': entry.behavioralNotes,
      'clinical_notes': entry.clinicalNotes,
      'home_recommendations': entry.homeRecommendations,
      'next_session_targets': entry.nextSessionTargets,
      'created_at': entry.createdAt.toIso8601String(),
    };

    if (existingIdx != -1) {
      list[existingIdx] = entryMap;
    } else {
      list.insert(0, entryMap);
    }
    map[entry.childId] = list;
    await prefs.setString(_prefDatasheetEntriesKey, jsonEncode(map));
  }

  Future<void> deleteDatasheetEntry(String childId, String entryId) async {
    if (FirebaseService.instance.isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(childId)
            .collection('datasheet_entries')
            .doc(entryId)
            .delete();
      } catch (e) {
        debugPrint('Firestore deleteDatasheetEntry error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefDatasheetEntriesKey);
    if (data != null) {
      Map<String, dynamic> map = jsonDecode(data);
      if (map.containsKey(childId)) {
        List<dynamic> list = List<dynamic>.from(map[childId]);
        list.removeWhere((item) => item['id'] == entryId);
        map[childId] = list;
        await prefs.setString(_prefDatasheetEntriesKey, jsonEncode(map));
      }
    }
  }

  Future<List<DatasheetSessionEntry>> getDatasheetEntriesForChild(String childId, {String childName = 'Child'}) async {
    if (FirebaseService.instance.isFirebaseReady) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('children')
            .doc(childId)
            .collection('datasheet_entries')
            .orderBy('date', descending: true)
            .get();
        if (query.docs.isNotEmpty) {
          return query.docs.map((doc) => DatasheetSessionEntry.fromFirestore(doc)).toList();
        }
      } catch (e) {
        debugPrint('Firestore getDatasheetEntries error: $e');
      }
    }

    // Local fallback
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefDatasheetEntriesKey);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey(childId)) {
        final list = (map[childId] as List).cast<Map<String, dynamic>>();
        if (list.isNotEmpty) {
          return list.map((m) => DatasheetSessionEntry.fromMap(m['id'] as String, m)).toList();
        }
      }
    }

    // Return realistic initial seed datasheet records if none exist
    final seedEntries = _getSeedDatasheetEntriesFor(childId, childName);
    for (var entry in seedEntries) {
      await saveDatasheetEntry(entry);
    }
    return seedEntries;
  }

  List<DatasheetSessionEntry> _getSeedDatasheetEntriesFor(String childId, String childName) {
    final now = DateTime.now();
    return [
      DatasheetSessionEntry(
        id: 'ds_${childId}_01',
        childId: childId,
        childName: childName,
        date: now.subtract(const Duration(hours: 3)),
        sessionType: 'ABA Therapy',
        domainId: 'domain_09_hygiene',
        domainTitle: 'Self-Care: Hygiene & Handwashing',
        goalId: 'goal_09_01',
        goalTitle: '4-Step Handwashing Sequence',
        promptLevel: 'Gestural',
        trialsAttempted: 10,
        trialsSuccessful: 9,
        masteryPercentage: 90.0,
        sensoryState: 'Regulated',
        behavioralNotes: 'Calm throughout trials. High responsiveness to visual step card cues.',
        clinicalNotes: 'Child initiated soap rubbing independently on 7/10 trials. Prompted gesturally for faucet turn-off.',
        homeRecommendations: 'Practice placing visual sequencing strips above the bathroom sink at home.',
        nextSessionTargets: 'Fade gestural prompt on towel drying to full independence.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      DatasheetSessionEntry(
        id: 'ds_${childId}_02',
        childId: childId,
        childName: childName,
        date: now.subtract(const Duration(days: 1, hours: 2)),
        sessionType: 'Occupational Therapy',
        domainId: 'domain_04_emotion_rec',
        domainTitle: 'Emotion Recognition & Mirroring',
        goalId: 'goal_04_01',
        goalTitle: 'Joyful Emotion Mirror & Smile',
        promptLevel: 'Verbal',
        trialsAttempted: 8,
        trialsSuccessful: 6,
        masteryPercentage: 75.0,
        sensoryState: 'Sensory Seeking',
        behavioralNotes: 'Slightly hyperactive at start; grounded well with 2 minutes of sensory bubble breathing.',
        clinicalNotes: 'Accurately recognized Happy and Calm expressions on the Joy-O-Meter. Needed verbal prompt for Surprised face.',
        homeRecommendations: 'Play mirror mimicry games during morning dressing routine.',
        nextSessionTargets: 'Introduce Sad and Tired emotion discrimination.',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      DatasheetSessionEntry(
        id: 'ds_${childId}_03',
        childId: childId,
        childName: childName,
        date: now.subtract(const Duration(days: 2, hours: 4)),
        sessionType: 'Speech & Language',
        domainId: 'domain_02_expressive_lang',
        domainTitle: 'Expressive Language & Vocalization',
        goalId: 'goal_02_01',
        goalTitle: 'Morning Phonics & Articulation',
        promptLevel: 'Modeling',
        trialsAttempted: 12,
        trialsSuccessful: 8,
        masteryPercentage: 66.7,
        sensoryState: 'Regulated',
        behavioralNotes: 'High task engagement. Smiled and clapped when companion mascot spoke.',
        clinicalNotes: 'Vocalized 2-syllable functional request "Pani do" with modeling cue. Articulation confidence +20%.',
        homeRecommendations: 'Use expectant pause (3-5 seconds) before handing requested objects at mealtime.',
        nextSessionTargets: 'Generalize verbal manding across snack routines.',
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
    ];
  }

  // --- CHILD CLINICAL CASE SUMMARY ---

  Future<ChildClinicalSummary> getChildClinicalSummary(String childId, {String childName = 'Child'}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefClinicalSummaryKey);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey(childId)) {
        return ChildClinicalSummary.fromMap(map[childId] as Map<String, dynamic>);
      }
    }

    final defaultSummary = ChildClinicalSummary.defaultFor(childId, childName);
    await saveChildClinicalSummary(defaultSummary);
    return defaultSummary;
  }

  Future<void> saveChildClinicalSummary(ChildClinicalSummary summary) async {
    if (FirebaseService.instance.isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(summary.childId)
            .collection('clinical_summary')
            .doc('active')
            .set(summary.toMap());
      } catch (e) {
        debugPrint('Firestore saveChildClinicalSummary error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefClinicalSummaryKey);
    Map<String, dynamic> map = data != null ? jsonDecode(data) : {};
    map[summary.childId] = summary.toMap();
    await prefs.setString(_prefClinicalSummaryKey, jsonEncode(map));
  }

  // --- EXPORT DATASHEET TO CSV & CASE SUMMARY REPORT ---

  String exportDatasheetAsCsv(List<DatasheetSessionEntry> entries, {required String childName}) {
    final buffer = StringBuffer();
    // CSV Header row
    buffer.writeln('"Date","Child","Session Type","Domain","Clinical Goal","Prompt Level","Trials Attempted","Trials Successful","Mastery Rate (%)","Sensory State","Behavioral Notes","Clinical Notes","Home Recommendations","Next Targets"');

    for (final e in entries) {
      final dateStr = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        '"$dateStr",'
        '"${_escapeCsv(e.childName)}",'
        '"${_escapeCsv(e.sessionType)}",'
        '"${_escapeCsv(e.domainTitle)}",'
        '"${_escapeCsv(e.goalTitle)}",'
        '"${_escapeCsv(e.promptLevel)}",'
        '${e.trialsAttempted},'
        '${e.trialsSuccessful},'
        '${e.masteryPercentage},'
        '"${_escapeCsv(e.sensoryState)}",'
        '"${_escapeCsv(e.behavioralNotes)}",'
        '"${_escapeCsv(e.clinicalNotes)}",'
        '"${_escapeCsv(e.homeRecommendations)}",'
        '"${_escapeCsv(e.nextSessionTargets)}"',
      );
    }

    return buffer.toString();
  }

  String generateClinicalSummaryReport({
    required ChildClinicalSummary summary,
    required List<DatasheetSessionEntry> entries,
    required String childName,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=====================================================');
    buffer.writeln('PARWARISH.AI — CLINICAL CASE & DATASHEET SUMMARY');
    buffer.writeln('=====================================================');
    buffer.writeln('Child Name: $childName');
    buffer.writeln('Case ID: ${summary.caseId}');
    buffer.writeln('Primary Therapist: ${summary.primaryTherapist}');
    buffer.writeln('Diagnosis / Focus: ${summary.diagnosisSummary}');
    buffer.writeln('Last Updated: ${summary.lastUpdated.toLocal().toString().split('.')[0]}');
    buffer.writeln('-----------------------------------------------------');
    buffer.writeln('SENSORY PROFILE & TRIGGERS:');
    for (final t in summary.sensoryTriggers) {
      buffer.writeln(' • $t');
    }
    buffer.writeln('\nPRIMARY REINFORCERS:');
    for (final r in summary.primaryReinforcers) {
      buffer.writeln(' • $r');
    }
    buffer.writeln('\nBEHAVIOR INTERVENTION PLAN:');
    buffer.writeln(summary.targetBehaviorPlan);
    buffer.writeln('-----------------------------------------------------');
    buffer.writeln('RECENT SESSION DATASHEET ENTRIES (${entries.length} Sessions):');
    for (final e in entries) {
      final dateStr = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      buffer.writeln('[$dateStr] ${e.sessionType} | Domain: ${e.domainTitle}');
      buffer.writeln('  Goal: ${e.goalTitle}');
      buffer.writeln('  Prompt: ${e.promptLevel} | Trials: ${e.trialsSuccessful}/${e.trialsAttempted} (${e.masteryPercentage}%) | Sensory: ${e.sensoryState}');
      if (e.clinicalNotes.isNotEmpty) buffer.writeln('  Notes: ${e.clinicalNotes}');
      if (e.homeRecommendations.isNotEmpty) buffer.writeln('  Home Rec: ${e.homeRecommendations}');
      buffer.writeln('');
    }
    buffer.writeln('=====================================================');
    return buffer.toString();
  }

  static String _escapeCsv(String val) {
    return val.replaceAll('"', '""').replaceAll('\n', ' ');
  }
}

