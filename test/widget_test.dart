import 'dart:convert';

import 'package:fitplan_hutech/app.dart';
import 'package:fitplan_hutech/models/exercise.dart';
import 'package:fitplan_hutech/providers/workout_provider.dart';
import 'package:fitplan_hutech/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test - hiển thị màn hình đăng nhập', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WorkoutProvider()..loadData(),
        child: const FitPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FitPlanApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('FITPLAN PRO'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });

  test('Đọc JSON bài tập cấu trúc cũ (không có imagePath và createdAt) giữ nguyên dữ liệu và thứ tự', () async {
    final singleOldExercise = Exercise.fromJson({
      'id': 'old_0',
      'title': 'Plank siết cơ bụng',
      'category': 'Thể lực',
      'sets': 3,
      'reps': 60,
      'calories': 90,
      'dayOfWeek': 'Mỗi ngày',
      'notes': 'Giữ cơ thể tạo thành một đường thẳng từ đầu đến gót chân.',
      'isCompleted': true,
    });
    expect(singleOldExercise.id, 'old_0');
    expect(singleOldExercise.imagePath, '');
    expect(singleOldExercise.createdAt, isNotEmpty);

    final legacyExercisesJson = jsonEncode([
      {
        'id': 'legacy_1',
        'title': 'Đẩy ngực với tạ đòn (Bench Press)',
        'category': 'Tăng cơ',
        'sets': 4,
        'reps': 10,
        'calories': 180,
        'dayOfWeek': 'Thứ 2 - Thứ 5',
        'notes':
            'Giữ chặt bả vai trên ghế, hạ tạ chạm ngực dưới rồi đẩy thẳng.',
        'isCompleted': true,
      },
      {
        'id': 'legacy_2',
        'title': 'Chạy bộ biến tốc (HIIT Treadmill)',
        'category': 'Cardio',
        'sets': 1,
        'reps': 20,
        'calories': 300,
        'dayOfWeek': 'Thứ 4 - Thứ 7',
        'notes': 'Chạy nước rút 30 giây, đi bộ chậm 60 giây lặp lại 20 phút.',
        'isCompleted': false,
      },
    ]);

    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'userEmail': 'sv.hutech@edu.vn',
      'weight': 70.5,
      'height': 175.0,
      'exercises_v2': legacyExercisesJson,
    });

    final provider = WorkoutProvider();
    await provider.loadData();

    expect(provider.isLoggedIn, isTrue);
    expect(provider.userEmail, 'sv.hutech@edu.vn');
    expect(provider.weight, 70.5);
    expect(provider.height, 175.0);
    expect(provider.exercises.length, 2);

    final first = provider.exercises[0];
    expect(first.id, 'legacy_1');
    expect(first.title, 'Đẩy ngực với tạ đòn (Bench Press)');
    expect(first.category, 'Tăng cơ');
    expect(first.sets, 4);
    expect(first.reps, 10);
    expect(first.calories, 180);
    expect(first.dayOfWeek, 'Thứ 2 - Thứ 5');
    expect(
      first.notes,
      'Giữ chặt bả vai trên ghế, hạ tạ chạm ngực dưới rồi đẩy thẳng.',
    );
    expect(first.isCompleted, isTrue);
    expect(first.imagePath, isEmpty);
    expect(first.createdAt, isNotEmpty);

    final second = provider.exercises[1];
    expect(second.id, 'legacy_2');
    expect(second.title, 'Chạy bộ biến tốc (HIIT Treadmill)');
    expect(second.category, 'Cardio');
    expect(second.sets, 1);
    expect(second.reps, 20);
    expect(second.calories, 300);
    expect(second.dayOfWeek, 'Thứ 4 - Thứ 7');
    expect(
      second.notes,
      'Chạy nước rút 30 giây, đi bộ chậm 60 giây lặp lại 20 phút.',
    );
    expect(second.isCompleted, isFalse);
    expect(second.imagePath, isEmpty);
    expect(second.createdAt, isNotEmpty);
  });
}
