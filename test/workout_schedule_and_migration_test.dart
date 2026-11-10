import 'dart:async';
import 'dart:convert';

import 'package:fitplan_hutech/helpers/date_utils_helper.dart';
import 'package:fitplan_hutech/models/exercise.dart';
import 'package:fitplan_hutech/providers/workout_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adapter lưu trữ phục vụ kiểm thử: hỗ trợ giả lập lỗi lưu và độ trễ bất đồng bộ
class ControllableStorageAdapter extends SharedPreferencesStorageAdapter {
  bool failNextSetString = false;
  String? failOnKey;
  Completer<void>? delayNextSetStringCompleter;

  @override
  Future<bool> setString(String key, String value) async {
    if (delayNextSetStringCompleter != null &&
        (failOnKey == null || failOnKey == key)) {
      final completer = delayNextSetStringCompleter!;
      delayNextSetStringCompleter = null;
      await completer.future;
    }
    if (failNextSetString && (failOnKey == null || failOnKey == key)) {
      failNextSetString = false;
      return false;
    }
    return super.setString(key, value);
  }
}

void main() {
  group('DateUtilsHelper & SchedulePeriod validation', () {
    test(
      'Xử lý khóa ngày địa phương yyyy-MM-dd và từ chối ngày không hợp lệ',
      () {
        // Giờ địa phương lúc 01:30 sáng (nếu đổi sang UTC-7 sẽ bị lùi ngày, nhưng local phải giữ nguyên)
        final earlyMorningLocal = DateTime(2026, 11, 10, 1, 30);
        expect(DateUtilsHelper.toDateKey(earlyMorningLocal), '2026-11-10');
        expect(
          DateUtilsHelper.formatDisplayDate(earlyMorningLocal),
          '10/11/2026',
        );

        expect(DateUtilsHelper.isValidDateKey('2026-11-10'), isTrue);
        expect(DateUtilsHelper.isValidDateKey('2026-02-29'), isFalse);
        expect(DateUtilsHelper.isValidDateKey('2026-13-01'), isFalse);
        expect(DateUtilsHelper.isValidDateKey('10/11/2026'), isFalse);

        expect(DateUtilsHelper.addDaysToKey('2026-11-01', -1), '2026-10-31');
        expect(DateUtilsHelper.addDaysToKey('2026-11-30', 1), '2026-12-01');
      },
    );

    test('Chặn các giai đoạn lịch chồng lấn hoặc khoảng ngày không hợp lệ', () {
      expect(
        () => SchedulePeriod(
          scheduleType: ScheduleTypes.weekly,
          repeatDays: const [1, 4],
          startDate: '2026-11-01',
          effectiveFrom: '2026-11-10',
          effectiveTo: '2026-11-05', // effectiveFrom > effectiveTo
        ),
        throwsFormatException,
      );

      final p1 = SchedulePeriod(
        scheduleType: ScheduleTypes.weekly,
        repeatDays: const [1, 4],
        startDate: '2026-11-01',
        effectiveFrom: '2026-11-01',
        effectiveTo: '2026-11-08',
      );
      final p2Overlapping = SchedulePeriod(
        scheduleType: ScheduleTypes.weekly,
        repeatDays: const [2, 5],
        startDate: '2026-11-05',
        effectiveFrom: '2026-11-08', // Chồng lấn ngày 2026-11-08
        effectiveTo: '2026-11-12',
      );

      expect(
        () => Exercise(
          id: 'ex1',
          title: 'Squat',
          category: 'Tăng cơ',
          sets: 3,
          reps: 10,
          calories: 100,
          dayOfWeek: 'T2, T5',
          scheduleType: ScheduleTypes.weekly,
          repeatDays: const [1, 4],
          startDate: '2026-11-13',
          effectiveFrom: '2026-11-13',
          scheduleHistory: [p1, p2Overlapping],
        ),
        throwsFormatException,
      );
    });
  });

  group('Migration dữ liệu cũ (exercises_v2) và bảo toàn backup', () {
    test('Sao lưu nguyên bản exercises_v2, cố định migrationDate qua lần thử lại, ánh xạ đúng nhãn lịch và giữ nhãn lạ', () async {
      final legacyRaw = jsonEncode([
        {
          'id': 'ex_today',
          'title': 'Bài Hôm nay',
          'category': 'Tăng cơ',
          'sets': 3,
          'reps': 10,
          'calories': 120,
          'dayOfWeek': 'Hôm nay',
          'notes': 'Ghi chú 1',
          'createdAt': '2025-01-01T00:00:00.000',
          'isCompleted': true,
        },
        {
          'id': 'ex_daily',
          'title': 'Bài Mỗi ngày',
          'category': 'Thể lực',
          'sets': 3,
          'reps': 60,
          'calories': 90,
          'dayOfWeek': 'Mỗi ngày',
          'notes': 'Ghi chú 2',
          'isCompleted': false,
        },
        {
          'id': 'ex_pair',
          'title': 'Bài T2 - T5',
          'category': 'Cardio',
          'sets': 4,
          'reps': 12,
          'calories': 200,
          'dayOfWeek': 'Thứ 2 - Thứ 5',
          'notes': 'Ghi chú 3',
          'isCompleted': false,
        },
        {
          'id': 'ex_custom',
          'title': 'Bài Nhãn Lạ',
          'category': 'Cardio',
          'sets': 2,
          'reps': 15,
          'calories': 150,
          'dayOfWeek': 'Cuối tuần tùy hứng',
          'notes': 'Ghi chú 4',
          'isCompleted': false,
        },
      ]);

      SharedPreferences.setMockInitialValues({
        WorkoutProvider.legacyExercisesKey: legacyRaw,
        WorkoutProvider.legacyBackupKey: 'EXISTING_BACKUP_DO_NOT_OVERWRITE',
      });

      DateTime currentNow = DateTime(2026, 11, 10, 8, 0); // Thứ 3
      final storage = ControllableStorageAdapter();

      // Lần 1: Giả lập lỗi khi lưu Store v3 -> migrationDate vẫn phải được khóa ở 2026-11-10
      storage.failNextSetString = true;
      storage.failOnKey = WorkoutProvider.storeKeyV3;

      final provider = WorkoutProvider(
        clock: () => currentNow,
        storage: storage,
      );
      final firstLoadOk = await provider.loadData();
      expect(firstLoadOk, isFalse);
      expect(provider.hasLoadError, isTrue);

      // Kiểm tra backup cũ không bị ghi đè
      expect(
        await storage.getString(WorkoutProvider.legacyBackupKey),
        'EXISTING_BACKUP_DO_NOT_OVERWRITE',
      );

      // Sang ngày hôm sau (2026-11-11), người dùng nhấn Thử lại (loadData)
      currentNow = DateTime(2026, 11, 11, 9, 0);
      final retryOk = await provider.loadData();
      expect(retryOk, isTrue);
      expect(provider.hasLoadError, isFalse);

      // migrationDate phải cố định ở 2026-11-10 chứ không bị nhảy sang 2026-11-11
      expect(provider.migrationDate, '2026-11-10');
      expect(provider.exercises.length, 4);

      // 1. Nhãn "Hôm nay" -> lịch 1 lần vào migrationDate (2026-11-10), không dùng createdAt (2025-01-01)
      final exToday = provider.exercises[0];
      expect(exToday.id, 'ex_today');
      expect(exToday.scheduleType, ScheduleTypes.once);
      expect(exToday.scheduledDate, '2026-11-10');
      expect(exToday.legacyCompletedWithoutDate, isTrue);
      expect(exToday.isScheduledOnDateKey('2026-11-10'), isTrue);
      expect(exToday.isScheduledOnDateKey('2026-11-11'), isFalse);
      expect(exToday.isScheduledOnDateKey('2025-01-01'), isFalse);

      // Không tự tạo bản ghi hoàn thành từ isCompleted cũ
      expect(provider.completions, isEmpty);

      // 2. Nhãn "Mỗi ngày" -> lặp đủ 7 thứ, bắt đầu từ migrationDate (2026-11-10), không tạo lịch quá khứ
      final exDaily = provider.exercises[1];
      expect(exDaily.scheduleType, ScheduleTypes.weekly);
      expect(exDaily.repeatDays, [1, 2, 3, 4, 5, 6, 7]);
      expect(exDaily.startDate, '2026-11-10');
      expect(exDaily.isScheduledOnDateKey('2026-11-09'), isFalse);
      expect(exDaily.isScheduledOnDateKey('2026-11-10'), isTrue);

      // 3. Nhãn "Thứ 2 - Thứ 5" -> repeatDays [1, 4] từ 2026-11-10
      final exPair = provider.exercises[2];
      expect(exPair.scheduleType, ScheduleTypes.weekly);
      expect(exPair.repeatDays, [1, 4]);
      expect(
        exPair.isScheduledOnDateKey('2026-11-09'),
        isFalse,
      ); // Trước migrationDate
      expect(exPair.isScheduledOnDateKey('2026-11-12'), isTrue); // Thứ 5

      // 4. Nhãn không nhận diện được -> giữ nhãn gốc, đánh dấu cần chọn lại lịch, không tự đặt mỗi ngày
      final exCustom = provider.exercises[3];
      expect(exCustom.dayOfWeek, 'Cuối tuần tùy hứng');
      expect(exCustom.scheduleType, ScheduleTypes.unrecognized);
      expect(exCustom.needsScheduleReview, isTrue);
      expect(exCustom.isScheduledOnDateKey('2026-11-10'), isFalse);
      expect(
        provider.exercisesNeedingScheduleReview.map((e) => e.id),
        contains('ex_custom'),
      );

      // Chạy lại loadData lần nữa không nhân đôi bài tập
      await provider.loadData();
      expect(provider.exercises.length, 4);
    });

    test('Phát hiện dữ liệu Store v3 bị hỏng, chặn ghi đè và không nạp dữ liệu mẫu', () async {
      SharedPreferences.setMockInitialValues({
        WorkoutProvider.storeKeyV3:
            '{"schemaVersion": 3, "exercises": "corrupted"}',
      });

      final provider = WorkoutProvider(
        clock: () => DateTime(2026, 11, 10, 10, 0),
      );
      final ok = await provider.loadData();

      expect(ok, isFalse);
      expect(provider.hasLoadError, isTrue);
      expect(provider.exercises, isEmpty);

      // Thao tác thêm bài tập phải bị chặn để không ghi đè dữ liệu hỏng
      final addOk = await provider.addExercise(
        Exercise(
          id: 'new_1',
          title: 'Push up',
          category: 'Tăng cơ',
          sets: 3,
          reps: 15,
          calories: 100,
          dayOfWeek: 'Mỗi ngày',
          startDate: '2026-11-10',
        ),
      );
      expect(addOk, isFalse);
    });
  });

  group('Hàng đợi lưu tuần tự, lỗi lưu và thao tác đổi ngày khi đang lưu', () {
    test('Một thao tác lưu thất bại không làm mất trạng thái đã lưu trước đó và không làm đứt hàng đợi', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = ControllableStorageAdapter();
      final provider = WorkoutProvider(
        clock: () => DateTime(2026, 11, 10, 10, 0),
        storage: storage,
      );
      await provider.loadData();
      final initialCount = provider.exercises.length;

      // Thao tác 1: Thêm bài tập thành công
      final ok1 = await provider.addExercise(
        Exercise(
          id: 'ex_added_1',
          title: 'Bài thêm 1',
          category: 'Tăng cơ',
          sets: 3,
          reps: 10,
          calories: 110,
          dayOfWeek: 'Mỗi ngày',
          scheduleType: ScheduleTypes.weekly,
          repeatDays: const [1, 2, 3, 4, 5, 6, 7],
          startDate: '2026-11-10',
        ),
      );
      expect(ok1, isTrue);
      expect(provider.exercises.length, initialCount + 1);

      // Thao tác 2: Giả lập lỗi lưu -> bộ nhớ không được cập nhật bẩn
      storage.failNextSetString = true;
      storage.failOnKey = WorkoutProvider.storeKeyV3;
      final ok2 = await provider.addExercise(
        Exercise(
          id: 'ex_failed_2',
          title: 'Bài lỗi 2',
          category: 'Cardio',
          sets: 3,
          reps: 10,
          calories: 150,
          dayOfWeek: 'Mỗi ngày',
          scheduleType: ScheduleTypes.weekly,
          repeatDays: const [1, 2, 3, 4, 5, 6, 7],
          startDate: '2026-11-10',
        ),
      );
      expect(ok2, isFalse);
      expect(provider.exercises.length, initialCount + 1);
      expect(provider.exercises.any((e) => e.id == 'ex_failed_2'), isFalse);

      // Thao tác 3: Ngay sau lỗi, hàng đợi vẫn hoạt động bình thường
      final ok3 = await provider.toggleComplete('ex_added_1');
      expect(ok3, isTrue);
      expect(provider.isExerciseCompletedOn('ex_added_1'), isTrue);
    });

    test('Chụp lại ngày khi đưa vào hàng đợi: đổi selectedDate trong lúc chờ lưu không làm lưu nhầm ngày', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = ControllableStorageAdapter();
      final provider = WorkoutProvider(
        clock: () => DateTime(2026, 11, 10, 10, 0), // Thứ 3 (2026-11-10)
        storage: storage,
      );
      await provider.loadData();

      // Bài tập '4' (Plank) lặp mỗi ngày từ 2026-11-10.
      // Giả sử hôm nay là 2026-11-12, bài tập có lịch ở cả 2026-11-10 và 2026-11-11.
      final laterProvider = WorkoutProvider(
        clock: () => DateTime(2026, 11, 12, 10, 0),
        storage: storage,
      );
      await laterProvider.loadData();

      // Chọn ngày 2026-11-10
      laterProvider.selectDate(DateTime(2026, 11, 10));
      expect(laterProvider.selectedDateKey, '2026-11-10');

      final saveDelay = Completer<void>();
      storage.delayNextSetStringCompleter = saveDelay;
      storage.failOnKey = WorkoutProvider.storeKeyV3;

      // Bấm hoàn thành bài '4' khi đang ở ngày 2026-11-10 (lệnh lưu đang chờ)
      final futureComplete = laterProvider.toggleComplete('4');

      // Ngay lập tức người dùng chuyển sang ngày 2026-11-11 trước khi lệnh lưu hoàn tất
      laterProvider.selectDate(DateTime(2026, 11, 11));
      expect(laterProvider.selectedDateKey, '2026-11-11');

      // Cho phép lệnh lưu hoàn tất
      saveDelay.complete();
      final ok = await futureComplete;
      expect(ok, isTrue);

      // Bản ghi hoàn thành phải nằm ở 2026-11-10, KHÔNG nằm ở 2026-11-11
      expect(
        laterProvider.isExerciseCompletedOn('4', dateKey: '2026-11-10'),
        isTrue,
      );
      expect(
        laterProvider.isExerciseCompletedOn('4', dateKey: '2026-11-11'),
        isFalse,
      );
    });
  });

  group('Lịch tập, hoàn thành độc lập, chặn tương lai, sửa/xóa/hoàn tác và snapshot', () {
    test('Hoàn thành độc lập theo ngày, chặn ngày tương lai, không ghi đè snapshot khi gọi hoàn thành lại, phân biệt dateKey và completedAt', () async {
      SharedPreferences.setMockInitialValues({});
      DateTime fakeNow = DateTime(2026, 11, 12, 15, 45); // Thứ 5
      final provider = WorkoutProvider(clock: () => fakeNow);
      await provider.loadData();

      // Thêm 1 bài tập lặp mỗi ngày bắt đầu từ 2026-11-09
      await provider.addExercise(
        Exercise(
          id: 'ex_test',
          title: 'Hít đất chuẩn',
          category: 'Tăng cơ',
          sets: 3,
          reps: 15,
          calories: 120,
          dayOfWeek: 'Mỗi ngày',
          scheduleType: ScheduleTypes.weekly,
          repeatDays: const [1, 2, 3, 4, 5, 6, 7],
          startDate: '2026-11-09',
          effectiveFrom: '2026-11-09',
        ),
      );

      // 1. Chọn ngày quá khứ 2026-11-10 và đánh dấu hoàn thành lúc 2026-11-12T15:45
      provider.selectDate(DateTime(2026, 11, 10));
      final okPast = await provider.markExerciseCompleted('ex_test');
      expect(okPast, isTrue);

      final compRecord = provider.completionForExerciseOn(
        'ex_test',
        dateKey: '2026-11-10',
      );
      expect(compRecord, isNotNull);
      expect(compRecord!.dateKey, '2026-11-10');
      expect(compRecord.completedAt, fakeNow.toIso8601String());
      expect(compRecord.caloriesSnapshot, 120);

      // 2. Ngày hôm nay (2026-11-12) vẫn chưa hoàn thành
      provider.selectDate(DateTime(2026, 11, 12));
      expect(provider.isExerciseCompletedOn('ex_test'), isFalse);

      // 3. Chặn hoàn thành ngày tương lai (2026-11-13)
      provider.selectDate(DateTime(2026, 11, 13));
      final okFuture = await provider.markExerciseCompleted('ex_test');
      expect(okFuture, isFalse);
      expect(provider.isExerciseCompletedOn('ex_test'), isFalse);

      // 4. Sửa bài tập (đổi tên và tăng calo lên 250) vào hôm nay (2026-11-12)
      final currentEx = provider.exercises.firstWhere((e) => e.id == 'ex_test');
      await provider.updateExercise(
        currentEx.copyWith(title: 'Hít đất nâng cao', calories: 250),
      );

      // Gọi lại markExerciseCompleted trên ngày 2026-11-10 (đã hoàn thành trước đó)
      // -> Không được ghi đè snapshot cũ (vẫn giữ tên 'Hít đất chuẩn' và 120 kcal)
      fakeNow = DateTime(2026, 11, 12, 18, 0);
      await provider.markExerciseCompleted('ex_test', dateKey: '2026-11-10');
      final compAfterReMark = provider.completionForExerciseOn(
        'ex_test',
        dateKey: '2026-11-10',
      );
      expect(compAfterReMark!.titleSnapshot, 'Hít đất chuẩn');
      expect(compAfterReMark.caloriesSnapshot, 120);
      expect(
        provider.completions
            .where(
              (c) => c.exerciseId == 'ex_test' && c.dateKey == '2026-11-10',
            )
            .length,
        1,
      );
    });

    test('Sửa lịch nhiều lần trong cùng ngày, bài bắt đầu ở tương lai, bài 1 lần đã qua, xóa/ngừng lịch và hoàn tác đúng thứ tự', () async {
      SharedPreferences.setMockInitialValues({});
      DateTime fakeNow = DateTime(2026, 11, 2, 9, 0); // Thứ 2 (2026-11-02)
      final provider = WorkoutProvider(clock: () => fakeNow);
      await provider.loadData();

      // Tạo 1 bài lặp Thứ 2, Thứ 5 bắt đầu từ 2026-11-02 và 1 bài 1 lần vào 2026-11-04
      final weeklyEx = Exercise(
        id: 'w_1',
        title: 'Bench Press',
        category: 'Tăng cơ',
        sets: 4,
        reps: 10,
        calories: 200,
        dayOfWeek: 'T2, T5',
        scheduleType: ScheduleTypes.weekly,
        repeatDays: const [DateTime.monday, DateTime.thursday],
        startDate: '2026-11-02',
        effectiveFrom: '2026-11-02',
      );
      final oncePastEx = Exercise(
        id: 'o_1',
        title: 'Chạy 5km',
        category: 'Cardio',
        sets: 1,
        reps: 1,
        calories: 300,
        dayOfWeek: 'Ngày 04/11/2026',
        scheduleType: ScheduleTypes.once,
        scheduledDate: '2026-11-04',
        startDate: '2026-11-04',
        effectiveFrom: '2026-11-04',
      );
      final futureOnlyEx = Exercise(
        id: 'f_1',
        title: 'Bài tương lai',
        category: 'Thể lực',
        sets: 3,
        reps: 12,
        calories: 100,
        dayOfWeek: 'Mỗi ngày',
        scheduleType: ScheduleTypes.weekly,
        repeatDays: const [1, 2, 3, 4, 5, 6, 7],
        startDate: '2026-11-20',
        effectiveFrom: '2026-11-20',
      );

      await provider.addExercise(futureOnlyEx);
      await provider.addExercise(oncePastEx);
      await provider.addExercise(weeklyEx);

      // Chuyển thời gian sang Thứ 3 tuần kế tiếp: 2026-11-10
      fakeNow = DateTime(2026, 11, 10, 10, 0);

      // Sửa lịch weeklyEx lần 1 trong ngày 2026-11-10: sang Thứ 3 (2)
      final w1Current = provider.exercises.firstWhere((e) => e.id == 'w_1');
      await provider.updateExercise(
        w1Current.copyWith(
          repeatDays: const [DateTime.tuesday],
          startDate: '2026-11-10',
        ),
      );

      // Sửa lịch weeklyEx lần 2 ngay trong cùng ngày 2026-11-10: sang Thứ 4 (3), Thứ 6 (5)
      final w1AfterFirstEdit = provider.exercises.firstWhere(
        (e) => e.id == 'w_1',
      );
      await provider.updateExercise(
        w1AfterFirstEdit.copyWith(
          repeatDays: const [DateTime.wednesday, DateTime.friday],
          startDate: '2026-11-10',
        ),
      );

      final w1AfterSecondEdit = provider.exercises.firstWhere(
        (e) => e.id == 'w_1',
      );
      // Chỉ có đúng 1 giai đoạn lịch sử [2026-11-02 .. 2026-11-09], không bị chồng lấn
      expect(w1AfterSecondEdit.scheduleHistory.length, 1);
      expect(
        w1AfterSecondEdit.scheduleHistory.first.effectiveFrom,
        '2026-11-02',
      );
      expect(w1AfterSecondEdit.scheduleHistory.first.effectiveTo, '2026-11-09');

      // Kiểm tra lịch quá khứ (< 2026-11-10) vẫn giữ nguyên Thứ 2 (2026-11-02) và Thứ 5 (2026-11-05)
      expect(w1AfterSecondEdit.isScheduledOnDateKey('2026-11-02'), isTrue);
      expect(w1AfterSecondEdit.isScheduledOnDateKey('2026-11-05'), isTrue);
      expect(w1AfterSecondEdit.isScheduledOnDateKey('2026-11-04'), isFalse);

      // Từ hôm nay (2026-11-10, Thứ 3) trở đi áp dụng lịch mới (Thứ 4, Thứ 6)
      expect(w1AfterSecondEdit.isScheduledOnDateKey('2026-11-10'), isFalse);
      expect(
        w1AfterSecondEdit.isScheduledOnDateKey('2026-11-11'),
        isTrue,
      ); // Thứ 4

      // Bài một lần đã qua (2026-11-04) khi sửa sang ngày mới 2026-11-15 vẫn giữ lịch cũ ở 2026-11-04
      final o1Current = provider.exercises.firstWhere((e) => e.id == 'o_1');
      await provider.updateExercise(
        o1Current.copyWith(
          scheduleType: ScheduleTypes.once,
          scheduledDate: '2026-11-15',
          startDate: '2026-11-15',
        ),
      );
      final o1Updated = provider.exercises.firstWhere((e) => e.id == 'o_1');
      expect(o1Updated.isScheduledOnDateKey('2026-11-04'), isTrue);
      expect(o1Updated.isScheduledOnDateKey('2026-11-15'), isTrue);

      // Bài chỉ bắt đầu ở tương lai (2026-11-20) khi sửa ở 2026-11-10 không tạo lịch sử quá khứ giả
      final f1Current = provider.exercises.firstWhere((e) => e.id == 'f_1');
      await provider.updateExercise(
        f1Current.copyWith(
          repeatDays: const [DateTime.monday],
          startDate: '2026-11-20',
        ),
      );
      final f1Updated = provider.exercises.firstWhere((e) => e.id == 'f_1');
      expect(f1Updated.scheduleHistory, isEmpty);
      expect(f1Updated.isScheduledOnDateKey('2026-11-09'), isFalse);

      // Đánh dấu hoàn thành bài '4' (Plank) vào hôm nay 2026-11-10 rồi xóa/ngừng bài '4'
      provider.selectDate(DateTime(2026, 11, 10));
      await provider.markExerciseCompleted('4', dateKey: '2026-11-10');
      expect(
        provider.isExerciseCompletedOn('4', dateKey: '2026-11-10'),
        isTrue,
      );

      final orderBeforeDelete = provider.exercises.map((e) => e.id).toList();
      final deleteOk = await provider.deleteExercise('4');
      expect(deleteOk, isTrue);

      // Sau khi xóa/ngừng:
      // - Ngày mai (2026-11-11) bài '4' không còn trong lịch
      final tomorrowItems = provider.itemsForDate(DateTime(2026, 11, 11));
      expect(tomorrowItems.any((i) => i.exerciseId == '4'), isFalse);

      // - Nhưng hôm nay (2026-11-10) kết quả đã hoàn thành của bài '4' vẫn được giữ nguyên và tính vào tiến độ (1/1, không đếm trùng)
      final todayItems = provider.itemsForDate(DateTime(2026, 11, 10));
      expect(todayItems.where((i) => i.exerciseId == '4').length, 1);
      expect(
        todayItems.firstWhere((i) => i.exerciseId == '4').isCompleted,
        isTrue,
      );

      // - Ngày quá khứ (2026-11-09) vẫn dựng lại được lịch của bài '4'
      final yesterdayItems = provider.itemsForDate(DateTime(2026, 11, 9));
      // Lưu ý: bài '4' mặc định bắt đầu từ ngày khởi tạo 2026-11-02 nên 2026-11-09 có lịch
      expect(yesterdayItems.any((i) => i.exerciseId == '4'), isTrue);

      // Hoàn tác xóa (Undo): khôi phục đúng lịch và thứ tự ban đầu, không nhân đôi bản ghi hoàn thành
      final restoreOk = await provider.restoreDeletedExercise('4');
      expect(restoreOk, isTrue);
      expect(provider.exercises.map((e) => e.id).toList(), orderBeforeDelete);
      expect(
        provider.completions
            .where((c) => c.exerciseId == '4' && c.dateKey == '2026-11-10')
            .length,
        1,
      );

      // Tắt/mở lại app (khởi tạo WorkoutProvider mới và gọi loadData) vẫn giữ nguyên lịch và kết quả hoàn thành
      final reloadedProvider = WorkoutProvider(clock: () => fakeNow);
      await reloadedProvider.loadData();
      expect(
        reloadedProvider.exercises.map((e) => e.id).toList(),
        orderBeforeDelete,
      );
      expect(
        reloadedProvider.isExerciseCompletedOn('4', dateKey: '2026-11-10'),
        isTrue,
      );
    });
  });
}
