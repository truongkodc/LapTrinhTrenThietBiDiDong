import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

// ==================================================
// 2. STATE MANAGEMENT VỚI PROVIDER (BÀI 7)
// ==================================================
class WorkoutProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userEmail = '';
  double _weight = 68.0;
  double _height = 172.0;
  List<Exercise> _exercises = [];

  bool get isLoggedIn => _isLoggedIn;
  String get userEmail => _userEmail;
  double get weight => _weight;
  double get height => _height;
  List<Exercise> get exercises => _exercises;

  double get bmi => _weight / ((_height / 100) * (_height / 100));

  int get completedCount => _exercises.where((e) => e.isCompleted).length;
  int get totalCaloriesBurned => _exercises
      .where((e) => e.isCompleted)
      .fold(0, (sum, item) => sum + item.calories);
  double get progressPercentage =>
      _exercises.isEmpty ? 0.0 : completedCount / _exercises.length;

  List<Exercise> _defaultExercises() => [
    Exercise(
      id: '1',
      title: 'Đẩy ngực với tạ đòn (Bench Press)',
      category: 'Tăng cơ',
      sets: 4,
      reps: 10,
      calories: 180,
      dayOfWeek: 'Thứ 2 - Thứ 5',
      notes: 'Giữ chặt bả vai trên ghế, hạ tạ chạm ngực dưới rồi đẩy thẳng.',
      isCompleted: true,
    ),
    Exercise(
      id: '2',
      title: 'Gánh tạ đòn (Barbell Squat)',
      category: 'Tăng cơ',
      sets: 4,
      reps: 12,
      calories: 240,
      dayOfWeek: 'Thứ 3 - Thứ 6',
      notes: 'Giữ lưng thẳng tự nhiên, mở gối theo hướng mũi chân.',
      isCompleted: false,
    ),
    Exercise(
      id: '3',
      title: 'Chạy bộ biến tốc (HIIT Treadmill)',
      category: 'Cardio',
      sets: 1,
      reps: 20,
      calories: 300,
      dayOfWeek: 'Thứ 4 - Thứ 7',
      notes: 'Chạy nước rút 30 giây, đi bộ chậm 60 giây lặp lại 20 phút.',
      isCompleted: false,
    ),
    Exercise(
      id: '4',
      title: 'Plank siết cơ bụng',
      category: 'Thể lực',
      sets: 3,
      reps: 60,
      calories: 90,
      dayOfWeek: 'Mỗi ngày',
      notes: 'Giữ cơ thể tạo thành một đường thẳng từ đầu đến gót chân.',
      isCompleted: true,
    ),
  ];

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userEmail = prefs.getString('userEmail') ?? 'nhom.doan@hutech.edu.vn';
    _weight = prefs.getDouble('weight') ?? 68.0;
    _height = prefs.getDouble('height') ?? 172.0;

    final String? storedList = prefs.getString('exercises_v2');
    if (storedList != null) {
      final List<dynamic> decoded = jsonDecode(storedList);
      _exercises = decoded
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      _exercises = _defaultExercises();
      await _saveExercises();
    }
    notifyListeners();
  }

  Future<void> _saveExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _exercises.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('exercises_v2', encoded);
  }

  Future<void> login(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = true;
    _userEmail = email;
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    await prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  // CREATE: Thêm bài tập mới
  Future<void> addExercise(Exercise exercise) async {
    _exercises.insert(0, exercise);
    await _saveExercises();
    notifyListeners();
  }

  // UPDATE: Cập nhật thông tin bài tập
  Future<void> updateExercise(Exercise updated) async {
    final index = _exercises.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _exercises[index] = updated;
      await _saveExercises();
      notifyListeners();
    }
  }

  // UPDATE STATUS: Đổi trạng thái hoàn thành
  Future<void> toggleComplete(String id) async {
    final index = _exercises.indexWhere((e) => e.id == id);
    if (index != -1) {
      _exercises[index].isCompleted = !_exercises[index].isCompleted;
      await _saveExercises();
      notifyListeners();
    }
  }

  // DELETE: Xóa bài tập
  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    await _saveExercises();
    notifyListeners();
  }

  Future<void> updateBodyMetrics(double newWeight, double newHeight) async {
    final prefs = await SharedPreferences.getInstance();
    _weight = newWeight;
    _height = newHeight;
    await prefs.setDouble('weight', newWeight);
    await prefs.setDouble('height', newHeight);
    notifyListeners();
  }
}
