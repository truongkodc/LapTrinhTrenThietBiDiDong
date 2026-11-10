import 'dart:convert';

import 'package:fitplan_hutech/app.dart';
import 'package:fitplan_hutech/models/exercise.dart';
import 'package:fitplan_hutech/providers/workout_provider.dart';
import 'package:fitplan_hutech/screens/login_screen.dart';
import 'package:flutter/material.dart';
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
        create: (_) =>
            WorkoutProvider(clock: () => DateTime(2026, 11, 10, 9, 0))
              ..loadData(),
        child: const FitPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FitPlanApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('FITPLAN PRO'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });

  test('Đọc JSON bài tập cấu trúc cũ (không có imagePath và createdAt) giữ nguyên dữ liệu, thứ tự và quy tắc migration', () async {
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
    }, fallbackDateKey: '2026-11-10');
    expect(singleOldExercise.id, 'old_0');
    expect(singleOldExercise.imagePath, '');
    expect(singleOldExercise.createdAt, isNotEmpty);
    expect(singleOldExercise.legacyCompletedWithoutDate, isTrue);

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

    // Cố định ngày migration là Thứ 2 (2026-11-09)
    final provider = WorkoutProvider(clock: () => DateTime(2026, 11, 9, 8, 30));
    await provider.loadData();

    expect(provider.isLoggedIn, isTrue);
    expect(provider.userEmail, 'sv.hutech@edu.vn');
    expect(provider.weight, 70.5);
    expect(provider.height, 175.0);
    expect(provider.migrationDate, '2026-11-09');
    expect(provider.exercises.length, 2);

    final first = provider.exercises[0];
    expect(first.id, 'legacy_1');
    expect(first.title, 'Đẩy ngực với tạ đòn (Bench Press)');
    expect(first.category, 'Tăng cơ');
    expect(first.sets, 4);
    expect(first.reps, 10);
    expect(first.calories, 180);
    expect(
      first.notes,
      'Giữ chặt bả vai trên ghế, hạ tạ chạm ngực dưới rồi đẩy thẳng.',
    );
    // isCompleted cũ được bảo toàn vào legacyCompletedWithoutDate, không tự tạo lịch sử hoàn thành theo ngày
    expect(first.legacyCompletedWithoutDate, isTrue);
    expect(provider.completions, isEmpty);
    expect(first.repeatDays, [1, 4]);
    expect(first.startDate, '2026-11-09');

    final second = provider.exercises[1];
    expect(second.id, 'legacy_2');
    expect(second.title, 'Chạy bộ biến tốc (HIIT Treadmill)');
    expect(second.category, 'Cardio');
    expect(second.sets, 1);
    expect(second.reps, 20);
    expect(second.calories, 300);
    expect(
      second.notes,
      'Chạy nước rút 30 giây, đi bộ chậm 60 giây lặp lại 20 phút.',
    );
    expect(second.legacyCompletedWithoutDate, isFalse);
    expect(second.repeatDays, [3, 6]);
  });

  testWidgets(
    'Giao diện lịch theo ngày: chuyển ngày, ngày 0/0, hiển thị nhãn lạ & hoàn thành trước đây, đồng bộ tab BMI',
    (WidgetTester tester) async {
      final legacyExercisesJson = jsonEncode([
        {
          'id': 'ex_today_1',
          'title': 'Gập bụng cơ bản',
          'category': 'Thể lực',
          'sets': 3,
          'reps': 20,
          'calories': 100,
          'dayOfWeek': 'Hôm nay',
          'notes': 'Thở đều.',
          'isCompleted': true,
        },
        {
          'id': 'ex_unknown_1',
          'title': 'Bơi tự do',
          'category': 'Cardio',
          'sets': 1,
          'reps': 30,
          'calories': 250,
          'dayOfWeek': 'Khi nào rảnh',
          'notes': 'Khởi động kỹ.',
          'isCompleted': false,
        },
      ]);

      SharedPreferences.setMockInitialValues({
        'isLoggedIn': true,
        'userEmail': 'sv.hutech@edu.vn',
        'exercises_v2': legacyExercisesJson,
      });

      final provider = WorkoutProvider(
        clock: () => DateTime(2026, 11, 10, 9, 0), // Thứ 3, 10/11/2026
      );
      await provider.loadData();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const FitPlanApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Hiển thị ngày hôm nay (10/11/2026) và bài tập 'Hôm nay'
      expect(find.textContaining('10/11/2026'), findsWidgets);
      expect(find.text('Gập bụng cơ bản'), findsOneWidget);
      expect(find.text('✓ Đã hoàn thành trước đây'), findsOneWidget);
      expect(find.text('Tiến độ hoàn thành: 0/1 bài'), findsOneWidget);
      expect(find.text('🔥 0 kcal (ước tính)'), findsOneWidget);

      // Hiển thị khu vực cảnh báo bài tập có nhãn lịch cũ chưa nhận diện được
      expect(
        find.text('Bài tập có nhãn lịch cũ cần chọn lại lịch:'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Bơi tự do (Nhãn gốc: "Khi nào rảnh")'),
        findsOneWidget,
      );

      // Đánh dấu hoàn thành bài tập trong ngày hôm nay (10/11/2026)
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('Tiến độ hoàn thành: 1/1 bài'), findsOneWidget);
      expect(find.text('🔥 100 kcal (ước tính)'), findsOneWidget);

      // Chuyển sang Tab Thống kê & BMI để kiểm tra số liệu khớp với ngày đang chọn
      await tester.tap(find.text('Thống kê & BMI'));
      await tester.pumpAndSettle();

      expect(find.text('THỐNG KÊ NGÀY ĐANG CHỌN (10/11/2026)'), findsOneWidget);
      expect(find.text('Hoàn thành: 1/1 bài'), findsOneWidget);
      expect(find.text('🔥 100 kcal (ước tính)'), findsOneWidget);

      // Quay lại Tab Kế hoạch tập và chuyển sang ngày hôm sau (11/11/2026 - ngày không có bài tập)
      await tester.tap(find.text('Kế hoạch tập'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('next_day_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('11/11/2026'), findsWidgets);
      expect(find.text('Tiến độ hoàn thành: 0/0 bài'), findsOneWidget);
      expect(find.text('🔥 0 kcal (ước tính)'), findsOneWidget);
      expect(
        find.textContaining(
          'Chưa có bài tập nào trong mục này cho ngày 11/11/2026.',
        ),
        findsOneWidget,
      );

      // Bấm nút 'Hôm nay' để quay về ngày 10/11/2026
      await tester.tap(find.byKey(const Key('go_today_button')));
      await tester.pumpAndSettle();
      expect(find.text('Tiến độ hoàn thành: 1/1 bài'), findsOneWidget);
    },
  );

  testWidgets(
    'Hiển thị màn hình báo lỗi và nút Thử lại khi dữ liệu lưu trữ bị hỏng, chặn thêm bài tập',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'isLoggedIn': true,
        WorkoutProvider.storeKeyV3: '{invalid_json',
      });

      final provider = WorkoutProvider(
        clock: () => DateTime(2026, 11, 10, 9, 0),
      );
      await provider.loadData();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const FitPlanApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('retry_load_button')), findsOneWidget);
      // Không hiển thị nút Thêm bài tập khi dữ liệu chưa tải được để tránh ghi đè
      expect(find.text('Thêm bài tập'), findsNothing);
    },
  );

  testWidgets(
    'Biểu mẫu thêm bài tập: đổi nhãn theo đơn vị, chặn lưu khi dữ liệu không hợp lệ (giữ nguyên text đã nhập) và lưu thành công với calories = 0',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'isLoggedIn': true});
      final provider = WorkoutProvider(
        clock: () => DateTime(2026, 11, 10, 9, 0),
      );
      await provider.loadData();
      final initialCount = provider.exercises.length;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const FitPlanApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Mở hộp thoại Thêm bài tập
      await tester.tap(find.text('Thêm bài tập'));
      await tester.pumpAndSettle();

      expect(find.text('Số lần mỗi hiệp'), findsOneWidget);

      // Đổi đơn vị sang 'giây' -> nhãn đổi thành 'Số giây mỗi hiệp'
      await tester.tap(find.byKey(const Key('exercise_unit_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('giây').last);
      await tester.pumpAndSettle();

      expect(find.text('Số giây mỗi hiệp'), findsOneWidget);

      // Nhập dữ liệu không hợp lệ: tên rỗng, số hiệp = 0, số giây = -5, calo = -10
      await tester.enterText(
        find.byKey(const Key('exercise_title_field')),
        '   ',
      );
      await tester.enterText(find.byKey(const Key('exercise_sets_field')), '0');
      await tester.enterText(
        find.byKey(const Key('exercise_quantity_field')),
        '-5',
      );
      await tester.enterText(
        find.byKey(const Key('exercise_calories_field')),
        '-10',
      );

      await tester.tap(find.byKey(const Key('save_exercise_button')));
      await tester.pumpAndSettle();

      // Không được đóng dialog hay tự ý gán mặc định để lưu
      expect(find.text('Thêm bài tập mới'), findsOneWidget);
      expect(provider.exercises.length, initialCount);
      expect(find.text('Vui lòng nhập tên bài tập'), findsOneWidget);
      expect(
        find.text('Số hiệp phải là số nguyên dương (> 0)'),
        findsOneWidget,
      );
      expect(
        find.text('Số giây mỗi hiệp phải là số nguyên dương (> 0)'),
        findsOneWidget,
      );
      expect(find.text('Kcal phải là số nguyên từ 0 trở lên'), findsOneWidget);

      // Giữ nguyên dữ liệu người dùng vừa gõ để sửa lại
      expect(find.text('-5'), findsOneWidget);
      expect(find.text('-10'), findsOneWidget);

      // Sửa lại dữ liệu hợp lệ (calories = 0 được phép)
      await tester.enterText(
        find.byKey(const Key('exercise_title_field')),
        'Giãn cơ tĩnh',
      );
      await tester.enterText(find.byKey(const Key('exercise_sets_field')), '3');
      await tester.enterText(
        find.byKey(const Key('exercise_quantity_field')),
        '45',
      );
      await tester.enterText(
        find.byKey(const Key('exercise_calories_field')),
        '0',
      );

      await tester.tap(find.byKey(const Key('save_exercise_button')));
      await tester.pumpAndSettle();

      // Dialog đã đóng và bài tập mới hiển thị đúng định dạng '3 hiệp × 45 giây'
      expect(find.text('Thêm bài tập mới'), findsNothing);
      expect(provider.exercises.length, initialCount + 1);
      expect(find.text('Giãn cơ tĩnh'), findsOneWidget);
      expect(find.textContaining('3 hiệp × 45 giây'), findsOneWidget);

      // Mở màn hình chi tiết kiểm tra hiển thị khối lượng
      await tester.tap(find.text('Giãn cơ tĩnh'));
      await tester.pumpAndSettle();
      expect(find.text('🔁 Khối lượng: 3 hiệp × 45 giây'), findsOneWidget);
    },
  );

  testWidgets(
    'Tab Thống kê & BMI: cảnh báo khi dữ liệu lưu không hợp lệ, chặn nhập sai mà không tự đổi về 68/172, hỗ trợ dấu phẩy thập phân',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'isLoggedIn': true,
        'weight': 0.0,
        'height': -170.0,
      });
      final provider = WorkoutProvider(
        clock: () => DateTime(2026, 11, 10, 9, 0),
      );
      await provider.loadData();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const FitPlanApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thống kê & BMI'));
      await tester.pumpAndSettle();

      // Hiển thị thông báo yêu cầu cập nhật lại thay vì hiển thị BMI vô nghĩa
      expect(
        find.textContaining(
          'Dữ liệu cân nặng hoặc chiều cao đang lưu không hợp lệ',
        ),
        findsOneWidget,
      );

      // Nhập giá trị không hợp lệ (dấu phân tách hàng nghìn và số âm)
      await tester.enterText(
        find.byKey(const Key('weight_input_field')),
        '1,000.5',
      );
      await tester.enterText(
        find.byKey(const Key('height_input_field')),
        '-170',
      );

      await tester.tap(find.byKey(const Key('update_bmi_button')));
      await tester.pumpAndSettle();

      // Báo lỗi tiếng Việt dưới ô nhập, giữ nguyên text đã nhập và không tự đổi về 68/172
      expect(
        find.textContaining('Cân nặng phải là số hợp lệ > 0'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Chiều cao phải là số hợp lệ > 0'),
        findsOneWidget,
      );
      expect(find.text('1,000.5'), findsOneWidget);
      expect(find.text('-170'), findsOneWidget);
      expect(provider.hasValidBodyMetrics, isFalse);

      // Nhập số thập phân dùng dấu phẩy hợp lệ
      await tester.enterText(
        find.byKey(const Key('weight_input_field')),
        '67,5',
      );
      await tester.enterText(
        find.byKey(const Key('height_input_field')),
        '172,5',
      );

      await tester.tap(find.byKey(const Key('update_bmi_button')));
      await tester.pumpAndSettle();

      expect(provider.hasValidBodyMetrics, isTrue);
      expect(provider.weight, closeTo(67.5, 1e-6));
      expect(provider.height, closeTo(172.5, 1e-6));
      expect(find.text('22.7'), findsOneWidget);
      expect(find.text('Đã cập nhật chỉ số BMI!'), findsOneWidget);
    },
  );
}
