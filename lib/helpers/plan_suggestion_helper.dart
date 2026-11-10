import '../models/exercise.dart';
import 'date_utils_helper.dart';

// =========================================================
// BỘ QUY TẮC & DANH MỤC MẪU GỢI Ý KẾ HOẠCH CỐ ĐỊNH
// Thuần Dart, không dùng mạng/AI/package ngoài, kết quả tất định.
// =========================================================

class SuggestionGoals {
  static const String muscleGain = 'Tăng cơ';
  static const String cardio = 'Cardio';
  static const String generalFitness = 'Vận động tổng hợp';

  static const List<String> values = <String>[
    muscleGain,
    cardio,
    generalFitness,
  ];

  static bool isValidGoal(String? goal) {
    return goal != null && values.contains(goal);
  }

  static String descriptionForGoal(String goal) {
    switch (goal) {
      case muscleGain:
        return 'Tập trung các bài sức mạnh cơ bản cho ngực, chân và lưng.';
      case cardio:
        return 'Tăng cường nhịp tim và sức bền tim mạch với các bài vận động liên tục.';
      case generalFitness:
      default:
        return 'Kết hợp cân bằng giữa Tăng cơ, Cardio và Thể lực trọng tâm.';
    }
  }
}

/// Một bài tập mẫu cố định trong danh mục gợi ý
class SuggestedExerciseTemplate {
  final String code;
  final String goal;
  final String title;
  final String category; // 'Tăng cơ' | 'Cardio' | 'Thể lực'
  final int sets;
  final int reps;
  final String unit; // 'lần' | 'giây' | 'phút'
  final int calories;
  final String notes;

  const SuggestedExerciseTemplate({
    required this.code,
    required this.goal,
    required this.title,
    required this.category,
    required this.sets,
    required this.reps,
    required this.unit,
    required this.calories,
    required this.notes,
  });

  String get volumeLabel => ExerciseUnits.formatVolume(sets, reps, unit);

  /// Tạo đối tượng Exercise hợp lệ từ bài mẫu cho lịch lặp hằng tuần bắt đầu từ [startDateKey]
  Exercise toExercise({
    required String id,
    required List<int> repeatDays,
    required String startDateKey,
    String? createdAt,
  }) {
    final normalizedDays = PlanSuggestionHelper.normalizeWeekdays(repeatDays);
    final dayLabel = DateUtilsHelper.formatRepeatDays(normalizedDays);
    return Exercise(
      id: id,
      title: title,
      category: category,
      sets: sets,
      reps: reps,
      unit: unit,
      calories: calories,
      dayOfWeek: dayLabel,
      notes: notes,
      isCompleted: false,
      createdAt: createdAt,
      scheduleType: ScheduleTypes.weekly,
      repeatDays: normalizedDays,
      startDate: startDateKey,
      effectiveFrom: startDateKey,
      isStopped: false,
      needsScheduleReview: false,
      legacyCompletedWithoutDate: false,
      templateCode: code,
    );
  }
}

/// Bản xem trước kế hoạch gợi ý (chưa ghi vào bộ nhớ)
class PlanSuggestionPreview {
  final String goal;
  final List<int> repeatDays;
  final String startDateKey;
  final List<SuggestedExerciseTemplate> templates;

  PlanSuggestionPreview({
    required this.goal,
    required List<int> repeatDays,
    required this.startDateKey,
    required List<SuggestedExerciseTemplate> templates,
  }) : repeatDays = List.unmodifiable(
         PlanSuggestionHelper.normalizeWeekdays(repeatDays),
       ),
       templates = List.unmodifiable(templates);

  String get repeatDaysLabel => DateUtilsHelper.formatRepeatDays(repeatDays);

  String get formattedStartDate =>
      DateUtilsHelper.formatDisplayDateKey(startDateKey);
}

class PlanSuggestionHelper {
  static const String referenceNotice =
      'Kế hoạch mẫu để tham khảo; hãy điều chỉnh theo khả năng của bạn.';

  static const String scheduleRuleNotice =
      'Lịch lặp hằng tuần, bắt đầu từ hôm nay';

