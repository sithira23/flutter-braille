import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class CameraAlignmentScreen extends StatefulWidget {
  @override
  _CameraAlignmentScreenState createState() => _CameraAlignmentScreenState();
}

class _CameraAlignmentScreenState extends State<CameraAlignmentScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isDetecting = false;
  String _lastWords = "";
  late ObjectDetector _objectDetector;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initSpeech();
    _initObjectDetector();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGuidance();
    });
  }

  // Initialize speech recognizer
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) => print("Speech status: $status"),
      onError: (errorNotification) => print("Speech error: $errorNotification"),
    );
    if (!available) {
      print("Speech recognition not available");
    }
  }

  // Initialize object detector
  void _initObjectDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  // Initialize camera
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first; // Choose the first available camera
    _controller = CameraController(camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();

    // Start streaming images for real-time processing
    _controller.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _processCameraImage(image);
      }
    });

    setState(() {});
  }

  // Start initial voice guidance
  void _startGuidance() async {
    await _flutterTts.speak(
      "Welcome to the camera alignment screen. Please position the camera over the paper.",
    );
  }

  // Process camera image for object detection
  Future<void> _processCameraImage(CameraImage image) async {
    try {
      // Combine image planes into a single byte array.
      final Uint8List bytes = Uint8List(
        image.planes
            .fold(0, (int prev, Plane plane) => prev + plane.bytes.length),
      );
      int offset = 0;
      for (Plane plane in image.planes) {
        bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
        offset += plane.bytes.length;
      }

      final InputImage inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final List<DetectedObject> objects =
          await _objectDetector.processImage(inputImage);

      if (objects.isNotEmpty) {
        await _flutterTts.speak("Paper detected. Hold steady.");
      } else {
        await _flutterTts.speak("No paper detected. Move closer or adjust.");
      }
    } catch (e) {
      print("Error processing image: $e");
    } finally {
      _isDetecting = false;
    }
  }

  // Start listening for voice commands
  void _startListening() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords.toLowerCase();
          });
          if (result.finalResult) {
            _processVoiceCommand(_lastWords);
          }
        },
        localeId: "en-US",
      );
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
    }
  }

  // Process voice commands
  void _processVoiceCommand(String command) async {
    if (command.contains("capture") || command.contains("take photo")) {
      await _flutterTts.speak("Capturing image");
      await _captureImage();
    }
  }

  // Capture image
  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture; // Ensure camera is initialized
      final XFile imageFile = await _controller.takePicture();
      await _flutterTts.speak("Image captured successfully");
      print("Image saved at: ${imageFile.path}");
    } catch (e) {
      print("Error capturing image: $e");
      await _flutterTts.speak("Failed to capture image. Please try again.");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera Alignment')),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: () => !_isListening ? _startListening() : null,
                    child: Text(
                        _isListening ? "Stop Listening" : "Start Listening"),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
