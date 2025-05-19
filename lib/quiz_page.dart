// lib/quiz_page.dart
import 'package:flutter/material.dart';
import 'package:braille_app/quiz_model.dart' as quiz_model;
import 'package:braille_app/quiz_service.dart' as quiz_service;
import 'package:braille_app/generated_quiz_page.dart'; // If you want to navigate

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  quiz_model.Quiz? quiz;
  bool isLoading = false;

  Future<void> _generateQuiz() async {
    setState(() {
      isLoading = true;
    });
    final quizResult =
        await quiz_service.generateQuiz(topic: "general", numQuestions: 5);
    if (quizResult != null) {
      setState(() {
        quiz = quizResult;
        isLoading = false;
      });
      print("Quiz received: ${quiz!.title}");
      print("Questions: ${quiz!.questions.map((q) => q.question).toList()}");
      // Optionally, navigate to a dedicated page:
      // Navigator.push(context, MaterialPageRoute(builder: (context) => GeneratedQuizPage(quiz: quiz!)));
    } else {
      setState(() {
        isLoading = false;
      });
      print("No quiz received");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dynamic Quiz")),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _generateQuiz,
                  child: const Text("Generate Quiz"),
                ),
                const SizedBox(height: 20),
                if (isLoading) const CircularProgressIndicator(),
                if (quiz != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz!.title,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...quiz!.questions.map((q) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.question,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                ...q.options.entries.map((entry) => Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        "${entry.key}: ${entry.value}",
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    )),
                                const Divider(),
                              ],
                            ),
                          )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