  // ---- Danh mục 3 bài mẫu cố định cho mục tiêu "Tăng cơ" ----
  static const List<SuggestedExerciseTemplate> _muscleGainTemplates = [
    SuggestedExerciseTemplate(
      code: 'tpl_muscle_bench_press',
      goal: SuggestionGoals.muscleGain,
      title: 'Đẩy ngực với tạ đòn (Bench Press)',
      category: 'Tăng cơ',
      sets: 4,
      reps: 10,
      unit: ExerciseUnits.reps,
      calories: 180,
      notes: 'Giữ chặt bả vai trên ghế, hạ tạ chạm ngực dưới rồi đẩy thẳng.',
    ),
    SuggestedExerciseTemplate(
      code: 'tpl_muscle_barbell_squat',
      goal: SuggestionGoals.muscleGain,
      title: 'Gánh tạ đòn (Barbell Squat)',
      category: 'Tăng cơ',
      sets: 4,
      reps: 12,
      unit: ExerciseUnits.reps,
      calories: 240,
      notes: 'Giữ lưng thẳng tự nhiên, mở gối theo hướng mũi chân.',
    ),
    SuggestedExerciseTemplate(
      code: 'tpl_muscle_lat_pulldown',
      goal: SuggestionGoals.muscleGain,
      title: 'Kéo xô với cáp (Lat Pulldown)',
      category: 'Tăng cơ',
      sets: 3,
      reps: 12,
      unit: ExerciseUnits.reps,
      calories: 150,
      notes:
          'Ngồi thẳng lưng, kéo thanh cầm về phía ngực trên và siết cơ lưng.',
    ),
  ];

  // ---- Danh mục 3 bài mẫu cố định cho mục tiêu "Cardio" ----
  static const List<SuggestedExerciseTemplate> _cardioTemplates = [
    SuggestedExerciseTemplate(
      code: 'tpl_cardio_hiit_treadmill',
      goal: SuggestionGoals.cardio,
      title: 'Chạy bộ biến tốc (HIIT Treadmill)',
      category: 'Cardio',
      sets: 1,
      reps: 20,
      unit: ExerciseUnits.minutes,
      calories: 300,
      notes: 'Chạy nước rút 30 giây, đi bộ chậm 60 giây lặp lại 20 phút.',
    ),
    SuggestedExerciseTemplate(
      code: 'tpl_cardio_jump_rope',
      goal: SuggestionGoals.cardio,
      title: 'Nhảy dây nhịp độ vừa',
      category: 'Cardio',
      sets: 3,
      reps: 60,
      unit: ExerciseUnits.seconds,
      calories: 160,
      notes: 'Tiếp đất nhẹ bằng mũi chân, giữ khuỷu tay sát thân người.',
    ),
    SuggestedExerciseTemplate(
      code: 'tpl_cardio_stationary_bike',
      goal: SuggestionGoals.cardio,
      title: 'Đạp xe tại chỗ tốc độ ổn định',
      category: 'Cardio',
      sets: 1,
      reps: 25,
      unit: ExerciseUnits.minutes,
      calories: 220,
      notes: 'Giữ nhịp đạp đều đặn, điều chỉnh mức cản phù hợp thể lực.',
    ),
  ];

  // ---- Danh mục 3 bài mẫu cố định cho mục tiêu "Vận động tổng hợp" ----
  static const List<SuggestedExerciseTemplate> _generalFitnessTemplates = [
    SuggestedExerciseTemplate(
      code: 'tpl_mixed_barbell_squat',
      goal: SuggestionGoals.generalFitness,
      title: 'Gánh tạ đòn (Barbell Squat)',
      category: 'Tăng cơ',
      sets: 3,
      reps: 12,
      unit: ExerciseUnits.reps,
      calories: 200,
      notes: 'Giữ lưng thẳng tự nhiên, mở gối theo hướng mũi chân.',
    ),
    SuggestedExerciseTemplate(
      code: 'tpl_mixed_hiit_treadmill',
      goal: SuggestionGoals.generalFitness,
      title: 'Chạy bộ biến tốc (HIIT Treadmill)',
      category: 'Cardio',
      sets: 1,
      reps: 15,
      unit: ExerciseUnits.minutes,
      calories: 220,
      notes: 'Chạy bước đều kết hợp đi bộ nhanh giúp tăng sức bền.',
    ),
    SuggestedExerciseTemplate(
      code: 'tpl_mixed_plank_core',
      goal: SuggestionGoals.generalFitness,
      title: 'Plank siết cơ bụng',
      category: 'Thể lực',
      sets: 3,
      reps: 60,
      unit: ExerciseUnits.seconds,
      calories: 90,
      notes: 'Giữ cơ thể tạo thành một đường thẳng từ đầu đến gót chân.',
    ),
  ];

