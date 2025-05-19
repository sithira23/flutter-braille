// lib/dynamic_math_quiz_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

// Define a model for a quiz question.
class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });
}

class DynamicMathQuizPage extends StatefulWidget {
  const DynamicMathQuizPage({Key? key}) : super(key: key);

  @override
  _DynamicMathQuizPageState createState() => _DynamicMathQuizPageState();
}

class _DynamicMathQuizPageState extends State<DynamicMathQuizPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "";
  final FlutterTts flutterTts = FlutterTts();

  // Dynamic list of quiz questions.
  final List<QuizQuestion> questions = [
    QuizQuestion(
      questionText: "මෙම ගණනය කරන්න: 3 + 4 = ?",
      options: ["6", "7", "8", "9"],
      correctOptionIndex: 1,
    ),
    QuizQuestion(
      questionText: "මෙම ගණනය කරන්න: 5 - 2 = ?",
      options: ["2", "3", "4", "5"],
      correctOptionIndex: 1,
    ),
    // Add more questions here
  ];

  int currentQuestionIndex = 0;
  String feedback = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();
    // Speak the current quiz question after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentQuestion();
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
    flutterTts.setCompletionHandler(() {
      completer.complete();
    });
    await flutterTts.setLanguage("si-LK");
    await flutterTts.setSpeechRate(0.3);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
    await completer.future;
  }

  Future<void> _speakCurrentQuestion() async {
    final currentQuestion = questions[currentQuestionIndex];
    // Speak the question.
    await _speak(currentQuestion.questionText);
    await Future.delayed(const Duration(seconds: 1));
    // Speak each option.
    for (int i = 0; i < currentQuestion.options.length; i++) {
      await _speak("පිළිතුර ${i + 1}: ${currentQuestion.options[i]}");
      await Future.delayed(const Duration(seconds: 1));
    }
    // Prompt for an answer.
    await _speak("කරුණාකර පිළිතුර කියන්න, උදාහරණයට, 'පිළිතුර 2'");
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

  void _processAnswer(String answerText) async {
    int? selectedOption;
    // Check for Arabic numerals or Sinhala words.
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
    await _speak("ඔබ කිව්වා: $answerText");

    final currentQuestion = questions[currentQuestionIndex];

    if (selectedOption != null) {
      if (selectedOption == currentQuestion.correctOptionIndex) {
        feedback = "නිවැරදයි!"; // Correct!
        await _speak("පිළිතුර නිවැරදියි!");
      } else {
        feedback =
            "වැරදි. නිවැරදි පිළිතුර ${currentQuestion.options[currentQuestion.correctOptionIndex]} වේ.";
        await _speak(
            "වැරදි. නිවැරදි පිළිතුර ${currentQuestion.options[currentQuestion.correctOptionIndex]} වේ.");
      }
    } else {
      feedback = "කරුණාකර 1, 2, 3, හෝ 4 ලෙස පිළිතුර කියන්න.";
      await _speak("කරුණාකර 1, 2, 3, හෝ 4 ලෙස පිළිතුර කියන්න.");
    }
    setState(() {});

    // After processing, move to the next question if available.
    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;
      feedback = ""; // Clear feedback for the new question.
      _recognizedText = "";
      // Speak the next question after a short delay.
      await Future.delayed(const Duration(seconds: 2));
      _speakCurrentQuestion();
    } else {
      await _speak("Quiz finished. Thank you!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];
    return Scaffold(
      appBar: AppBar(title: const Text("Dynamic Math Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              currentQuestion.questionText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Display the options as text for visual reference.
            ListView.builder(
              shrinkWrap: true,
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Text("පිළිතුර ${index + 1}",
                      style: const TextStyle(fontSize: 18)),
                  title: Text(currentQuestion.options[index],
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
