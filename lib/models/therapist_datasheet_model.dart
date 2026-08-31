import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single clinical session datasheet entry for a child
class DatasheetSessionEntry {
  final String id;
  final String childId;
  final String childName;
  final DateTime date;
  final String sessionType; // 'ABA Therapy', 'Speech & Language', 'Occupational Therapy', 'Social Skills', 'Baseline Assessment'
  final String domainId;
  final String domainTitle;
  final String goalId;
  final String goalTitle;
  final String promptLevel; // 'Independent', 'Gestural', 'Verbal', 'Modeling', 'Partial Physical', 'Full Physical'
  final int trialsAttempted;
  final int trialsSuccessful;
  final double masteryPercentage;
  final String sensoryState; // 'Regulated', 'Hypersensitive', 'Hyposensitive', 'Sensory Seeking', 'Fatigued'
  final String behavioralNotes;
  final String clinicalNotes;
  final String homeRecommendations;
  final String nextSessionTargets;
  final DateTime createdAt;

  const DatasheetSessionEntry({
    required this.id,
    required this.childId,
    required this.childName,
    required this.date,
    required this.sessionType,
    required this.domainId,
    required this.domainTitle,
    required this.goalId,
    required this.goalTitle,
    required this.promptLevel,
    required this.trialsAttempted,
    required this.trialsSuccessful,
    required this.masteryPercentage,
    required this.sensoryState,
    required this.behavioralNotes,
    required this.clinicalNotes,
    required this.homeRecommendations,
    required this.nextSessionTargets,
    required this.createdAt,
  });

  factory DatasheetSessionEntry.create({
    required String id,
    required String childId,
    required String childName,
    required DateTime date,
    required String sessionType,
    required String domainId,
    required String domainTitle,
    required String goalId,
    required String goalTitle,
    required String promptLevel,
    required int trialsAttempted,
    required int trialsSuccessful,
    required String sensoryState,
    required String behavioralNotes,
    required String clinicalNotes,
    required String homeRecommendations,
    required String nextSessionTargets,
  }) {
    final double mastery = trialsAttempted > 0
        ? (trialsSuccessful / trialsAttempted) * 100
        : 0.0;

    return DatasheetSessionEntry(
      id: id,
      childId: childId,
      childName: childName,
      date: date,
      sessionType: sessionType,
      domainId: domainId,
      domainTitle: domainTitle,
      goalId: goalId,
      goalTitle: goalTitle,
      promptLevel: promptLevel,
      trialsAttempted: trialsAttempted,
      trialsSuccessful: trialsSuccessful,
      masteryPercentage: double.parse(mastery.toStringAsFixed(1)),
      sensoryState: sensoryState,
      behavioralNotes: behavioralNotes,
      clinicalNotes: clinicalNotes,
      homeRecommendations: homeRecommendations,
      nextSessionTargets: nextSessionTargets,
      createdAt: DateTime.now(),
    );
  }

