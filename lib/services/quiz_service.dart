import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import 'auth_service.dart';

class QuizService {
  static Future<List<dynamic>> getQuizzesByChapter(int chapterId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Quiz/chapter/$chapterId'));
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getQuizDetails(int quizId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Quiz/$quizId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> submitQuiz(int quizId, List<Map<String, int>> answers) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Quiz/$quizId/submit'),
        headers: {
          'Authorization': 'Bearer ${user.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(answers),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }
}
