// lib/math_quiz_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class MathQuizPage extends StatefulWidget {
  const MathQuizPage({Key? key}) : super(key: key);

  @override
  _MathQuizPageState createState() => _MathQuizPageState();
}

class _MathQuizPageState extends State<MathQuizPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "";
  final FlutterTts flutterTts = FlutterTts();

  // Example simple math question in Sinhala:
  final String question = "මෙම ගණනය කරන්න: 3 + 4 = ?";
  // Options in Sinhala (you can customize these labels)
  final List<String> options = ["6", "7", "8", "9"];
  // Correct answer: option 2 (i.e. "7")
  final int correctOptionIndex = 1;

  String feedback = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();
    // Removed flutterTts.setAwaitSpeakCompletion(true);
    // Speak the quiz (question and options) after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakQuiz();
    });
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
  }

  Future<void> _speak(String text) async {
    final completer = Completer<void>();

    // Set the completion handler to complete the completer when speaking is finished.
    flutterTts.setCompletionHandler(() {
      completer.complete();
    });

    await flutterTts.setLanguage("si-LK");
    await flutterTts.setSpeechRate(0.3);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);

    // Wait for the speaking to complete.
    await completer.future;
  }

  Future<void> _speakQuiz() async {
    // Speak the question
    await _speak(question);
    // Delay to allow the question to be fully spoken
    await Future.delayed(const Duration(seconds: 1));
    // Speak each option with a small delay
    for (int i = 0; i < options.length; i++) {
      await _speak("පිළිතුර ${i + 1}: ${options[i]}");
      await Future.delayed(const Duration(seconds: 1));
    }
    // Prompt the user to answer
    await _speak("කරුණාකර පිළිතුර කියන්න, උදාහරණයට, 'පිළිතුර 1'");
  }

  void _listenForAnswer() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
        _recognizedText = "";
      });
      _speech.listen(
        onResult: (result) {
          print(
              "Recognized: ${result.recognizedWords} (final: ${result.finalResult})");
          if (result.finalResult) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _isListening = false;
            });
            _processAnswer(_recognizedText);
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

  void _processAnswer(String answerText) {
    int? selectedOption;

    // Check for Arabic numerals or Sinhala words
    if (answerText.contains("1") || answerText.contains("එක")) {
      selectedOption = 0;
    } else if (answerText.contains("2") || answerText.contains("දෙක")) {
      selectedOption = 1;
    } else if (answerText.contains("3") || answerText.contains("තුන")) {
      selectedOption = 2;
    } else if (answerText.contains("4") || answerText.contains("හතර")) {
      selectedOption = 3;
    }

    print("Processing answer: $answerText");
    _speak("ඔබ කිව්වා: $answerText");

    if (selectedOption != null) {
      if (selectedOption == correctOptionIndex) {
        feedback = "නිවැරදයි!"; // Correct!
        _speak("පිළිතුර නිවැරදියි!");
      } else {
        feedback = "වැරදි. නිවැරදි පිළිතුර ${options[correctOptionIndex]} වේ.";
        _speak("වැරදි. නිවැරදි පිළිතුර ${options[correctOptionIndex]} වේ.");
      }
    } else {
      feedback = "කරුණාකර 1, 2, 3, හෝ 4 ලෙස පිළිතුර කියන්න.";
      _speak("කරුණාකර 1, 2, 3, හෝ 4 ලෙස පිළිතුර කියන්න.");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Simple Math Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Display the options as text for visual reference
            ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Text("පිළිතුර ${index + 1}",
                      style: const TextStyle(fontSize: 18)),
                  title: Text(options[index],
                      style: const TextStyle(fontSize: 18)),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _listenForAnswer,
              child: Text(_isListening ? "හඬ නවතා දමන්න" : "පිළිතුර කියන්න"),
            ),
            const SizedBox(height: 20),
            if (_recognizedText.isNotEmpty)
              Text("ඇතුළත් කළ පිළිතුර: $_recognizedText",
                  style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (feedback.isNotEmpty)
              Text(feedback,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
