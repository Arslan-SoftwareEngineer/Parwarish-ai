import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TherapistGoalModel {
  final String id;
  final String domainId;
  final String titleEn;
  final String titleUr;
  final String descriptionEn;
  final String descriptionUr;
  final String gameType; // 'emotion_mirror', 'drag_sequence', 'voice_phonics', 'sensory_breathe', 'matching_sorting', 'fine_motor_trace'
  final String recommendedLevel; // 'All', 'Mild', 'Moderate', 'Severe'
  final String promptEn;
  final String promptUr;
  final int targetDurationSeconds;

  const TherapistGoalModel({
    required this.id,
    required this.domainId,
    required this.titleEn,
    required this.titleUr,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.gameType,
    this.recommendedLevel = 'All',
    required this.promptEn,
    required this.promptUr,
    this.targetDurationSeconds = 120,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'domain_id': domainId,
      'title_en': titleEn,
      'title_ur': titleUr,
      'description_en': descriptionEn,
      'description_ur': descriptionUr,
      'game_type': gameType,
      'recommended_level': recommendedLevel,
      'prompt_en': promptEn,
      'prompt_ur': promptUr,
      'target_duration_seconds': targetDurationSeconds,
    };
  }

  factory TherapistGoalModel.fromMap(Map<String, dynamic> map) {
    return TherapistGoalModel(
      id: map['id'] as String? ?? '',
      domainId: map['domain_id'] as String? ?? '',
      titleEn: map['title_en'] as String? ?? '',
      titleUr: map['title_ur'] as String? ?? '',
      descriptionEn: map['description_en'] as String? ?? '',
      descriptionUr: map['description_ur'] as String? ?? '',
      gameType: map['game_type'] as String? ?? 'drag_sequence',
      recommendedLevel: map['recommended_level'] as String? ?? 'All',
      promptEn: map['prompt_en'] as String? ?? '',
      promptUr: map['prompt_ur'] as String? ?? '',
      targetDurationSeconds: (map['target_duration_seconds'] as num?)?.toInt() ?? 120,
    );
  }
}

class TherapistDomainModel {
  final String id;
  final int indexNumber;
  final String titleEn;
  final String titleUr;
  final String category;
  final IconData icon;
  final LinearGradient gradient;
  final String descriptionEn;
  final String descriptionUr;
  final List<TherapistGoalModel> goals;

  const TherapistDomainModel({
    required this.id,
    required this.indexNumber,
    required this.titleEn,
    required this.titleUr,
    required this.category,
    required this.icon,
    required this.gradient,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.goals,
  });

