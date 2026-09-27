import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class LessonScreen extends StatefulWidget {
  final String lessonTitle;
  final String videoUrl;
  final String englishPrompt;
  final String urduPrompt;
  final String interactionType; // 'voice', 'camera', 'breathe'
  final bool isUrdu;

  const LessonScreen({
    super.key,
    required this.lessonTitle,
    required this.videoUrl,
    required this.englishPrompt,
    required this.urduPrompt,
    required this.interactionType,
    required this.isUrdu,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  // Video Player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasPromptRevealed = false;

  // TTS
  final FlutterTts _flutterTts = FlutterTts();

  // Camera Sensor
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // Speech to text
  final SpeechToText _speechToText = SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  String _recognizedWords = '';

  // Telemetry & Frustration tracking
  int _struggleCount = 0;
  final Stopwatch _sessionStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _sessionStopwatch.start();
    _initTts();
    _initVideo();

    if (widget.interactionType == 'camera') {
      _initCamera();
    } else {
      _initSpeech();
    }
  }

  @override
  void dispose() {
    _sessionStopwatch.stop();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _cameraController?.dispose();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setPitch(1.2);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setLanguage(widget.isUrdu ? "ur-PK" : "en-US");
    } catch (e) {
      debugPrint('TTS config warning: $e');
    }
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoController!.initialize();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
        _videoController!.play();
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Video init warning: $e');
      // If video fails or in headless test environment, directly reveal prompt
      if (mounted) {
        setState(() {
          _hasPromptRevealed = true;
        });
        _speakPrompt();
      }
    }
  }

  void _videoListener() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.position >= _videoController!.value.duration &&
          !_hasPromptRevealed) {
        setState(() {
          _hasPromptRevealed = true;
        });
        _speakPrompt();
      }
    }
  }

  Future<void> _speakPrompt() async {
    try {
      final promptText = widget.isUrdu ? widget.urduPrompt : widget.englishPrompt;
      _flutterTts.speak(promptText);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Camera sensor init warning: $e');
    }
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize();
      if (mounted) {
        setState(() => _isSpeechInitialized = available);
      }
    } catch (e) {
      debugPrint('SpeechToText init warning: $e');
    }
  }

  Future<void> _toggleSpeechListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      if (_isSpeechInitialized) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          localeId: widget.isUrdu ? 'ur_PK' : 'en_US',
          onResult: (result) {
            if (mounted) {
              setState(() {
                _recognizedWords = result.recognizedWords;
              });
            }
            if (result.recognizedWords.isNotEmpty || result.confidence > 0.3) {
              _completeLesson();
            }
          },
        );
      } else {
        // Fallback for tests/environments without audio input
        _completeLesson();
      }
    }
  }

  // Telemetry: Tap outside interaction controls registers as frustration/struggle
  void _onBackgroundTap() async {
    _struggleCount++;
    try {
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString('child_id') ?? 'child_demo_01';

      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('children').doc(childId).update({
          'struggle_flags': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Frustration telemetry error: $e');
    }
  }

  // Completion sequence
  Future<void> _completeLesson() async {
    _sessionStopwatch.stop();

    // 1. TTS speaks praise
    try {
      _flutterTts.speak(widget.isUrdu ? "شاباش!" : "Great Job!");
    } catch (_) {}

    // 2. Add log document to children/{childId}/activity_logs
    try {
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString('child_id') ?? 'child_demo_01';
      final logData = {
        'module_name': widget.lessonTitle,
        'interaction_type': widget.interactionType,
        'completed_at': FieldValue.serverTimestamp(),
        'duration_seconds': _sessionStopwatch.elapsed.inSeconds > 0
            ? _sessionStopwatch.elapsed.inSeconds
            : 30,
        'struggle_count': _struggleCount,
      };

      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(childId)
            .collection('activity_logs')
            .add(logData);
      }
    } catch (e) {
      debugPrint('Activity log sync error: $e');
    }

    // 3. Show celebratory dialog with star animation and pop true
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  gradient: AppTheme.orangePinkGradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.star_rounded, size: 54, color: Colors.white),
                ),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut)
                  .shimmer(delay: 400.ms, duration: 1200.ms),
              const SizedBox(height: 18),
              Text(
                widget.isUrdu ? "شاباش!" : "Great Job!",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isUrdu
                    ? "آپ نے کامیابی کے ساتھ یہ سرگرمی مکمل کی ہے!"
                    : "You successfully completed this quest!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('celebration_done_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  widget.isUrdu ? "جاری رکھیں" : "Continue",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.04),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.interactionType.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6A11CB),
              ),
            ),
          ),
        ],
      ),
      // Wrap scaffold body in GestureDetector to track frustrational taps outside controls
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onBackgroundTap,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Video Player Container
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _isVideoInitialized && _videoController != null
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : Container(
                            color: const Color(0xFF1E293B),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_fill_rounded,
                                      size: 56, color: Colors.white70),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.lessonTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    key: const Key('skip_video_btn'),
                                    onPressed: () {
                                      setState(() => _hasPromptRevealed = true);
                                      _speakPrompt();
                                    },
                                    child: Text(
                                      widget.isUrdu ? 'پریکٹس شروع کریں' : 'Start Practice',
                                      style: const TextStyle(color: AppTheme.electricBlue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. AI Prompt Card (Revealed when position >= duration or on click)
                if (_hasPromptRevealed)
                  Container(
                    key: const Key('prompt_card'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF6A11CB), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A11CB).withOpacity(0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded,
                              color: Color(0xFF6A11CB), size: 28),
                          onPressed: _speakPrompt,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isUrdu ? 'آپ کی باری ہے!' : 'Your Turn!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6A11CB),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.isUrdu ? widget.urduPrompt : widget.englishPrompt,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0)
                else
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _hasPromptRevealed = true);
                        _speakPrompt();
                      },
                      icon: const Icon(Icons.touch_app_rounded),
                      label: Text(widget.isUrdu ? 'پرامپٹ دیکھیں' : 'Reveal Interaction Prompt'),
                    ),
                  ),

                const SizedBox(height: 24),

                // 3. Hardware Sensor Interaction Section
                if (widget.interactionType == 'camera')
                  _buildCameraSensorSection()
                else
                  _buildVoiceOrBreatheSensorSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Camera Sensor UI with Circular Clip
  Widget _buildCameraSensorSection() {
    return Column(
      children: [
        Center(
          child: ClipOval(
            child: SizedBox(
              width: 220,
              height: 220,
              child: _isCameraInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.orangePinkGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          key: const Key('smile_complete_btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF97316),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
          ),
          onPressed: _completeLesson,
          icon: const Icon(Icons.sentiment_very_satisfied_rounded, color: Colors.white, size: 26),
          label: Text(
            widget.isUrdu ? 'مسکرائیں!' : 'I am Smiling!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Voice / Breathe Sensor UI
  Widget _buildVoiceOrBreatheSensorSection() {
    final isBreathe = widget.interactionType == 'breathe';
    final primaryColor = isBreathe ? const Color(0xFF10B981) : AppTheme.electricBlue;

    return Column(
      children: [
        GestureDetector(
          key: const Key('mic_toggle_btn'),
          onTap: _toggleSpeechListening,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: isBreathe ? AppTheme.greenMintGradient : AppTheme.blueCyanGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _isListening
                    ? Icons.mic_rounded
                    : (isBreathe ? Icons.air_rounded : Icons.mic_none_rounded),
                size: 58,
                color: Colors.white,
              ),
            ),
          ),
        )
            .animate(target: _isListening ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 600.ms),

        const SizedBox(height: 16),

        Text(
          _isListening
              ? (widget.isUrdu ? 'سن رہے ہیں...' : 'Listening...')
              : (widget.isUrdu ? 'مائیکروفون دبائیں اور بولیں' : 'Tap to speak or complete'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),

        if (_recognizedWords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"$_recognizedWords"',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        ElevatedButton(
          key: const Key('manual_complete_btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _completeLesson,
          child: Text(
            widget.isUrdu ? 'سبق مکمل ہوا' : 'Mark Lesson Done',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
