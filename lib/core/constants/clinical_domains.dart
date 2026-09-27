import 'package:flutter/material.dart';

/// Clinical domain definition representing one of the 22 pediatric & autism behavioral areas.
class ClinicalDomain {
  final int id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final Color themeColor;
  final List<ClinicalSubGoal> subGoals;

  const ClinicalDomain({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.subGoals,
  });
}

/// Clinical target sub-goal that therapists can assign to an individual child.
class ClinicalSubGoal {
  final String goalId;
  final int domainId;
  final String title;
  final String description;
  final String moduleName;
  final String interactionType; // 'touch_game' | 'voice' | 'camera' | 'breathe'
  final int defaultDurationSeconds;

  const ClinicalSubGoal({
    required this.goalId,
    required this.domainId,
    required this.title,
    required this.description,
    required this.moduleName,
    required this.interactionType,
    this.defaultDurationSeconds = 180,
  });

  Map<String, dynamic> toMap({String targetStatus = 'active'}) {
    return {
      'goal_id': goalId,
      'domain_id': domainId,
      'goal_title': title,
      'module_name': moduleName,
      'interaction_type': interactionType,
      'target_status': targetStatus,
    };
  }
}

/// The official 22 Standard Pediatric & Autism Behavioral Domains Taxonomy
class ClinicalTaxonomy {
  static const List<ClinicalDomain> domains = [
    // 1. Receptive Language
    ClinicalDomain(
      id: 1,
      name: 'Receptive Language',
      category: 'Communication',
      description: 'Understanding spoken instructions, identifying named items, and following multi-step commands.',
      icon: Icons.record_voice_over_rounded,
      themeColor: Color(0xFF3B82F6),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_01_01',
          domainId: 1,
          title: 'Identifying Objects by Name',
          description: 'Child points to or selects objects when named aloud.',
          moduleName: 'Object Identifier',
          interactionType: 'voice',
        ),
        ClinicalSubGoal(
          goalId: 'g_01_02',
          domainId: 1,
          title: 'Following 1-Step Verbal Commands',
          description: 'Child responds to clear single-step auditory commands ("Sit down", "Look here").',
          moduleName: 'Voice Command Follower',
          interactionType: 'voice',
        ),
        ClinicalSubGoal(
          goalId: 'g_01_03',
          domainId: 1,
          title: 'Following Multi-Step Instructions',
          description: 'Child executes 2-3 chained tasks in sequence from verbal cues.',
          moduleName: 'Sequence Listener',
          interactionType: 'voice',
        ),
      ],
    ),

    // 2. Expressive Language
    ClinicalDomain(
      id: 2,
      name: 'Expressive Language',
      category: 'Communication',
      description: 'Requesting items (Mands), labeling objects (Tacts), and answering simple questions.',
      icon: Icons.forum_rounded,
      themeColor: Color(0xFF2563EB),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_02_01',
          domainId: 2,
          title: 'Requesting Items (Mands)',
          description: 'Child vocalizes or selects symbols to request desired toy or water.',
          moduleName: 'Expressive Request Studio',
          interactionType: 'voice',
        ),
        ClinicalSubGoal(
          goalId: 'g_02_02',
          domainId: 2,
          title: 'Labeling Surroundings (Tacts)',
          description: 'Child verbally names items shown on screen or in environment.',
          moduleName: 'Vocabulary Builder',
          interactionType: 'voice',
        ),
        ClinicalSubGoal(
          goalId: 'g_02_03',
          domainId: 2,
          title: 'Answering Simple Inquiries',
          description: 'Child answers "Yes/No" or basic "What/Where" questions.',
          moduleName: 'Question & Answer Mirror',
          interactionType: 'voice',
        ),
      ],
    ),

    // 3. Social Interaction & Play
    ClinicalDomain(
      id: 3,
      name: 'Social Interaction & Play',
      category: 'Social & Emotional',
      description: 'Turn-taking, parallel play with virtual peers, and interactive cooperative engagement.',
      icon: Icons.groups_rounded,
      themeColor: Color(0xFF8B5CF6),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_03_01',
          domainId: 3,
          title: 'Structured Turn-Taking',
          description: 'Child waits patiently for their turn during sequential interactive play.',
          moduleName: 'Turn-Taking Arena',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_03_02',
          domainId: 3,
          title: 'Parallel Play Exploration',
          description: 'Child engages in shared digital canvas alongside animated companion.',
          moduleName: 'Companion Canvas',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_03_03',
          domainId: 3,
          title: 'Interactive Peer Cooperation',
          description: 'Child cooperates with interactive cues to build a shared virtual structure.',
          moduleName: 'Team Builder Quest',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 4. Joint Attention
    ClinicalDomain(
      id: 4,
      name: 'Joint Attention',
      category: 'Social & Emotional',
      description: 'Gaze following, responding to name call, and pointing to share interest.',
      icon: Icons.visibility_rounded,
      themeColor: Color(0xFF6366F1),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_04_01',
          domainId: 4,
          title: 'Gaze Following & Head Turn',
          description: 'Child turns head and gaze in direction indicated by character.',
          moduleName: 'Gaze Tracker Companion',
          interactionType: 'camera',
        ),
        ClinicalSubGoal(
          goalId: 'g_04_02',
          domainId: 4,
          title: 'Responding to Name Call',
          description: 'Child looks at camera when name audio prompt is delivered.',
          moduleName: 'Name Call Response',
          interactionType: 'camera',
        ),
        ClinicalSubGoal(
          goalId: 'g_04_03',
          domainId: 4,
          title: 'Pointing to Share Visual Interest',
          description: 'Child points at animated target on screen to share discovery.',
          moduleName: 'Shared Interest Spotlight',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 5. Imitation & Modeling
    ClinicalDomain(
      id: 5,
      name: 'Imitation & Modeling',
      category: 'Social & Emotional',
      description: 'Gross motor imitation, fine motor copying, and vocal sound imitation.',
      icon: Icons.copy_all_rounded,
      themeColor: Color(0xFFA855F7),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_05_01',
          domainId: 5,
          title: 'Gross Motor Imitation',
          description: 'Child mimics clapping, waving, and raising arms shown on screen.',
          moduleName: 'Motion Mirror',
          interactionType: 'camera',
        ),
        ClinicalSubGoal(
          goalId: 'g_05_02',
          domainId: 5,
          title: 'Fine Motor Copying',
          description: 'Child copies specific finger taps and gesture sequences.',
          moduleName: 'Finger Gesture Mimic',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_05_03',
          domainId: 5,
          title: 'Vocal Sound & Pitch Imitation',
          description: 'Child echoes phonetic sounds and simple words.',
          moduleName: 'Phonics Echo Chamber',
          interactionType: 'voice',
        ),
      ],
    ),

    // 6. Emotional Recognition & Expression
    ClinicalDomain(
      id: 6,
      name: 'Emotional Recognition & Expression',
      category: 'Social & Emotional',
      description: 'Identifying happy/sad/angry, mimicking facial expressions, and emotion labeling.',
      icon: Icons.sentiment_satisfied_alt_rounded,
      themeColor: Color(0xFFEC4899),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_06_01',
          domainId: 6,
          title: 'Identifying Primary Emotions',
          description: 'Child distinguishes happy, sad, angry, and surprised expressions.',
          moduleName: 'Emotion Detective',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_06_02',
          domainId: 6,
          title: 'Facial Expression Mimicking',
          description: 'Child performs smiles, curious, and calm expressions to front camera.',
          moduleName: 'Emotion Mirror Studio',
          interactionType: 'camera',
        ),
        ClinicalSubGoal(
          goalId: 'g_06_03',
          domainId: 6,
          title: 'Self-Emotion Labeling',
          description: 'Child selects current internal emotional state on check-in wheel.',
          moduleName: 'Daily Feelings Dial',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 7. Sensory Regulation
    ClinicalDomain(
      id: 7,
      name: 'Sensory Regulation',
      category: 'Sensory & Behavioral',
      description: 'Paced deep breathing, auditory desensitization, and tactile tolerance.',
      icon: Icons.spa_rounded,
      themeColor: Color(0xFF10B981),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_07_01',
          domainId: 7,
          title: 'Paced Deep Breathing (4-7-8)',
          description: 'Child follows visual expand/contract flower for paced inhalation and exhalation.',
          moduleName: 'Breathing Flower Game',
          interactionType: 'breathe',
        ),
        ClinicalSubGoal(
          goalId: 'g_07_02',
          domainId: 7,
          title: 'Auditory Threshold Desensitization',
          description: 'Gradual controlled exposure to everyday soundscapes with volume control.',
          moduleName: 'Sound Horizon Calmer',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_07_03',
          domainId: 7,
          title: 'Tactile Screen Gentle Touch Tolerance',
          description: 'Gentle smooth dragging without hard erratic screen pounding.',
          moduleName: 'Pop Bubbles Game',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 8. ADL: Personal Hygiene
    ClinicalDomain(
      id: 8,
      name: 'ADL: Personal Hygiene',
      category: 'Daily Living Skills',
      description: 'Hand washing step sequences, teeth brushing routine, and face hygiene.',
      icon: Icons.clean_hands_rounded,
      themeColor: Color(0xFF06B6D4),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_08_01',
          domainId: 8,
          title: 'Hand Washing 4-Stage Routine',
          description: 'Soap, scrub palms, rinse, and towel dry sequence.',
          moduleName: 'Wash Hands Game',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_08_02',
          domainId: 8,
          title: 'Tooth Brushing Circular Motions',
          description: 'Brushing front, chewing surfaces, and back quadrants for 120s.',
          moduleName: 'Brush Teeth Game',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_08_03',
          domainId: 8,
          title: 'Face Washing & Cleanliness',
          description: 'Wiping face and eyes cleanly with soft washcloth sequence.',
          moduleName: 'Fresh Face Routine',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 9. ADL: Dressing & Grooming
    ClinicalDomain(
      id: 9,
      name: 'ADL: Dressing & Grooming',
      category: 'Daily Living Skills',
      description: 'Shoe velcro/lacing, buttoning garments, and jacket zipper alignment.',
      icon: Icons.checkroom_rounded,
      themeColor: Color(0xFF0EA5E9),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_09_01',
          domainId: 9,
          title: 'Shoe Fastening & Velcro Strap',
          description: 'Child pulls velcro strap across sneaker and presses firmly.',
          moduleName: 'Shoe Strap Master',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_09_02',
          domainId: 9,
          title: 'Buttoning & Shirt Fastening',
          description: 'Aligning buttons into corresponding buttonholes from bottom to top.',
          moduleName: 'Button Sequence Trainer',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_09_03',
          domainId: 9,
          title: 'Jacket Zipper Alignment & Pull',
          description: 'Connecting zipper pin into retainer box and sliding up smoothly.',
          moduleName: 'Zip & Go Challenge',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 10. ADL: Toileting & Bathroom Habits
    ClinicalDomain(
      id: 10,
      name: 'ADL: Toileting & Bathroom Habits',
      category: 'Daily Living Skills',
      description: 'Bathroom sequence recognition, toilet flushing, and hand drying.',
      icon: Icons.wc_rounded,
      themeColor: Color(0xFF14B8A6),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_10_01',
          domainId: 10,
          title: 'Toilet Routine Sequence Recognition',
          description: 'Ordering the steps: door close, clothing down, sit, wipe, flush.',
          moduleName: 'Bathroom Schedule Steps',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_10_02',
          domainId: 10,
          title: 'Flushing & Cleanliness Awareness',
          description: 'Child presses flush trigger and ensures bowl cleanliness.',
          moduleName: 'Clean Space Habit',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 11. ADL: Feeding & Table Manners
    ClinicalDomain(
      id: 11,
      name: 'ADL: Feeding & Table Manners',
      category: 'Daily Living Skills',
      description: 'Utensil grip and usage, steady cup drinking without spills, and sitting at mealtime.',
      icon: Icons.restaurant_rounded,
      themeColor: Color(0xFFF59E0B),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_11_01',
          domainId: 11,
          title: 'Spoon & Fork Utensil Motion',
          description: 'Scooping food item and guiding steadily to plate center.',
          moduleName: 'Steady Spoon Quest',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_11_02',
          domainId: 11,
          title: 'Cup Drinking Without Spillage',
          description: 'Two-handed cup tilt simulation at controlled angle.',
          moduleName: 'Careful Sip Game',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_11_03',
          domainId: 11,
          title: 'Table Etiquette & Calm Meal Sitting',
          description: 'Staying engaged at meal table for target 5-minute interval.',
          moduleName: 'Mealtime Calm Timer',
          interactionType: 'breathe',
        ),
      ],
    ),

    // 12. Fine Motor Coordination
    ClinicalDomain(
      id: 12,
      name: 'Fine Motor Coordination',
      category: 'Motor & Physical',
      description: 'Pincer grasp training, finger tracing paths, and drag-and-drop precision.',
      icon: Icons.pinch_rounded,
      themeColor: Color(0xFFD97706),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_12_01',
          domainId: 12,
          title: 'Pincer Grasp Digital Squeeze',
          description: 'Pinching small targets with index and thumb simultaneously.',
          moduleName: 'Pincer Precision Tap',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_12_02',
          domainId: 12,
          title: 'Curved Path & Boundary Tracing',
          description: 'Following curving lines without straying outside visual gutters.',
          moduleName: 'Fine Motor Trace Game',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_12_03',
          domainId: 12,
          title: 'Drag-and-Drop Spatial Snapping',
          description: 'Dragging target into subtle snapping socket with high alignment precision.',
          moduleName: 'Shadow Match Game',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 13. Gross Motor Pacing
    ClinicalDomain(
      id: 13,
      name: 'Gross Motor Pacing',
      category: 'Motor & Physical',
      description: 'Body posture balance, rhythm tapping cadence, and paced body movements.',
      icon: Icons.directions_run_rounded,
      themeColor: Color(0xFFEF4444),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_13_01',
          domainId: 13,
          title: 'Standing Posture & Arm Balancing',
          description: 'Holding airplane arms pose in camera view for 15 seconds.',
          moduleName: 'Balance Statue Quest',
          interactionType: 'camera',
        ),
        ClinicalSubGoal(
          goalId: 'g_13_02',
          domainId: 13,
          title: 'Rhythmic Beat Tapping',
          description: 'Tapping in time with metronome beat to regulate motor impulsivity.',
          moduleName: 'Rhythm Pacing Drum',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 14. Executive Functioning: Organization
    ClinicalDomain(
      id: 14,
      name: 'Executive Functioning: Organization',
      category: 'Cognitive & Executive',
      description: 'School bag packing, room clean-up, and categorizing items into places.',
      icon: Icons.backpack_rounded,
      themeColor: Color(0xFF10B981),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_14_01',
          domainId: 14,
          title: 'School Bag Packing from Checklist',
          description: 'Selecting notebook, water bottle, pencil box into backpack slots.',
          moduleName: 'Pack Bag Game',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_14_02',
          domainId: 14,
          title: 'Toy Chest Categorized Clean-Up',
          description: 'Sorting 6 toys into blocks, vehicles, and soft toys boxes.',
          moduleName: 'Toy Chest Cleanup Game',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 15. Executive Functioning: Task Switching & Flexibility
    ClinicalDomain(
      id: 15,
      name: 'Executive Functioning: Task Switching & Flexibility',
      category: 'Cognitive & Executive',
      description: 'Smooth transitions between activities, accepting alternative choices without rigidity.',
      icon: Icons.published_with_changes_rounded,
      themeColor: Color(0xFF6366F1),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_15_01',
          domainId: 15,
          title: 'Activity Transition Countdown Follower',
          description: 'Stopping preferred activity within 10-second chime countdown.',
          moduleName: 'Transition Chime Bridge',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_15_02',
          domainId: 15,
          title: 'Accepting Alternative Reward Choices',
          description: 'Choosing from Plan B options when first choice item is unavailable.',
          moduleName: 'Flexible Choice Studio',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 16. Cognitive Sorting & Seriation
    ClinicalDomain(
      id: 16,
      name: 'Cognitive Sorting & Seriation',
      category: 'Cognitive & Executive',
      description: 'Color sorting, shape matching, and stacking rings in exact size order.',
      icon: Icons.filter_alt_rounded,
      themeColor: Color(0xFF8B5CF6),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_16_01',
          domainId: 16,
          title: 'Multi-Color Laundry Sorting',
          description: 'Sorting shirts by color into blue and green baskets.',
          moduleName: 'Laundry Sort Game',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_16_02',
          domainId: 16,
          title: 'Seriation Order Stacking (Large to Small)',
          description: 'Enforcing strict size order from largest base to smallest peak.',
          moduleName: 'Shape Tower Game',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 17. Cognitive Merging & Synthesis
    ClinicalDomain(
      id: 17,
      name: 'Cognitive Merging & Synthesis',
      category: 'Cognitive & Executive',
      description: 'Part-to-whole puzzle assembly, fruit synthesis merging, and category association.',
      icon: Icons.merge_type_rounded,
      themeColor: Color(0xFFEC4899),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_17_01',
          domainId: 17,
          title: 'Hierarchical Fruit Merge Progression',
          description: 'Merging matching berries into oranges and apples progressively.',
          moduleName: 'Fruit Merge Game',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_17_02',
          domainId: 17,
          title: 'Part-to-Whole Blueprint Assembly',
          description: 'Snapping cab, chassis, and wheels onto assembly blueprint.',
          moduleName: 'Build Vehicle Game',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 18. Visual-Spatial Awareness
    ClinicalDomain(
      id: 18,
      name: 'Visual-Spatial Awareness',
      category: 'Cognitive & Executive',
      description: 'Shadow silhouette matching, figure-ground discrimination, and boundary spatialization.',
      icon: Icons.blur_linear_rounded,
      themeColor: Color(0xFF14B8A6),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_18_01',
          domainId: 18,
          title: 'Silhouette Shadow Matching',
          description: 'Matching 3 objects to their exact darkened silhouettes.',
          moduleName: 'Shadow Match Game',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_18_02',
          domainId: 18,
          title: 'Figure-Ground Object Finder',
          description: 'Locating hidden targets inside cluttered visual backgrounds.',
          moduleName: 'Hidden Object Canvas',
          interactionType: 'touch_game',
        ),
      ],
    ),

    // 19. Frustration Tolerance & Coping
    ClinicalDomain(
      id: 19,
      name: 'Frustration Tolerance & Coping',
      category: 'Sensory & Behavioral',
      description: 'Calming down after in-game error, refraining from hard pounding, using calming tools.',
      icon: Icons.healing_rounded,
      themeColor: Color(0xFFF97316),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_19_01',
          domainId: 19,
          title: 'Gentle Retry After Mistake',
          description: 'Pausing and trying again gently when a match misses without rapid erratic taps.',
          moduleName: 'Gentle Tap Resilience',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_19_02',
          domainId: 19,
          title: 'Calm-Down Corner Activation',
          description: 'Child self-selects breathing petal or water ripple when feeling frustrated.',
          moduleName: 'Peaceful Oasis Corner',
          interactionType: 'breathe',
        ),
      ],
    ),

    // 20. Self-Advocacy & Functional Communication
    ClinicalDomain(
      id: 20,
      name: 'Self-Advocacy & Functional Communication',
      category: 'Communication',
      description: 'Gesturing help, expressing "Break please", signaling physical discomfort or overwhelm.',
      icon: Icons.front_hand_rounded,
      themeColor: Color(0xFF0284C7),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_20_01',
          domainId: 20,
          title: 'Requesting "Help Please"',
          description: 'Child taps help symbol or speaks word before escalating frustration.',
          moduleName: 'Help Button Advocate',
          interactionType: 'voice',
        ),
        ClinicalSubGoal(
          goalId: 'g_20_02',
          domainId: 20,
          title: 'Signaling Need for a Sensory Break',
          description: 'Child communicates "Need a break" via icon or audio prompt.',
          moduleName: 'Break Time Signal',
          interactionType: 'voice',
        ),
      ],
    ),

    // 21. Routine & Daily Schedule Adherence
    ClinicalDomain(
      id: 21,
      name: 'Routine & Daily Schedule Adherence',
      category: 'Daily Living Skills',
      description: 'Following visual timetable, checking off morning checklist, evening bedtime routine.',
      icon: Icons.calendar_month_rounded,
      themeColor: Color(0xFF475569),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_21_01',
          domainId: 21,
          title: 'Morning Routine Checklist Completion',
          description: 'Checking off wake, bathroom, teeth, dress, breakfast milestones.',
          moduleName: 'Morning Routine Star',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_21_02',
          domainId: 21,
          title: 'Bedtime Wind-Down Timetable',
          description: 'Following soothing evening sequence into quiet time and lights out.',
          moduleName: 'Bedtime Calm Track',
          interactionType: 'breathe',
        ),
      ],
    ),

    // 22. Safety Awareness & Boundary Recognition
    ClinicalDomain(
      id: 22,
      name: 'Safety Awareness & Boundary Recognition',
      category: 'Sensory & Behavioral',
      description: 'Recognizing danger signs, hot vs cold thermal awareness, adhering to stop commands.',
      icon: Icons.warning_amber_rounded,
      themeColor: Color(0xFFDC2626),
      subGoals: [
        ClinicalSubGoal(
          goalId: 'g_22_01',
          domainId: 22,
          title: 'Recognizing Danger Symbols & Hazards',
          description: 'Identifying poison, electrical outlet, and street boundary symbols.',
          moduleName: 'Safety Shield Hero',
          interactionType: 'touch_game',
        ),
        ClinicalSubGoal(
          goalId: 'g_22_02',
          domainId: 22,
          title: 'Immediate Stop Command Compliance',
          description: 'Halting all screen actions immediately upon hearing auditory "STOP!" alarm.',
          moduleName: 'Red Light Green Light Safety',
          interactionType: 'touch_game',
        ),
      ],
    ),
  ];

  static ClinicalDomain? getDomainById(int id) {
    for (final d in domains) {
      if (d.id == id) return d;
    }
    return null;
  }

  static List<String> get uniqueCategories {
    final Set<String> categories = {};
    for (final d in domains) {
      categories.add(d.category);
    }
    return categories.toList();
  }
}