  static List<TherapistDomainModel> get allDomains => [
    // 1. Receptive Language
    const TherapistDomainModel(
      id: 'dom_01',
      indexNumber: 1,
      titleEn: 'Receptive Language & Processing',
      titleUr: 'سمعی ادراک اور زبان فہمی',
      category: 'Communication',
      icon: Icons.hearing_rounded,
      gradient: AppTheme.blueCyanGradient,
      descriptionEn: 'Following multi-step verbal cues and identifying spoken sounds & objects.',
      descriptionUr: 'زبانی ہدایات پر عمل کرنا اور آوازوں کی پہچان۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_01_1',
          domainId: 'dom_01',
          titleEn: 'Identify Daily Spoken Routine Tool',
          titleUr: 'روزمرہ اشیاء کی زبانی پہچان',
          descriptionEn: 'Listen to the audio cue and tap the matching self-care item.',
          descriptionUr: 'آواز سنیں اور متعلقہ چیز پر کلک کریں۔',
          gameType: 'matching_sorting',
          promptEn: 'Tap the Toothbrush to clean your teeth!',
          promptUr: 'دانت صاف کرنے کے لیے ٹوتھ برش پر ٹیپ کریں!',
        ),
        TherapistGoalModel(
          id: 'goal_01_2',
          domainId: 'dom_01',
          titleEn: 'Two-Step Object Selection',
          titleUr: 'دو مرحلہ اشیاء کی شناخت',
          descriptionEn: 'Pick soap first, then water tap in correct spoken order.',
          descriptionUr: 'پہلے صابن پھر نلکے کے پانی کو منتخب کریں۔',
          gameType: 'drag_sequence',
          promptEn: 'Pick soap first and rinse with water!',
          promptUr: 'پہلے صابن لیں اور پھر پانی سے دھوئیں!',
        ),
      ],
    ),

    // 2. Expressive Language
    const TherapistDomainModel(
      id: 'dom_02',
      indexNumber: 2,
      titleEn: 'Expressive Language & Vocalization',
      titleUr: 'اظہار بیان اور زبانی گفتگو',
      category: 'Communication',
      icon: Icons.record_voice_over_rounded,
      gradient: AppTheme.orangePinkGradient,
      descriptionEn: 'Encouraging verbal speech, phonics articulation, and functional word requests.',
      descriptionUr: 'الفاظ کی ادائیگی اور زبانی ضروریات کا اظہار۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_02_1',
          domainId: 'dom_02',
          titleEn: 'Say "Saaf" / "Clean" Phonics Challenge',
          titleUr: '"صاف" بولنے کی مشق',
          descriptionEn: 'Articulate target self-care hygiene word into the microphone.',
          descriptionUr: 'مائیکروفون میں صاف ہونے کا لفظ بولیں۔',
          gameType: 'voice_phonics',
          promptEn: 'Say clearly: "Clean and Fresh!"',
          promptUr: 'آواز میں بولیں: "میرے ہاتھ صاف ہیں!"',
        ),
        TherapistGoalModel(
          id: 'goal_02_2',
          domainId: 'dom_02',
          titleEn: 'Vocalize "Help Please"',
          titleUr: '"مدد چاہیے" بولنا',
          descriptionEn: 'Encourage child to verbalize help when facing an obstacle.',
          descriptionUr: 'مشکل وقت میں مدد مانگنے کی زبانی مشق۔',
          gameType: 'voice_phonics',
          promptEn: 'Say: "Help please buddy!"',
          promptUr: 'کہیں: "میری مدد کریں دوست!"',
        ),
      ],
    ),

    // 3. Joint Attention
    const TherapistDomainModel(
      id: 'dom_03',
      indexNumber: 3,
      titleEn: 'Joint Attention & Eye Contact',
      titleUr: 'باہمی توجہ اور آنکھوں کا رابطہ',
      category: 'Social',
      icon: Icons.visibility_rounded,
      gradient: AppTheme.purpleBlueGradient,
      descriptionEn: 'Fostering shared gaze, pointing recognition, and responsive attention shifts.',
      descriptionUr: 'مشترکہ توجہ اور اشارے کی طرف دیکھنے کی تربیت۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_03_1',
          domainId: 'dom_03',
          titleEn: 'Eye Contact Mirror Gaze',
          titleUr: 'کیمرے میں آنکھوں کا رابطہ',
          descriptionEn: 'Gaze into the center mirror frame for 4 sustained seconds.',
          descriptionUr: '۴ سیکنڈ تک کیمرے میں دوستانہ نظر رکھیں۔',
          gameType: 'emotion_mirror',
          promptEn: 'Look at your cheerful companion in the mirror!',
          promptUr: 'شیشے میں اپنے پیارے دوست کی آنکھوں میں دیکھیں!',
        ),
      ],
    ),

    // 4. Emotion Recognition
    const TherapistDomainModel(
      id: 'dom_04',
      indexNumber: 4,
      titleEn: 'Emotion Recognition & Mirroring',
      titleUr: 'جذبات کی پہچان اور اظہار',
      category: 'Emotional',
      icon: Icons.sentiment_very_satisfied_rounded,
      gradient: AppTheme.sunshineGradient,
      descriptionEn: 'Decoding facial expressions and expressing happy, calm, and curious emotions.',
      descriptionUr: 'چہرے کے تاثرات کی پہچان اور مسکراہٹ کا اظہار۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_04_1',
          domainId: 'dom_04',
          titleEn: 'Big Bright Happy Smile Challenge',
          titleUr: 'خوبصورت مسکراہٹ کیمرہ مشن',
          descriptionEn: 'Show a joyful smile to the camera to fill the Joy-O-Meter.',
          descriptionUr: 'کیمرے میں اپنی پیاری مسکراہٹ دکھائیں۔',
          gameType: 'emotion_mirror',
          promptEn: 'Show your happiest superstar smile to the camera!',
          promptUr: 'کیمرے کے سامنے اپنی سب سے پیاری مسکراہٹ لائیں!',
        ),
        TherapistGoalModel(
          id: 'goal_04_2',
          domainId: 'dom_04',
          titleEn: 'Sort Happy vs Surprised Emotions',
          titleUr: 'خوشی اور حیرت کے چہرے الگ کرنا',
          descriptionEn: 'Drag emotion faces into the right feeling boxes.',
          descriptionUr: 'مختلف چہروں کو درست خانے میں ڈالیں۔',
          gameType: 'matching_sorting',
          promptEn: 'Match the happy smiling face to the sun!',
          promptUr: 'مسکراتے چہرے کو سورج کے ساتھ جوڑیں!',
        ),
      ],
    ),

    // 5. Social Play & Turn Taking
    const TherapistDomainModel(
      id: 'dom_05',
      indexNumber: 5,
      titleEn: 'Social Play & Turn-Taking',
      titleUr: 'سماجی کھیل اور باری کا انتظار',
      category: 'Social',
      icon: Icons.people_alt_rounded,
      gradient: AppTheme.greenMintGradient,
      descriptionEn: 'Practicing waiting for turn, sharing virtual toys, and interactive cooperation.',
      descriptionUr: 'باری کا انتظار کرنا اور مل کر کھیلنا۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_05_1',
          domainId: 'dom_05',
          titleEn: 'My Turn, Your Turn Interactive Tap',
          titleUr: 'میری باری اور آپ کی باری',
          descriptionEn: 'Wait for companion pet to complete turn before tapping.',
          descriptionUr: 'دوست کے بعد اپنی باری پر کلک کریں۔',
          gameType: 'matching_sorting',
          promptEn: 'Wait for the green light, then tap your turn!',
          promptUr: 'سبز بتی جلنے پر اپنی باری لیں!',
        ),
      ],
    ),

    // 6. Fine Motor & Hand-Eye
    const TherapistDomainModel(
      id: 'dom_06',
      indexNumber: 6,
      titleEn: 'Fine Motor & Hand-Eye Coordination',
      titleUr: 'باریک حرکات اور ہاتھ آنکھ کا تال میل',
      category: 'Motor',
      icon: Icons.touch_app_rounded,
      gradient: AppTheme.purpleBlueGradient,
      descriptionEn: 'Precision tapping, line tracing, button fastening, and pinch gestures.',
      descriptionUr: 'انگلیوں کی گرفت، لکیر کھینچنا اور باریک کام۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_06_1',
          domainId: 'dom_06',
          titleEn: 'Shoelace Loop & Knot Tracing',
          titleUr: 'تسمے کی گرہ لگانے کی مشق',
          descriptionEn: 'Trace the glowing loop path with finger to tie the knot.',
          descriptionUr: 'انگلی سے چمکتی لکیر پر گرہ لگائیں۔',
          gameType: 'fine_motor_trace',
          promptEn: 'Trace the bunny loop from start to star!',
          promptUr: 'تارے تک انگلی سے لکیر مکمل کریں!',
        ),
      ],
    ),

    // 7. Gross Motor & Balance
    const TherapistDomainModel(
      id: 'dom_07',
      indexNumber: 7,
      titleEn: 'Gross Motor & Movement Rhythm',
      titleUr: 'بڑی جسمانی حرکات اور توازن',
      category: 'Motor',
      icon: Icons.directions_run_rounded,
      gradient: AppTheme.orangePinkGradient,
      descriptionEn: 'Bilateral coordination, rhythmic full body stretching, and movement miming.',
      descriptionUr: 'جسمانی ورزش، توازن اور ہلکی پھلکی اسٹریچنگ۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_07_1',
          domainId: 'dom_07',
          titleEn: 'Morning Stretch & Reach Skyward',
          titleUr: 'صبح کی انگڑائی اور ہاتھ اوپر کرنا',
          descriptionEn: 'Interactive motion detection stretch challenge.',
          descriptionUr: 'ہاتھ اوپر اٹھا کر ستارے چھونے کا کھیل۔',
          gameType: 'emotion_mirror',
          promptEn: 'Reach both hands high up in the mirror!',
          promptUr: 'شیشے کے سامنے دونوں ہاتھ آسمان کی طرف اٹھائیں!',
        ),
      ],
    ),

    // 8. Sensory Processing & Tolerance
    const TherapistDomainModel(
      id: 'dom_08',
      indexNumber: 8,
      titleEn: 'Sensory Processing & Regulation',
      titleUr: 'حسی توازن اور سکون',
      category: 'Sensory',
      icon: Icons.spa_rounded,
      gradient: AppTheme.calmLavenderGradient,
      descriptionEn: 'Sensory grounding, sound tolerance soothing, and visual calming rhythms.',
      descriptionUr: 'حسی سکون اور پرسکون ماحول کی عادت۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_08_1',
          domainId: 'dom_08',
          titleEn: 'Zen Bubble Sensory Pop',
          titleUr: 'پرسکون بلبلے پھوڑنے کا کھیل',
          descriptionEn: 'Pop soothing pastel bubbles at your own gentle pace.',
          descriptionUr: 'اپنی مرضی کی رفتار سے نرم بلبلے پھوڑیں۔',
          gameType: 'sensory_breathe',
          promptEn: 'Pop the calm glowing bubbles gently.',
          promptUr: 'آہستہ آہستہ رنگ برنگے بلبلوں پر ٹیپ کریں۔',
        ),
      ],
    ),

    // 9. Self-Care: Hygiene & Handwashing
    const TherapistDomainModel(
      id: 'dom_09',
      indexNumber: 9,
      titleEn: 'Self-Care: Hygiene & Handwashing',
      titleUr: 'ذاتی صفائی: ہاتھ دھونا',
      category: 'SelfCare',
      icon: Icons.soap_rounded,
      gradient: AppTheme.blueCyanGradient,
      descriptionEn: 'Step-by-step soap lathering, palm rubbing, water rinsing, and towel drying.',
      descriptionUr: 'صابن لگانا، ہاتھ رگڑنا، پانی سے دھونا اور تولیے کا استعمال۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_09_1',
          domainId: 'dom_09',
          titleEn: 'Complete 4-Step Handwash Sequence',
          titleUr: 'ہاتھ دھونے کے ۴ مراحل کی ترتیب',
          descriptionEn: 'Order: Water On &rarr; Soap Rub &rarr; Rinse &rarr; Towel Dry.',
          descriptionUr: 'پانی &rarr; صابن &rarr; دھونا &rarr; تولیہ۔',
          gameType: 'drag_sequence',
          promptEn: 'Put the handwashing steps in the correct magic order!',
          promptUr: 'ہاتھ دھونے کے مراحل کو درست ترتیب میں رکھیں!',
        ),
      ],
    ),

    // 10. Self-Care: Dressing & Fasteners
    const TherapistDomainModel(
      id: 'dom_10',
      indexNumber: 10,
      titleEn: 'Self-Care: Dressing & Fasteners',
      titleUr: 'لباس پہننا اور بٹن لگانا',
      category: 'SelfCare',
      icon: Icons.checkroom_rounded,
      gradient: AppTheme.greenMintGradient,
      descriptionEn: 'Sequencing shirts, pants, socks, buttoning, and zipper closure.',
      descriptionUr: 'کپڑے پہننے کی ترتیب اور بٹن بند کرنا۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_10_1',
          domainId: 'dom_10',
          titleEn: 'Morning Outfit Hero Ordering',
          titleUr: 'صبح کے کپڑوں کا انتخاب',
          descriptionEn: 'Drag clothes onto character in sequential dressing order.',
          descriptionUr: 'کردار کو ترتیب سے کپڑے پہنائیں۔',
          gameType: 'drag_sequence',
          promptEn: 'Dress up the hero starting with the comfy shirt!',
          promptUr: 'سب سے پہلے شرٹ اور پھر پینٹ پہنائیں!',
        ),
      ],
    ),

    // 11. Self-Care: Toileting Routine
    const TherapistDomainModel(
      id: 'dom_11',
      indexNumber: 11,
      titleEn: 'Self-Care: Potty & Toilet Routine',
      titleUr: 'واش روم اور بیت الخلاء کی عادات',
      category: 'SelfCare',
      icon: Icons.wc_rounded,
      gradient: AppTheme.orangePinkGradient,
      descriptionEn: 'Step-by-step visual potty routine, wiping cues, and hygiene safety.',
      descriptionUr: 'واش روم کے مراحل اور پاکیزگی کا خیال۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_11_1',
          domainId: 'dom_11',
          titleEn: 'Visual Potty Steps Sequencing',
          titleUr: 'واش روم کے مراحل کی پہچان',
          descriptionEn: 'Door Close &rarr; Sit &rarr; Wipe &rarr; Flush &rarr; Wash Hands.',
          descriptionUr: 'دروازہ بند &rarr; بیٹھنا &rarr; فلش &rarr; ہاتھ دھونا۔',
          gameType: 'drag_sequence',
          promptEn: 'Arrange the potty routine steps safely and neatly!',
          promptUr: 'واش روم کے تمام مراحل کو درست ترتیب دیں!',
        ),
      ],
    ),

    // 12. Daily Living: Mealtime & Feeding
    const TherapistDomainModel(
      id: 'dom_12',
      indexNumber: 12,
      titleEn: 'Daily Living: Mealtime & Utensils',
      titleUr: 'کھانے کے آداب اور برتنوں کا استعمال',
      category: 'SelfCare',
      icon: Icons.restaurant_rounded,
      gradient: AppTheme.sunshineGradient,
      descriptionEn: 'Spoon and fork sorting, napkin usage, and paced eating intervals.',
      descriptionUr: 'چمچ اور کانٹے کا درست استعمال اور آرام سے کھانا۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_12_1',
          domainId: 'dom_12',
          titleEn: 'Sort Spoon, Plate, and Water Cup',
          titleUr: 'چمچ، پلیٹ اور گلاس کی ترتیب',
          descriptionEn: 'Sort dining items onto the clean placemat.',
          descriptionUr: 'کھانے کی میز پر برتنوں کو صحیح جگہ رکھیں۔',
          gameType: 'matching_sorting',
          promptEn: 'Place the spoon on the right and cup on top!',
          promptUr: 'چمچ کو پلیٹ کے ساتھ اور گلاس کو اوپر رکھیں!',
        ),
      ],
    ),

    // 13. Cognitive: Matching & Sorting
    const TherapistDomainModel(
      id: 'dom_13',
      indexNumber: 13,
      titleEn: 'Cognitive: Object Matching & Sorting',
      titleUr: 'ذہنی صلاحیت: اشیاء کی درجہ بندی',
      category: 'Cognitive',
      icon: Icons.category_rounded,
      gradient: AppTheme.blueCyanGradient,
      descriptionEn: 'Categorizing by functional use, colors, textures, and daily utility.',
      descriptionUr: 'رنگوں، اشکال اور استعمال کے لحاظ سے چھانٹی۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_13_1',
          domainId: 'dom_13',
          titleEn: 'Sort School Items vs Bedtime Items',
          titleUr: 'اسکول کی چیزیں اور سونے کی چیزیں الگ کرنا',
          descriptionEn: 'Drag books to school bag and pillows to bed.',
          descriptionUr: 'کتابوں کو بستہ میں اور تکیہ کو بستر پر رکھیں۔',
          gameType: 'matching_sorting',
          promptEn: 'Sort school supplies into the backpack!',
          promptUr: 'اسکول کی چیزیں بستہ میں ڈالیں!',
        ),
      ],
    ),

    // 14. Cognitive: Sequencing & Patterns
    const TherapistDomainModel(
      id: 'dom_14',
      indexNumber: 14,
      titleEn: 'Cognitive: Sequencing & Patterns',
      titleUr: 'ترتیب اور پیٹرن کی سمجھ',
      category: 'Cognitive',
      icon: Icons.timeline_rounded,
      gradient: AppTheme.greenMintGradient,
      descriptionEn: 'Predicting next daily steps, visual AB patterns, and time sequences.',
      descriptionUr: 'اگلے مرحلے کی پیشگوئی اور وقت کی ترتیب۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_14_1',
          domainId: 'dom_14',
          titleEn: 'Morning &rarr; Afternoon &rarr; Night Order',
          titleUr: 'صبح، دوپہر اور رات کا تسلسل',
          descriptionEn: 'Sequence Sun, Clock, and Moon in chronologic routine.',
          descriptionUr: 'سورج، دوپہر اور چاند کو ترتیب دیں۔',
          gameType: 'drag_sequence',
          promptEn: 'Order the day from Morning to Bedtime!',
          promptUr: 'صبح سے رات تک کے اوقات کو ترتیب دیں!',
        ),
      ],
    ),

    // 15. Visual-Spatial & Puzzles
    const TherapistDomainModel(
      id: 'dom_15',
      indexNumber: 15,
      titleEn: 'Visual-Spatial & Shape Alignment',
      titleUr: 'بصری فہم اور اشکال کا تال میل',
      category: 'Cognitive',
      icon: Icons.extension_rounded,
      gradient: AppTheme.purpleBlueGradient,
      descriptionEn: 'Fitting visual puzzle pieces, spatial rotation, and geometry pairing.',
      descriptionUr: 'پزل جوڑنا اور اشکال کو صحیح جگہ بٹھانا۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_15_1',
          domainId: 'dom_15',
          titleEn: 'Routine Badge Puzzle Match',
          titleUr: 'انعامی تمغے کی پزل مکمل کرنا',
          descriptionEn: 'Match target shape silhouettes with glowing badge pieces.',
          descriptionUr: 'اشکال کو ان کے سائے سے ملائیں۔',
          gameType: 'matching_sorting',
          promptEn: 'Fit the star and circle pieces into their spots!',
          promptUr: 'ستارے اور دائرے کو ان کے فریم میں بٹھائیں!',
        ),
      ],
    ),

    // 16. Executive Functioning & Focus
    const TherapistDomainModel(
      id: 'dom_16',
      indexNumber: 16,
      titleEn: 'Executive Functioning & Task Initiation',
      titleUr: 'توجہ مرکوز رکھنا اور کام کا آغاز',
      category: 'Independence',
      icon: Icons.timer_outlined,
      gradient: AppTheme.orangePinkGradient,
      descriptionEn: 'Overcoming task hesitation, single-target focus, and transition readiness.',
      descriptionUr: 'بلا جھجھک کام شروع کرنا اور توجہ قائم رکھنا۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_16_1',
          domainId: 'dom_16',
          titleEn: 'Single Target 30-Second Focus Game',
          titleUr: '۳۰ سیکنڈ کی توجہ کا کھیل',
          descriptionEn: 'Follow the floating star smoothly across the screen.',
          descriptionUr: 'اسکرین پر حرکت کرتے تارے کے ساتھ توجہ رکھیں۔',
          gameType: 'fine_motor_trace',
          promptEn: 'Keep your finger following the guiding light!',
          promptUr: 'چمکتی روشنی کے ساتھ ساتھ انگلی چلائیں!',
        ),
      ],
    ),

    // 17. Coping & Calming Breathing
    const TherapistDomainModel(
      id: 'dom_17',
      indexNumber: 17,
      titleEn: 'Coping Mechanisms & Calming Breathing',
      titleUr: 'پرسکون سانس اور جذباتی ضبط',
      category: 'Coping',
      icon: Icons.air_rounded,
      gradient: AppTheme.blueCyanGradient,
      descriptionEn: '4-second rhythmic inhalation and exhalation with glowing visual pacer.',
      descriptionUr: '۴ سیکنڈ کی پرسکون سانس لینے اور نکالنے کی مشق۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_17_1',
          domainId: 'dom_17',
          titleEn: '4-Count Expanding Ring Breathe',
          titleUr: '۴ گنتی کے ساتھ گہرا سانس لینا',
          descriptionEn: 'Expand with blue core, exhale with gentle green halo.',
          descriptionUr: 'دائرہ بڑا ہونے پر سانس لیں، چھوٹا ہونے پر نکالیں۔',
          gameType: 'sensory_breathe',
          promptEn: 'Breathe in deep with the ring... and gently out.',
          promptUr: 'دائرے کے ساتھ گہرا سانس لیں... اور آہستہ سے باہر نکالیں۔',
        ),
      ],
    ),

    // 18. Safety Awareness
    const TherapistDomainModel(
      id: 'dom_18',
      indexNumber: 18,
      titleEn: 'Safety Awareness & Hazard Recognition',
      titleUr: 'حفاظتی تدابیر اور خطرات کی پہچان',
      category: 'Independence',
      icon: Icons.health_and_safety_rounded,
      gradient: AppTheme.sunshineGradient,
      descriptionEn: 'Hot vs cold recognition, road stop signs, and safe touch awareness.',
      descriptionUr: 'گرم اشیاء سے احتیاط اور سڑک پار کرنے کے اشارے۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_18_1',
          domainId: 'dom_18',
          titleEn: 'Hot Stove vs Cold Ice Sorting',
          titleUr: 'گرم اور ٹھنڈی چیزوں کی تمیز',
          descriptionEn: 'Sort hot objects to warning side and cold to safe side.',
          descriptionUr: 'گرم چیزوں کو احتیاط کے خانے میں رکھیں۔',
          gameType: 'matching_sorting',
          promptEn: 'Identify hot kettle vs cool water glass!',
          promptUr: 'گرم چائے اور ٹھنڈے پانی کے گلاس کی پہچان کریں!',
        ),
      ],
    ),

    // 19. Non-Verbal Communication
    const TherapistDomainModel(
      id: 'dom_19',
      indexNumber: 19,
      titleEn: 'Non-Verbal Gestures & Signs',
      titleUr: 'غیر زبانی اشارے اور جسمانی زبان',
      category: 'Communication',
      icon: Icons.waving_hand_rounded,
      gradient: AppTheme.greenMintGradient,
      descriptionEn: 'Thumbs up for "Yes/Good", waving hello/bye, and pointing to indicate need.',
      descriptionUr: 'انگوٹھا دکھانا، ہاتھ ہلانا اور اشارے کرنا۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_19_1',
          domainId: 'dom_19',
          titleEn: 'Wave Hello in Mirror Camera',
          titleUr: 'شیشے میں ہاتھ ہلا کر سلام کرنا',
          descriptionEn: 'Wave to companion mascot to unlock friendly greeting.',
          descriptionUr: 'کیمرے کے سامنے ہاتھ ہلا کر سلام کریں۔',
          gameType: 'emotion_mirror',
          promptEn: 'Wave your friendly hand hello to your buddy!',
          promptUr: 'اپنے دوست کو ہاتھ ہلا کر سلام کریں!',
        ),
      ],
    ),

    // 20. Independence & Task Completion
    const TherapistDomainModel(
      id: 'dom_20',
      indexNumber: 20,
      titleEn: 'Independence & Daily Checklist',
      titleUr: 'خود انحصاری اور کاموں کی تکمیل',
      category: 'Independence',
      icon: Icons.checklist_rounded,
      gradient: AppTheme.purpleBlueGradient,
      descriptionEn: 'Checking off daily checklist, toy cleanup, and self-monitoring.',
      descriptionUr: 'اپنے کھلونے سمیٹنا اور کام مکمل کرنا۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_20_1',
          domainId: 'dom_20',
          titleEn: 'Tidy Up Toy Box Sorting Mission',
          titleUr: 'کھلونے باکس میں رکھنے کا مشن',
          descriptionEn: 'Drag scattered toys into the cheerful toy storage chest.',
          descriptionUr: 'کھلونوں کو ان کے باکس میں ترتیب سے رکھیں۔',
          gameType: 'matching_sorting',
          promptEn: 'Put the teddy and cars into the toy box!',
          promptUr: 'گاڑی اور ٹیڈی بیئر کو کھلونوں کے باکس میں رکھیں!',
        ),
      ],
    ),

    // 21. School Readiness & Organization
    const TherapistDomainModel(
      id: 'dom_21',
      indexNumber: 21,
      titleEn: 'School Readiness & Bag Packing',
      titleUr: 'اسکول کی تیاری اور بستہ پیک کرنا',
      category: 'School',
      icon: Icons.backpack_rounded,
      gradient: AppTheme.blueCyanGradient,
      descriptionEn: 'Packing notebook, pencil pouch, lunchbox, and water flask.',
      descriptionUr: 'کاپیاں، پنسل باکس اور لنچ باکس بستے میں رکھنا۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_21_1',
          domainId: 'dom_21',
          titleEn: 'School Backpack Packing Sequence',
          titleUr: 'اسکول بستہ ترتیب سے پیک کرنا',
          descriptionEn: 'Books &rarr; Pouch &rarr; Lunchbox &rarr; Water Bottle.',
          descriptionUr: 'کتابیں &rarr; پنسل باکس &rarr; لنچ &rarr; پانی بوتل۔',
          gameType: 'drag_sequence',
          promptEn: 'Pack your school essentials into the backpack!',
          promptUr: 'تمام ضروری اشیاء کو اسکول بیگ میں ڈالیں!',
        ),
      ],
    ),

    // 22. Tactile Exploration
    const TherapistDomainModel(
      id: 'dom_22',
      indexNumber: 22,
      titleEn: 'Tactile Exploration & Texture Calm',
      titleUr: 'لمسی احساس اور نرم بناوٹ',
      category: 'Sensory',
      icon: Icons.texture_rounded,
      gradient: AppTheme.orangePinkGradient,
      descriptionEn: 'Interactive particle tracing, gentle sand rubbing, and tactile tolerance.',
      descriptionUr: 'اسکرین پر نرم ساخت کی لکیریں اور لمسی مشق۔',
      goals: [
        TherapistGoalModel(
          id: 'goal_22_1',
          domainId: 'dom_22',
          titleEn: 'Rainbow Sand Glow Tracing',
          titleUr: 'رنگ برنگی ریت پر لکیر کھینچنا',
          descriptionEn: 'Rub finger across screen to reveal hidden rainbow stars.',
          descriptionUr: 'اسکرین پر انگلی پھیر کر چھپے ہوئے ستارے نکالیں۔',
          gameType: 'fine_motor_trace',
          promptEn: 'Smoothly trace through the glowing rainbow path!',
          promptUr: 'چمکتے راستے پر انگلی پھیر کر جادو جگائیں!',
        ),
      ],
    ),
  ];
}
