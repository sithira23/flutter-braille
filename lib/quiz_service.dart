// lib/quiz_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'quiz_model.dart';

Future<Quiz?> generateQuiz(
    {String topic = 'general', int numQuestions = 5}) async {
  final url =
      Uri.parse("https://5c39-112-134-162-211.ngrok-free.app/generate_quiz");
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "topic": topic,
        "numQuestions": numQuestions,
      }),
    );

    print("Response body: ${response.body}"); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      print("✅ API Response: $jsonResponse");
      // Check if the quiz data is wrapped in a "quiz" key:
      final data = jsonResponse.containsKey("quiz")
          ? jsonResponse["quiz"]
          : jsonResponse;
      return Quiz.fromJson(data);
    } else {
      print("❌ Quiz generation failed: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("❌ Error generating quiz: $e");
    return null;
  }
}
