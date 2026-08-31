import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService instance = TtsService._internal();
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.45); // Slower, soothing pace for autistic children
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.1); // Cheerful friendly pitch
      _isInitialized = true;
    } catch (e) {
      debugPrint('TtsService init warning: $e');
    }
  }

  Future<void> speak(String text, {String langCode = 'en'}) async {
    try {
      await init();
      final targetLang = langCode == 'ur' ? 'ur-PK' : 'en-US';
      try {
        await _flutterTts.setLanguage(targetLang);
      } catch (_) {
        await _flutterTts.setLanguage('en-US');
      }
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TtsService speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TtsService stop error: $e');
    }
  }
}
