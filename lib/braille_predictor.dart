// lib/braille_predictor.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'api_service.dart'; // Your API call function
import 'package:flutter_tts/flutter_tts.dart';
import 'camera_service.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class BraillePredictor extends StatefulWidget {
  // Removed the `const` keyword since this widget has mutable state.
  BraillePredictor({Key? key}) : super(key: key);

  @override
  _BraillePredictorState createState() => _BraillePredictorState();
}

class _BraillePredictorState extends State<BraillePredictor> {
  File? _image;
  String _result = '';
  String _recognizedCommand = '';
  final FlutterTts flutterTts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  final CameraService _cameraService = CameraService();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Common button style for uniform size
  final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size(250, 60),
    textStyle: const TextStyle(fontSize: 18),
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();
    _speakWelcomeMessage();
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );
  }

  Future<void> _speakWelcomeMessage() async {
    await flutterTts.setLanguage("si-LK");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(
        "බ්‍රේල් පරිවර්තන යෙදුමට සාදරයෙන් පිළිගනිමු...යෙදුම ක්‍රියාත්මක කිරීමට ඔබට ඔබේ හඬ භාවිතා කළ හැකිය.");
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("si-LK");
    await flutterTts.setSpeechRate(0.3);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  // Pick image from camera and crop it.
  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        debugPrint("Image picked: ${pickedFile.path}");
        try {
          final CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Image',
                toolbarColor: Colors.blue,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false,
              ),
              IOSUiSettings(title: 'Crop Image'),
            ],
          );
          if (croppedFile != null) {
            debugPrint("Image cropped: ${croppedFile.path}");
            setState(() {
              _image = File(croppedFile.path);
              _result = '';
            });
          } else {
            debugPrint("Cropping cancelled or failed");
          }
        } catch (cropError) {
          debugPrint("Error during cropping: $cropError");
          setState(() {
            _result = 'Cropping error: $cropError';
          });
        }
      } else {
        debugPrint("No image was picked");
      }
    } catch (pickError) {
      debugPrint("Error picking image: $pickError");
      setState(() {
        _result = 'Error picking image: $pickError';
      });
    }
  }

  // Capture image using guided method.
  Future<void> _captureImageWithGuidance() async {
    File? image = await _cameraService.captureImageWithGuidance();
    if (image != null) {
      setState(() {
        _image = image;
        _result = '';
      });
    }
  }

  // Upload image for prediction and speak out the result.
  Future<void> _uploadImage() async {
    if (_image == null) return;
    await _speak("පරිවර්තනය ආරම්භ වේ...මොහොතක් රන්දි සිටින්න");
    try {
      var prediction = await uploadImage(_image!);
      setState(() {
        _result = 'Predicted: ${prediction['predicted_name']}';
      });
      await _speak('Predicted translation is ${prediction['predicted_name']}');
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  // Pick image from gallery.
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = '';
      });
    }
  }

  // Listen for voice commands and display the recognized text.
  Future<void> _listenForVoiceCommands() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _recognizedCommand = ''; // Clear previous command.
      });
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            String command = val.recognizedWords.toLowerCase();
            print('Recognized command: $command');
            setState(() {
              _recognizedCommand = command;
              _isListening = false;
            });
            if (command.contains("කැමරාව විවෘත කරන්න")) {
              _captureImageWithGuidance();
            } else if (command.contains("රූපය කපන්න")) {
              _pickImageFromCamera();
            } else if (command.contains("ගැලරියෙන් තෝරන්න")) {
              _pickImageFromGallery();
            } else if (command.contains("පරිවර්තනය කරන්න")) {
              _uploadImage();
            } else if (command.contains("මම කොහෙද")) {
              _speak("ඔබ ඉන්නෙ බ්රේල් පරිවර්තකය තුලයි");
            } else if (command.contains("ප්‍රදාන මෙනුව") ||
                command.contains("ආපසු")) {
              Navigator.pop(context); // Navigate back to the previous screen
            } else {
              _speak("නොදන්නා විධානයක්, කරුණාකර නැවත උත්සාහ කරන්න..");
            }
          }
        },
        localeId: "si-LK",
      );
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Braille Predictor')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image != null
                  ? Image.file(_image!, width: 200, height: 200)
                  : Text('No image selected'),
              SizedBox(height: 20),
              Text(
                _recognizedCommand,
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
              SizedBox(height: 20),
              // Common sized buttons for various actions.
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _captureImageWithGuidance();
                },
                child: Text('Capture Image with Guidance'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _pickImageFromCamera();
                },
                child: Text('Capture & Crop Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _pickImageFromGallery();
                },
                child: Text('Pick Image from Gallery'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _uploadImage();
                },
                child: Text('Predict'),
              ),
              SizedBox(height: 40),
              // Voice command button moved lower and styled green.
              ElevatedButton(
                style: _buttonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(Colors.green),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _listenForVoiceCommands();
                },
                child: Text(_isListening ? 'Stop Listening' : 'Voice Command'),
              ),
              SizedBox(height: 20),
              Text(
                _result,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