  factory DatasheetSessionEntry.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DatasheetSessionEntry.fromMap(doc.id, data);
  }

  factory DatasheetSessionEntry.fromMap(String id, Map<String, dynamic> map) {
    return DatasheetSessionEntry(
      id: id,
      childId: map['child_id'] as String? ?? '',
      childName: map['child_name'] as String? ?? 'Child',
      date: _parseTimestamp(map['date']),
      sessionType: map['session_type'] as String? ?? 'ABA Therapy',
      domainId: map['domain_id'] as String? ?? '',
      domainTitle: map['domain_title'] as String? ?? '',
      goalId: map['goal_id'] as String? ?? '',
      goalTitle: map['goal_title'] as String? ?? '',
      promptLevel: map['prompt_level'] as String? ?? 'Gestural',
      trialsAttempted: (map['trials_attempted'] as num?)?.toInt() ?? 0,
      trialsSuccessful: (map['trials_successful'] as num?)?.toInt() ?? 0,
      masteryPercentage: (map['mastery_percentage'] as num?)?.toDouble() ?? 0.0,
      sensoryState: map['sensory_state'] as String? ?? 'Regulated',
      behavioralNotes: map['behavioral_notes'] as String? ?? '',
      clinicalNotes: map['clinical_notes'] as String? ?? '',
      homeRecommendations: map['home_recommendations'] as String? ?? '',
      nextSessionTargets: map['next_session_targets'] as String? ?? '',
      createdAt: _parseTimestamp(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'child_name': childName,
      'date': Timestamp.fromDate(date),
      'session_type': sessionType,
      'domain_id': domainId,
      'domain_title': domainTitle,
      'goal_id': goalId,
      'goal_title': goalTitle,
      'prompt_level': promptLevel,
      'trials_attempted': trialsAttempted,
      'trials_successful': trialsSuccessful,
      'mastery_percentage': masteryPercentage,
      'sensory_state': sensoryState,
      'behavioral_notes': behavioralNotes,
      'clinical_notes': clinicalNotes,
      'home_recommendations': homeRecommendations,
      'next_session_targets': nextSessionTargets,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  DatasheetSessionEntry copyWith({
    String? id,
    String? childId,
    String? childName,
    DateTime? date,
    String? sessionType,
    String? domainId,
    String? domainTitle,
    String? goalId,
    String? goalTitle,
    String? promptLevel,
    int? trialsAttempted,
    int? trialsSuccessful,
    double? masteryPercentage,
    String? sensoryState,
    String? behavioralNotes,
    String? clinicalNotes,
    String? homeRecommendations,
    String? nextSessionTargets,
    DateTime? createdAt,
  }) {
    return DatasheetSessionEntry(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      date: date ?? this.date,
      sessionType: sessionType ?? this.sessionType,
      domainId: domainId ?? this.domainId,
      domainTitle: domainTitle ?? this.domainTitle,
      goalId: goalId ?? this.goalId,
      goalTitle: goalTitle ?? this.goalTitle,
      promptLevel: promptLevel ?? this.promptLevel,
      trialsAttempted: trialsAttempted ?? this.trialsAttempted,
      trialsSuccessful: trialsSuccessful ?? this.trialsSuccessful,
      masteryPercentage: masteryPercentage ?? this.masteryPercentage,
      sensoryState: sensoryState ?? this.sensoryState,
      behavioralNotes: behavioralNotes ?? this.behavioralNotes,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      homeRecommendations: homeRecommendations ?? this.homeRecommendations,
      nextSessionTargets: nextSessionTargets ?? this.nextSessionTargets,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }
}

/// Clinical Mastery Status for an IEP Target
enum GoalMasteryStatus {
  notStarted,
  emerging,
  inProgress,
  mastered,
  maintained,
}

/// Represents individual skill mastery tracking for a child
class ChildMasteryGoal {
  final String goalId;
  final String domainId;
  final String domainTitle;
  final String goalTitle;
  final GoalMasteryStatus status;
  final double currentScore;
  final String targetCriteria;
  final DateTime lastEvaluated;

  const ChildMasteryGoal({
    required this.goalId,
    required this.domainId,
    required this.domainTitle,
    required this.goalTitle,
    required this.status,
    required this.currentScore,
    required this.targetCriteria,
    required this.lastEvaluated,
  });

  Map<String, dynamic> toMap() {
    return {
      'goal_id': goalId,
      'domain_id': domainId,
      'domain_title': domainTitle,
      'goal_title': goalTitle,
      'status': status.name,
      'current_score': currentScore,
      'target_criteria': targetCriteria,
      'last_evaluated': lastEvaluated.toIso8601String(),
    };
  }

  factory ChildMasteryGoal.fromMap(Map<String, dynamic> map) {
    return ChildMasteryGoal(
      goalId: map['goal_id'] as String? ?? '',
      domainId: map['domain_id'] as String? ?? '',
      domainTitle: map['domain_title'] as String? ?? '',
      goalTitle: map['goal_title'] as String? ?? '',
      status: GoalMasteryStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => GoalMasteryStatus.inProgress,
      ),
      currentScore: (map['current_score'] as num?)?.toDouble() ?? 0.0,
      targetCriteria: map['target_criteria'] as String? ?? '80% across 3 consecutive sessions',
      lastEvaluated: DateTime.tryParse(map['last_evaluated'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Child Clinical Case Summary for therapist management
class ChildClinicalSummary {
  final String childId;
  final String caseId;
  final String primaryTherapist;
  final String diagnosisSummary;
  final List<String> sensoryTriggers;
  final List<String> primaryReinforcers;
  final List<String> communicationModalities;
  final String targetBehaviorPlan;
  final DateTime lastUpdated;

  const ChildClinicalSummary({
    required this.childId,
    required this.caseId,
    required this.primaryTherapist,
    required this.diagnosisSummary,
    required this.sensoryTriggers,
    required this.primaryReinforcers,
    required this.communicationModalities,
    required this.targetBehaviorPlan,
    required this.lastUpdated,
  });

  factory ChildClinicalSummary.defaultFor(String childId, String childName) {
    return ChildClinicalSummary(
      childId: childId,
      caseId: 'CAS-${childName.toUpperCase().padRight(4, 'X').substring(0, 4)}-${childId.hashCode.abs() % 1000}',
      primaryTherapist: 'Dr. Ayesha Khan (Clinical BCBA)',
      diagnosisSummary: 'Autism Spectrum Profile • Fine-Motor & Social Interaction Focus',
      sensoryTriggers: ['Sudden loud noises', 'Bright fluorescent flickering lights'],
      primaryReinforcers: ['Star tokens', 'Sensory bubble chime sounds', 'High-fives'],
      communicationModalities: ['Verbal approximations', 'Visual PECS cards', 'Interactive touch app'],
      targetBehaviorPlan: 'Provide 2-minute visual countdown timer before task transitions; praise independent step completion.',
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'case_id': caseId,
      'primary_therapist': primaryTherapist,
      'diagnosis_summary': diagnosisSummary,
      'sensory_triggers': sensoryTriggers,
      'primary_reinforcers': primaryReinforcers,
      'communication_modalities': communicationModalities,
      'target_behavior_plan': targetBehaviorPlan,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory ChildClinicalSummary.fromMap(Map<String, dynamic> map) {
    return ChildClinicalSummary(
      childId: map['child_id'] as String? ?? '',
      caseId: map['case_id'] as String? ?? '',
      primaryTherapist: map['primary_therapist'] as String? ?? 'Dr. Ayesha Khan (Clinical BCBA)',
      diagnosisSummary: map['diagnosis_summary'] as String? ?? '',
      sensoryTriggers: (map['sensory_triggers'] as List<dynamic>?)?.cast<String>() ?? [],
      primaryReinforcers: (map['primary_reinforcers'] as List<dynamic>?)?.cast<String>() ?? [],
      communicationModalities: (map['communication_modalities'] as List<dynamic>?)?.cast<String>() ?? [],
      targetBehaviorPlan: map['target_behavior_plan'] as String? ?? '',
      lastUpdated: DateTime.tryParse(map['last_updated'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
