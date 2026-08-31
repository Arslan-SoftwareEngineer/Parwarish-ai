import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static final CameraService instance = CameraService._internal();
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;

  Future<bool> initializeFrontCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras detected on this device');
        return false;
      }

      CameraDescription selectedCam = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        selectedCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await _controller?.dispose();
    } catch (e) {
      debugPrint('Camera dispose error: $e');
    } finally {
      _controller = null;
      _isInitialized = false;
    }
  }
}
