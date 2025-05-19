// lib/dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'braille_predictor.dart';
import 'quiz_page.dart';
import 'maths_quiz_page.dart';
import 'camera_alignment_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late FlutterTts flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedCommand = '';

  // Common button style
  final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size(250, 60),
    textStyle: const TextStyle(fontSize: 18),
  );

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    // Set TTS language and voice properties for Sinhala.
    flutterTts.setLanguage("si-LK");
    flutterTts.setSpeechRate(0.4);
    flutterTts.setPitch(1.0);

    _speech = stt.SpeechToText();
    _initializeSpeech();

    // Delay the welcome alert until the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeAlert();
    });
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );
  }

  // Show an alert dialog with the welcome message and speak it.
  Future<void> _showWelcomeAlert() async {
    const welcomeMessage =
        "ආයුබෝවන්, බ්‍රේල් බඩ්ඩි වෙත පිළිගනිමු. ඩෑෂ්බෝඩ් හි ඇති විකල්ප: බ්‍රේල් පූර්වකථනය, විභාගය, සහ ගණිත විභාගය (සිංහල).";

    // Speak the welcome message.
    await flutterTts.speak(welcomeMessage);

    // Show the AlertDialog.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ආයුබෝවන්'),
          content: const Text(
            "බ්‍රේල් බඩ්ඩි වෙත පිළිගනිමු.\n\n"
            "ඩෑෂ්බෝඩ් හි විකල්ප:\n"
            "• බ්‍රේල් පූර්වකථනය\n"
            "• විභාගය\n"
            "• ගණිත විභාගය (සිංහල)",
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: const Text('හරි'),
            )
          ],
        );
      },
    );
  }

  // Listen for voice commands and process the recognized text.
  Future<void> _listenForVoiceCommands() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _recognizedCommand = ''; // Clear any previous command.
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
            _processVoiceCommand(command);
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

  // Process the recognized command and navigate to the corresponding page.
  void _processVoiceCommand(String command) {
    if (command.contains("මම කොහෙද")) {
      flutterTts.speak("ඔබ ඉන්නෙ ප්‍රදාන මෙනුව තුලයි.");
    } else if (command.contains("බ්‍රේල්") ||
        command.contains("predictor") ||
        command.contains("braille")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BraillePredictor()),
      );
    } else if (command.contains("විභාග") || command.contains("quiz")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizPage()),
      );
    } else if (command.contains("ගණිත") || command.contains("math")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MathQuizPage()),
      );
    } else {
      flutterTts.speak("නොදන්නා විධානයක්, කරුණාකර නැවත උත්සාහ කරන්න.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dashboard buttons for manual navigation.
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BraillePredictor()),
                  );
                },
                child: const Text("Braille Predictor"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizPage()),
                  );
                },
                child: const Text("Quiz"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MathQuizPage()),
                  );
                },
                child: const Text("Math Quiz (Sinhala)"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CameraAlignmentScreen()),
                  );
                },
                child: const Text("Camera Alignment"),
              ),
              const SizedBox(height: 20),
              // Button to trigger voice command listening.
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _listenForVoiceCommands();
                },
                child: Text(_isListening ? "Stop Listening" : "Voice Command"),
              ),
              const SizedBox(height: 20),
              // Display the recognized voice command.
              Text(
                _recognizedCommand,
                style: const TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
