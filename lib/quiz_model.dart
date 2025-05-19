// lib/quiz_model.dart
import 'dart:convert';

class Quiz {
  final String title;
  final List<QuizQuestion> questions;

  Quiz({required this.title, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Extract the "quiz" key if it exists
    final rawData = json.containsKey("quiz") ? json["quiz"] : json;
    // If rawData is a String, decode it into a Map.
    final data = rawData is String ? jsonDecode(rawData) : rawData;

    List<dynamic> questionsJson = data["questions"] as List<dynamic>? ?? [];
    List<QuizQuestion> questionsList = questionsJson
        .map((q) {
          // Check if q is a Map; if not, print an error and skip it.
          if (q is Map<String, dynamic>) {
            return QuizQuestion.fromJson(q);
          } else {
            print("Warning: Skipping invalid question: $q");
            return null;
          }
        })
        .whereType<QuizQuestion>()
        .toList();

    return Quiz(
      title: data["title"] as String,
      questions: questionsList,
    );
  }
}

class QuizQuestion {
  final String question;
  final Map<String, String> options;
  final String answer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json["question"] as String,
      options: Map<String, String>.from(json["options"]),
      answer: json["answer"] as String,
    );
  }
}
