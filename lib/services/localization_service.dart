import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static final LocalizationService instance = LocalizationService._internal();
  LocalizationService._internal();

  static const String _prefKey = 'selected_language';
  final ValueNotifier<String> currentLocale = ValueNotifier<String>('en');

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_prefKey) ?? 'en';
    currentLocale.value = savedLang;
  }

  Future<void> setLocale(String langCode) async {
    currentLocale.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
  }

  void toggleLanguage() {
    if (currentLocale.value == 'en') {
      setLocale('ur');
    } else {
      setLocale('en');
    }
  }

  bool get isUrdu => currentLocale.value == 'ur';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Parwarish.ai',
      'tagline': 'Empowering extraordinary minds with love & play',
      'welcome_back': 'Welcome Back!',
      'parent_login': 'Parent Portal',
      'parent_portal': 'Parent Portal',
      'child_login': 'Child Space',
      'child_space': 'Child Space',
      'email': 'Email Address',
      'password': 'Password',
      'sign_in': 'Sign In',
      'sign_in_with_google': 'Continue with Google',
      'sign_in_with_apple': 'Continue with Apple',
      'demo_login': 'Explore Demo Mode',
      'quick_access': 'Quick Child Access',
      'select_profile': 'Choose Your Hero Profile',
      'add_child': 'Add Child Profile',
      'child_name': 'Child Name',
      'save_child': 'Save Profile',
      'parent_dashboard': 'Parent Dashboard',
      'analytics_title': 'Growth & Strengths',
      'child_profiles': 'My Little Champions',
      'total_play_time': 'Total Active Learning Time',
      'modules_completed': 'Missions Completed',
      'current_streak': 'Day Streak',
      'days': 'Days',
      'mins': 'Mins',
      'daily_reports': 'Daily Reports from Therapist',
      'daily_strengths': 'Daily Strengths & Joys',
      'view_daily_report': 'View Detailed Therapist Report',
      'therapist_notes': 'Therapist Clinical Insights',
      'home_tip': 'Recommended Fun Home Activity',
      'tab_learn': 'Play & Learn',
      'tab_schedule': 'My Routine',
      'tab_badges': 'My Badges',
      'pet_greeting': 'Hello superstar! Let’s play today’s fun mission!',
      'pet_greeting_mild': 'Hello superstar! Ready for today’s fun adventure? ✨',
      'pet_greeting_moderate': 'Hi champion! Tap me to start our play routine! 🌟',
      'pet_greeting_severe': 'Hello hero! Let’s have fun and smile together! 🎈',
      'pet_happy_praise': 'You did it! You are a brilliant superstar!',
      'tap_to_talk': 'Tap to talk to your companion',
      'start_lesson': 'Start Mission',
      'how_did_you_feel': 'How did you feel during this mission?',
      'mood_happy': 'Happy & Joyful 😄',
      'mood_calm': 'Calm & Peaceful 🧘',
      'mood_excited': 'Super Excited ⚡',
      'mood_focused': 'Super Focused 🎯',
      'mood_tired': 'A bit tired 😴',
      'congratulations': 'Awesome Job!',
      'reward_stars': '+50 Stars Earned!',
      'continue_btn': 'Continue Adventure',
      'logout': 'Sign Out',
      'switch_role': 'Switch Account Role',
      'no_children_yet': 'No child profiles yet. Tap + to create one!',
      'no_reports_yet': 'No reports yet. Check back after today’s session!',
    },
    'ur': {
      'app_name': 'پرورش ڈاٹ اے آئی',
      'tagline': 'محبت، کھیل اور سائنسی مہارت سے بچوں کی بہترین رہنمائی',
      'welcome_back': 'خوش آمدید!',
      'parent_login': 'والدین کا پورٹل',
      'parent_portal': 'والدین کا پورٹل',
      'child_login': 'بچوں کا کارنر',
      'child_space': 'بچوں کا کارنر',
      'email': 'ای میل ایڈریس',
      'password': 'پاس ورڈ',
      'sign_in': 'لاگ ان کریں',
      'sign_in_with_google': 'گوگل کے ساتھ لاگ ان',
      'sign_in_with_apple': 'ایپل کے ساتھ لاگ ان',
      'demo_login': 'ڈیمو موڈ دیکھیں',
      'quick_access': 'بچوں کا فوری داخلہ',
      'select_profile': 'اپنا پروفائل منتخب کریں',
      'add_child': 'نیا پروفائل شامل کریں',
      'child_name': 'بچے کا نام',
      'save_child': 'پروفائل محفوظ کریں',
      'parent_dashboard': 'والدین کا ڈیش بورڈ',
      'analytics_title': 'ترقی اور نمایاں صلاحیتیں',
      'child_profiles': 'ہمارے پیارے چیمپیئنز',
      'total_play_time': 'سیکھنے کا کل وقت',
      'modules_completed': 'مکمل شدہ مشنز',
      'current_streak': 'مسلسل دن (Streak)',
      'days': 'دن',
      'mins': 'منٹ',
      'daily_reports': 'تھراپسٹ کی روزانہ کی رپورٹ',
      'daily_strengths': 'روزانہ کی خوبیاں اور ادراک',
      'view_daily_report': 'تھراپسٹ کی تفصیلی رپورٹ دیکھیں',
      'therapist_notes': 'ماہر تھراپسٹ کے تاثرات',
      'home_tip': 'گھر میں کرنے کی خوشگوار مشق',
      'tab_learn': 'سیکھیں اور کھیلیں',
      'tab_schedule': 'میرا شیڈول',
      'tab_badges': 'میرے انعامات',
      'pet_greeting': 'ہیلو سپر اسٹار! آئیں آج کا مزے دار مشن کریں!',
      'pet_greeting_mild': 'ہیلو سپر اسٹار! آئیں آج کا نیا ایڈونچر کھیلیں! ✨',
      'pet_greeting_moderate': 'شاباش چیمپئن! مشن شروع کرنے کے لیے مجھے چھوئیں! 🌟',
      'pet_greeting_severe': 'ہیلو پیارے ہیرو! آئیں مل کر کھیلیں اور مسکرائیں! 🎈',
      'pet_happy_praise': 'شاباش! آپ نے بہت شاندار کارکردگی دکھائی!',
      'tap_to_talk': 'بات کرنے کے لیے دوست کو چھوئیں',
      'start_lesson': 'مشن شروع کریں',
      'how_did_you_feel': 'اس مشن کے دوران آپ نے کیسا محسوس کیا؟',
      'mood_happy': 'بہت خوش اور پرجوش 😄',
      'mood_calm': 'پرسکون اور آرام دہ 🧘',
      'mood_excited': 'بہت انرجیٹک ⚡',
      'mood_focused': 'مکمل توجہ کے ساتھ 🎯',
      'mood_tired': 'تھوڑا سا تھکا ہوا 😴',
      'congratulations': 'شاندار کارکردگی!',
      'reward_stars': '+۵۰ ستارے ملے!',
      'continue_btn': 'جاری رکھیں',
      'logout': 'لاگ آؤٹ',
      'switch_role': 'اکاؤنٹ کا کردار تبدیل کریں',
      'no_children_yet': 'ابھی کوئی پروفائل موجود نہیں۔ نیا شامل کرنے کے لیے + دبائیں!',
      'no_reports_yet': 'ابھی کوئی رپورٹ موصول نہیں ہوئی۔ آج کی سرگرمی کے بعد حاضر ہوگی!',
    },
  };

  String tr(String key) {
    final lang = currentLocale.value;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
