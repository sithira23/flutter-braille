// lib/camera_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();

  /// Provides audio instructions, then captures an image from the camera.
  /// Returns the captured image file, or null if no image is captured.
  Future<File?> captureImageWithGuidance() async {
    // Set TTS language and speak the instructions
    await _flutterTts
        .setLanguage("si-LK"); // Change to "si-LK" for Sinhala if needed
    await _flutterTts.setSpeechRate(0.4); // Adjust rate as desired
    await _flutterTts.speak(
        "ඔබගේ දුරකථනය ස්ථාවරව තබාගෙන කැමරාව ඔබේ සටහනට යොමු කරන්න. ඔබ සූදානම් වූ විට, ග්‍රහණ බොත්තම ඔබන්න.");

    // Wait a few seconds to give the user time to listen to the instructions
    await Future.delayed(Duration(seconds: 5));

    // Capture the image using the camera
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    // Check if an image was captured
    if (pickedFile != null) {
      // Provide audio feedback and haptic feedback
      await _flutterTts
          .speak("රූපය ග්රහණය කර ඇත.පරිවර්තනය කිරීමට විධානය දෙන්න");
      HapticFeedback.lightImpact();
      return File(pickedFile.path);
    } else {
      // Inform the user if no image was captured
      await _flutterTts
          .speak("කිසිදු රූපයක් ග්‍රහණය කර නොමැත. කරුණාකර නැවත උත්සාහ කරන්න.");
      return null;
    }
  }
}
