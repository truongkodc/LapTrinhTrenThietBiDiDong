import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/exercise.dart';

// =============================================
// API SERVICE - Giao tiếp mạng REST API (Bài 6 P1)
// =============================================
// Sử dụng package http để gọi REST API,
// chuyển đổi dữ liệu JSON từ server thành Model.

class ApiService {
  // Base URL của API (JSONPlaceholder - mock REST API)
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  // Danh sách bài tập gợi ý thực tế (map từ API response)
  static final List<Map<String, dynamic>> _exerciseTemplates = [
    {
      'title': 'Hít đất (Push-ups)',
      'category': 'Tăng cơ',
      'sets': 3,
      'reps': 15,
      'calories': 120,
      'dayOfWeek': 'Thứ 2 - Thứ 5',
      'imagePath': 'assets/images/tang_co.jpg',
    },
    {
      'title': 'Nhảy dây (Jump Rope)',
      'category': 'Cardio',
      'sets': 1,
      'reps': 100,
      'calories': 200,
      'dayOfWeek': 'Mỗi ngày',
      'imagePath': 'assets/images/cardio.jpg',
    },
    {
      'title': 'Squat không tạ (Bodyweight Squat)',
      'category': 'Thể lực',
      'sets': 4,
      'reps': 20,
      'calories': 150,
      'dayOfWeek': 'Thứ 3 - Thứ 6',
      'imagePath': 'assets/images/the_luc.jpg',
    },
    {
      'title': 'Kéo xà đơn (Pull-ups)',
      'category': 'Tăng cơ',
      'sets': 3,
      'reps': 8,
      'calories': 100,
      'dayOfWeek': 'Thứ 2 - Thứ 5',
      'imagePath': 'assets/images/tang_co.jpg',
    },
    {
      'title': 'Chạy bộ ngoài trời (Jogging)',
      'category': 'Cardio',
      'sets': 1,
      'reps': 30,
      'calories': 350,
      'dayOfWeek': 'Thứ 4 - Thứ 7',
      'imagePath': 'assets/images/cardio.jpg',
    },
    {
      'title': 'Plank nghiêng (Side Plank)',
      'category': 'Thể lực',
      'sets': 3,
      'reps': 45,
      'calories': 80,
      'dayOfWeek': 'Mỗi ngày',
      'imagePath': 'assets/images/the_luc.jpg',
    },
    {
      'title': 'Tập vai với tạ đơn (Dumbbell Shoulder Press)',
      'category': 'Tăng cơ',
      'sets': 4,
      'reps': 10,
      'calories': 130,
      'dayOfWeek': 'Thứ 3 - Thứ 6',
      'imagePath': 'assets/images/tang_co.jpg',
    },
    {
      'title': 'Burpees',
      'category': 'Cardio',
      'sets': 3,
      'reps': 12,
      'calories': 250,
      'dayOfWeek': 'Thứ 2 - Thứ 5',
      'imagePath': 'assets/images/cardio.jpg',
    },
    {
      'title': 'Gập bụng (Crunches)',
      'category': 'Thể lực',
      'sets': 3,
      'reps': 25,
      'calories': 70,
      'dayOfWeek': 'Mỗi ngày',
      'imagePath': 'assets/images/the_luc.jpg',
    },
    {
      'title': 'Deadlift (Nâng tạ)',
      'category': 'Tăng cơ',
      'sets': 4,
      'reps': 8,
      'calories': 200,
      'dayOfWeek': 'Thứ 4 - Thứ 7',
      'imagePath': 'assets/images/tang_co.jpg',
    },
  ];

  /// Lấy danh sách bài tập gợi ý từ API (Bài 6 P1 - HTTP GET)
  ///
  /// Gọi REST API GET từ JSONPlaceholder, sau đó kết hợp dữ liệu
  /// trả về với danh sách bài tập thực tế để tạo gợi ý.
  static Future<List<Exercise>> fetchExerciseSuggestions() async {
    try {
      // Gọi HTTP GET request đến API (Bài 6 P1)
      final response = await http.get(
        Uri.parse('$_baseUrl/posts?_limit=10'),
        headers: {'Content-Type': 'application/json'},
      );

      // Kiểm tra status code
      if (response.statusCode == 200) {
        // Parse JSON response (Bài 6 P1 - jsonDecode)
        final List<dynamic> postsData = jsonDecode(response.body);

        // Chuyển đổi dữ liệu API thành danh sách Exercise
        return postsData.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> post = entry.value;
          final template =
              _exerciseTemplates[index % _exerciseTemplates.length];

          return Exercise(
            id: 'api_${post['id']}',
            title: template['title'],
            category: template['category'],
            sets: template['sets'],
            reps: template['reps'],
            calories: template['calories'],
            dayOfWeek: template['dayOfWeek'],
            notes: post['body'] ?? 'Thực hiện đúng kỹ thuật, hít thở đều.',
            imagePath: template['imagePath'],
          );
        }).toList();
      } else {
        throw Exception('Lỗi kết nối server: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Error: $e');
      rethrow;
    }
  }

  /// Demo HTTP POST - Gửi dữ liệu bài tập lên server (Bài 6 P1)
  static Future<bool> postExercise(Exercise exercise) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'title': exercise.title,
          'body': exercise.notes,
          'userId': 1,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('POST Error: $e');
      return false;
    }
  }
}
