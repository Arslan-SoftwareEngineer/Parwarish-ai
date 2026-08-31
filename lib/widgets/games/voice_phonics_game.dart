import 'package:flutter/material.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';

class VoicePhonicsGame extends StatefulWidget {
  final String promptEn;
  final String promptUr;
  final VoidCallback onGameCompleted;

  const VoicePhonicsGame({
    super.key,
    required this.promptEn,
    required this.promptUr,
    required this.onGameCompleted,
  });

  @override
  State<VoicePhonicsGame> createState() => _VoicePhonicsGameState();
}

class _VoicePhonicsGameState extends State<VoicePhonicsGame> {
  double _soundLevel = 0.0;
  String _recognizedWords = '';

  @override
  void initState() {
    super.initState();
    _startVoiceRecognition();
  }

  Future<void> _startVoiceRecognition() async {
    await SpeechService.instance.initialize();
    final isUrdu = LocalizationService.instance.isUrdu;

    SpeechService.instance.startListening(
      localeId: isUrdu ? 'ur_PK' : 'en_US',
      onResult: (words, confidence) {
        if (!mounted) return;
        setState(() => _recognizedWords = words);
        if (words.isNotEmpty) {
          _triggerSuccess();
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _soundLevel = level);
        if (level > 3.0) {
          _triggerSuccess();
        }
      },
    );
  }

  void _triggerSuccess() {
    final isUrdu = LocalizationService.instance.isUrdu;
    TtsService.instance.speak(
      isUrdu ? 'کیا زبردست آواز ہے! شاباش!' : 'What a powerful, clear voice! Excellent!',
      langCode: isUrdu ? 'ur' : 'en',
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onGameCompleted();
    });
  }

  @override
  void dispose() {
    SpeechService.instance.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;
    final prompt = isUrdu ? widget.promptUr : widget.promptEn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Prompt Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softCardShadow,
            border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.record_voice_over_rounded, color: AppTheme.primaryOrange, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Animated Microphone Soundwave Visualizer
        Stack(
          alignment: Alignment.center,
          children: [
            // Soundwave ripple rings
            Container(
              width: 160 + (_soundLevel * 12),
              height: 160 + (_soundLevel * 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange.withValues(alpha: 0.15),
              ),
            ),
            Container(
              width: 130 + (_soundLevel * 8),
              height: 130 + (_soundLevel * 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange.withValues(alpha: 0.25),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.orangePinkGradient,
                boxShadow: AppTheme.heavyShadow(AppTheme.primaryOrange),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 48),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (_recognizedWords.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Text(
              'Heard: "$_recognizedWords"',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.mintGreen, fontSize: 16),
            ),
          )
        else
          Text(
            isUrdu ? 'مائیکروفون میں بولیں...' : 'Speak into your microphone...',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 14),
          ),

        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: _triggerSuccess,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          label: Text(
            isUrdu ? 'میں نے بول دیا! ✨' : 'I Spoke! ✨',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.mintGreen,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }
}