  /// Chuẩn hóa danh sách thứ trong tuần (lọc hợp lệ 1..7, loại trùng, sắp xếp tăng dần)
  static List<int> normalizeWeekdays(Iterable<int> rawDays) {
    final valid = rawDays.where((d) => d >= 1 && d <= 7).toSet().toList()
      ..sort();
    return valid;
  }

  /// Trả về đúng 3 bài mẫu cố định theo mục tiêu (tất định, không ngẫu nhiên)
  static List<SuggestedExerciseTemplate> templatesForGoal(String goal) {
    switch (goal) {
      case SuggestionGoals.muscleGain:
        return List.unmodifiable(_muscleGainTemplates);
      case SuggestionGoals.cardio:
        return List.unmodifiable(_cardioTemplates);
      case SuggestionGoals.generalFitness:
        return List.unmodifiable(_generalFitnessTemplates);
      default:
        throw ArgumentError('Mục tiêu gợi ý không hợp lệ: $goal');
    }
  }

  /// Tạo bản xem trước kế hoạch gợi ý
  static PlanSuggestionPreview buildPreview({
    required String goal,
    required Iterable<int> repeatDays,
    required String startDateKey,
  }) {
    if (!SuggestionGoals.isValidGoal(goal)) {
      throw ArgumentError('Mục tiêu gợi ý không hợp lệ: $goal');
    }
    final normalizedDays = normalizeWeekdays(repeatDays);
    if (normalizedDays.isEmpty) {
      throw ArgumentError('Phải chọn ít nhất một thứ trong tuần.');
    }
    if (!DateUtilsHelper.isValidDateKey(startDateKey)) {
      throw ArgumentError('Ngày bắt đầu không hợp lệ: $startDateKey');
    }
    return PlanSuggestionPreview(
      goal: goal,
      repeatDays: normalizedDays,
      startDateKey: startDateKey,
      templates: templatesForGoal(goal),
    );
  }

  /// So sánh hai danh sách thứ lặp hằng tuần sau khi chuẩn hóa
  static bool isSameWeekdaySchedule(Iterable<int> daysA, Iterable<int> daysB) {
    final a = normalizeWeekdays(daysA);
    final b = normalizeWeekdays(daysB);
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Kiểm tra bài tập [existing] có phải là bài mẫu đang còn hiệu lực trùng mã mẫu và trùng lịch hay không.
  /// - Chỉ khớp khi [existing.templateCode] == [templateCode] (không gộp nhầm bài người dùng tự tạo).
  /// - Bài đã ngừng lịch ([existing.isStopped]) hoặc chưa nhận diện được lịch không chặn tạo lại.
  /// - Lịch khác thứ tập được phép thêm.
  static bool isDuplicateActiveTemplateExercise(
    Exercise existing, {
    required String templateCode,
    required Iterable<int> repeatDays,
  }) {
    if (existing.isStopped || existing.needsScheduleReview) {
      return false;
    }
    final existingCode = existing.templateCode?.trim();
    if (existingCode == null ||
        existingCode.isEmpty ||
        existingCode != templateCode.trim()) {
      return false;
    }
    if (existing.scheduleType != ScheduleTypes.weekly) {
      return false;
    }
    return isSameWeekdaySchedule(existing.repeatDays, repeatDays);
  }

  /// Tính ngày tập đầu tiên kể từ ngày địa phương [today] theo các thứ [repeatDays]
  static DateTime firstScheduledDateFromToday(
    DateTime today,
    Iterable<int> repeatDays,
  ) {
    final localToday = DateUtilsHelper.normalizeLocalDate(today);
    final normalizedDays = normalizeWeekdays(repeatDays);
    if (normalizedDays.isEmpty) return localToday;

    for (int offset = 0; offset < 7; offset++) {
      final candidate = DateTime(
        localToday.year,
        localToday.month,
        localToday.day + offset,
      );
      if (normalizedDays.contains(candidate.weekday)) {
        return candidate;
      }
    }
    return localToday;
  }
}
