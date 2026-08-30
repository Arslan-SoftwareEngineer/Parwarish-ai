import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:camera/camera.dart';

class LessonScreen extends StatefulWidget {
  final String lessonTitle;
  final String videoUrl;
  final String englishPrompt;
  final String urduPrompt;
  final String interactionType; // 'voice', 'camera', or 'breathe'
  final bool isUrdu;

  const LessonScreen({
    super.key,
    required this.lessonTitle,
    required this.videoUrl,
    required this.englishPrompt,
    required this.urduPrompt,
    required this.interactionType,
    required this.isUrdu
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String _childId = '';
  int _struggleFlags = 0;
  bool _showAiPrompt = false;
  bool _lessonComplete = false;

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _spokenText = '';

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _setupTts();
    _initVideo();
    if (widget.interactionType == 'camera') {
      _initCamera();
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    _videoController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _childId = prefs.getString('child_id') ?? '';
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCam = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
      _cameraController = CameraController(frontCam, ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  Future<void> _setupTts() async {
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.2);
    await _flutterTts.setLanguage(widget.isUrdu ? "ur-PK" : "en-US");
  }

  Future<void> _speakPrompt() async {
    await _flutterTts.speak(widget.isUrdu ? widget.urduPrompt : widget.englishPrompt);
  }

  void _initVideo() {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _isVideoInitialized = true);
        _videoController.play();
      });

    _videoController.addListener(() {
      if (_videoController.value.isInitialized &&
          _videoController.value.position >= _videoController.value.duration &&
          !_showAiPrompt) {
        setState(() => _showAiPrompt = true);
        _speakPrompt();
      }
    });
  }

  void _onErrantTap() {
    if (_lessonComplete) return;
    setState(() => _struggleFlags++);
    if (_childId.isNotEmpty) {
      FirebaseFirestore.instance.collection('children').doc(_childId).update({
        'struggle_flags': FieldValue.increment(1),
      });
    }
  }

  void _listenToChild() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          localeId: widget.isUrdu ? "ur-PK" : "en-US",
          onResult: (val) {
            setState(() => _spokenText = val.recognizedWords);

            // For 'breathe', any mic activity triggers success. For 'voice', needs words.
            bool success = widget.interactionType == 'breathe'
                ? (val.recognizedWords.isNotEmpty || val.hasConfidenceRating)
                : (val.hasConfidenceRating && val.confidence > 0);

            if (success && !_lessonComplete) {
              _speechToText.stop();
              setState(() => _isListening = false);
              _completeLesson();
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  void _completeLesson() async {
    setState(() => _lessonComplete = true);

    try { _flutterTts.speak(widget.isUrdu ? 'شاباش!' : 'Great Job!'); } catch (_) {}

    if (_childId.isNotEmpty) {
      try {
        // Log the completed module to the Parent Analytics dashboard
        await FirebaseFirestore.instance
            .collection('children')
            .doc(_childId)
            .collection('activity_logs')
            .add({
          'module_name': widget.lessonTitle,
          'interaction_type': widget.interactionType,
          'completed_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Firebase Error: $e");
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.isUrdu ? 'شاباش!' : 'Great Job!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 28, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.orange, size: 80),
            const SizedBox(height: 10),
            Text(
              widget.isUrdu ? 'آپ نے اپنے دوست کو خوش کر دیا!' : 'You made your buddy happy!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CA1AF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: Text(widget.isUrdu ? 'واپس جائیں' : 'Go Back', style: const TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInteractionUI() {
    if (widget.interactionType == 'camera') {
      return Column(
        children: [
          if (_isCameraInitialized)
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFF8C00), width: 4)),
              child: ClipOval(child: CameraPreview(_cameraController!)),
            )
          else
            const CircularProgressIndicator(color: Color(0xFFFF8C00)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
            onPressed: _completeLesson, // Simulates AI detecting the smile
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: Text(widget.isUrdu ? 'مسکرائیں!' : 'I am Smiling!', style: const TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ],
      );
    }

    // For both 'voice' and 'breathe', we use the microphone
    String btnLabel = widget.interactionType == 'breathe'
        ? (widget.isUrdu ? 'سانس لینے کے لیے دبائیں' : 'Tap & Breathe')
        : (widget.isUrdu ? 'بولنے کے لیے دبائیں' : 'Tap to Speak');

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isListening ? Colors.red : const Color(0xFFFF8C00),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: _listenToChild,
          icon: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 30, color: Colors.white),
          label: Text(_isListening ? (widget.isUrdu ? 'سن رہا ہے...' : 'Listening...') : btnLabel, style: const TextStyle(fontSize: 20, color: Colors.white)),
        ),
        const SizedBox(height: 20),
        if (widget.interactionType == 'voice')
          Text(_spokenText, style: const TextStyle(color: Colors.white70, fontSize: 18)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _onErrantTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: _showAiPrompt ? const Color(0xFFFF8C00) : Colors.transparent, width: 4)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _isVideoInitialized
                    ? AspectRatio(aspectRatio: _videoController.value.aspectRatio, child: VideoPlayer(_videoController))
                    : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))),
              ),
            ),
            const SizedBox(height: 40),
            if (_showAiPrompt && !_lessonComplete) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(widget.isUrdu ? widget.urduPrompt : widget.englishPrompt, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              _buildInteractionUI(),
            ]
          ],
        ),
      ),
    );
  }
}