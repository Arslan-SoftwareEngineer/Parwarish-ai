import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechService instance = SpeechService._internal();
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String words, double confidence) onResult,
    Function(double soundLevel)? onSoundLevelChange,
    String localeId = 'en_US',
  }) async {
    if (!_isAvailable) {
      final initOk = await initialize();
      if (!initOk) {
        debugPrint('Microphone / STT not available');
        return;
      }
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (val) {
          onResult(val.recognizedWords, val.confidence);
        },
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      _isListening = false;
      debugPrint('Error starting speech listen: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      _isListening = false;
      await _speech.stop();
    } catch (e) {
      debugPrint('Error stopping speech listen: $e');
    }
  }
}
