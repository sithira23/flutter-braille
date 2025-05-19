// lib/generated_quiz_page.dart
import 'package:flutter/material.dart';
import 'quiz_model.dart';

class GeneratedQuizPage extends StatelessWidget {
  final Quiz quiz;

  const GeneratedQuizPage({Key? key, required this.quiz}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generated Quiz")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...quiz.questions.map((q) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.question, // Display question
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
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
        ),
      ),
    );
  }
}
