import '../helpers/date_utils_helper.dart';

// =============================================
// MODEL BÀI TẬP & LỊCH TẬP (PHIÊN BẢN 3)
// Hỗ trợ đơn vị bài tập (lần, giây, phút), lịch 1 lần,
// lặp hằng tuần, lịch sử phiên bản lịch, tương thích ngược
// JSON cũ (exercises_v2), API và SQLite.
// =============================================

class ScheduleTypes {
  static const String once = 'once';
  static const String weekly = 'weekly';
  static const String unrecognized = 'unrecognized';
}

/// Các đơn vị bài tập được hỗ trợ
class ExerciseUnits {
  static const String reps = 'lần';
  static const String seconds = 'giây';
  static const String minutes = 'phút';

  static const String defaultUnit = reps;

  static const List<String> values = <String>[reps, seconds, minutes];

  static bool isValidUnit(String? unit) {
    return unit != null && values.contains(unit);
  }

  /// Nhãn ô nhập số lượng mỗi hiệp tương ứng với đơn vị đang chọn
  static String quantityInputLabel(String unit) {
    switch (unit) {
      case seconds:
        return 'Số giây mỗi hiệp';
      case minutes:
        return 'Số phút mỗi hiệp';
      case reps:
      default:
        return 'Số lần mỗi hiệp';
    }
  }

  /// Định dạng hiển thị nhất quán: "3 hiệp × 10 lần", "3 hiệp × 60 giây", "1 hiệp × 20 phút"
  static String formatVolume(int sets, int repsPerSet, String unit) {
    final safeUnit = isValidUnit(unit) ? unit : defaultUnit;
    return '$sets hiệp × $repsPerSet $safeUnit';
  }
}

/// Lưu một giai đoạn lịch trong quá khứ [effectiveFrom .. effectiveTo]
/// Đảm bảo effectiveFrom <= effectiveTo và không chồng lấn giữa các giai đoạn.
class SchedulePeriod {
  final String scheduleType; // 'once' | 'weekly'
  final String? scheduledDate; // yyyy-MM-dd (nếu scheduleType == 'once')
  final List<int> repeatDays; // 1..7 (nếu scheduleType == 'weekly')
  final String startDate; // yyyy-MM-dd
  final String effectiveFrom; // yyyy-MM-dd
  final String effectiveTo; // yyyy-MM-dd

  SchedulePeriod({
    required this.scheduleType,
    this.scheduledDate,
    List<int>? repeatDays,
    required this.startDate,
    required this.effectiveFrom,
    required this.effectiveTo,
  }) : repeatDays = List.unmodifiable(
         (repeatDays ?? const <int>[]).toSet().toList()..sort(),
       ) {
    if (!DateUtilsHelper.isValidDateKey(startDate) ||
        !DateUtilsHelper.isValidDateKey(effectiveFrom) ||
        !DateUtilsHelper.isValidDateKey(effectiveTo)) {
      throw const FormatException('Ngày trong SchedulePeriod không hợp lệ.');
    }
    if (effectiveFrom.compareTo(effectiveTo) > 0) {
      throw const FormatException(
        'Khoảng ngày trong SchedulePeriod không hợp lệ (effectiveFrom > effectiveTo).',
      );
    }
    if (scheduleType == ScheduleTypes.once) {
      if (!DateUtilsHelper.isValidDateKey(scheduledDate)) {
        throw const FormatException(
          'SchedulePeriod kiểu once thiếu scheduledDate hợp lệ.',
        );
      }
    } else if (scheduleType == ScheduleTypes.weekly) {
      if (this.repeatDays.isEmpty ||
          this.repeatDays.any((d) => d < 1 || d > 7)) {
        throw const FormatException(
          'SchedulePeriod kiểu weekly có repeatDays không hợp lệ.',
        );
      }
    } else {
      throw const FormatException('scheduleType trong SchedulePeriod sai.');
    }
  }

  bool matchesDate(DateTime localDate, String dateKey) {
    if (dateKey.compareTo(effectiveFrom) < 0 ||
        dateKey.compareTo(effectiveTo) > 0) {
      return false;
    }
    if (scheduleType == ScheduleTypes.once) {
      return scheduledDate == dateKey;
    }
    if (scheduleType == ScheduleTypes.weekly) {
      return dateKey.compareTo(startDate) >= 0 &&
          repeatDays.contains(localDate.weekday);
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'scheduleType': scheduleType,
    'scheduledDate': scheduledDate,
    'repeatDays': repeatDays,
    'startDate': startDate,
    'effectiveFrom': effectiveFrom,
    'effectiveTo': effectiveTo,
  };

  factory SchedulePeriod.fromJson(Map<String, dynamic> json) {
    final rawRepeat = json['repeatDays'];
    final List<int> parsedRepeat = [];
    if (rawRepeat is List) {
      for (final item in rawRepeat) {
        if (item is! int || item < 1 || item > 7) {
          throw const FormatException('repeatDays chứa giá trị không hợp lệ.');
        }
        parsedRepeat.add(item);
      }
    }
    return SchedulePeriod(
      scheduleType: json['scheduleType']?.toString() ?? '',
      scheduledDate: json['scheduledDate']?.toString(),
      repeatDays: parsedRepeat,
      startDate: json['startDate']?.toString() ?? '',
      effectiveFrom: json['effectiveFrom']?.toString() ?? '',
      effectiveTo: json['effectiveTo']?.toString() ?? '',
    );
  }
}

class Exercise {
  final String id;
  final String title;
  final String category; // 'Tăng cơ', 'Cardio', 'Thể lực'
  final int sets;
  final int reps; // Số lượng mỗi hiệp (lần, giây hoặc phút)
  final String unit; // 'lần' | 'giây' | 'phút'
  final int calories; // Kcal ước tính cho toàn bài tập
  final String dayOfWeek; // Nhãn lịch hiển thị hoặc nhãn gốc cũ
  final String notes;
  final String imagePath;
  final String createdAt;
  bool isCompleted;

  // ---- Thông tin lịch tập theo ngày (Store v3) ----
  final String scheduleType; // 'once' | 'weekly' | 'unrecognized'
  final String? scheduledDate; // yyyy-MM-dd khi scheduleType == 'once'
  final List<int> repeatDays; // 1..7 khi scheduleType == 'weekly'
  final String startDate; // yyyy-MM-dd
  final String effectiveFrom; // yyyy-MM-dd (mốc hiệu lực của quy tắc hiện tại)
  final String? endDate; // yyyy-MM-dd (nếu có giới hạn ngày kết thúc)
  final bool isStopped; // true nếu đã xóa/ngừng lịch từ hôm nay trở đi
  final bool needsScheduleReview; // true nếu nhãn lịch cũ không nhận diện được
  final bool legacyCompletedWithoutDate; // true nếu dữ liệu cũ có isCompleted
  final List<SchedulePeriod> scheduleHistory; // Các giai đoạn lịch trước đó

  Exercise({
    required this.id,
    required this.title,
    required this.category,
    required this.sets,
    required this.reps,
    this.unit = ExerciseUnits.defaultUnit,
    required this.calories,
    required this.dayOfWeek,
    this.notes = 'Khởi động kỹ 5 phút trước khi tập, hít thở đều.',
    this.imagePath = '',
    this.isCompleted = false,
    String? createdAt,
    String? scheduleType,
    this.scheduledDate,
    List<int>? repeatDays,
    String? startDate,
    String? effectiveFrom,
    this.endDate,
    this.isStopped = false,
    this.needsScheduleReview = false,
    this.legacyCompletedWithoutDate = false,
    List<SchedulePeriod>? scheduleHistory,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       scheduleType = scheduleType ?? ScheduleTypes.weekly,
       repeatDays = List.unmodifiable(
         (repeatDays ?? const <int>[1, 2, 3, 4, 5, 6, 7]).toSet().toList()
           ..sort(),
       ),
       startDate = startDate ?? DateUtilsHelper.toDateKey(DateTime.now()),
       effectiveFrom =
           effectiveFrom ??
           startDate ??
           scheduledDate ??
           DateUtilsHelper.toDateKey(DateTime.now()),
       scheduleHistory = List.unmodifiable(
         scheduleHistory ?? const <SchedulePeriod>[],
       ) {
    _validateExerciseFields(
      id: id,
      title: title,
      sets: sets,
      reps: reps,
      unit: unit,
      calories: calories,
    );
    _validateScheduleIntegrity(
      scheduleType: this.scheduleType,
      scheduledDate: scheduledDate,
      repeatDays: this.repeatDays,
      startDate: this.startDate,
      effectiveFrom: this.effectiveFrom,
      endDate: endDate,
      needsScheduleReview: needsScheduleReview,
      scheduleHistory: this.scheduleHistory,
    );
  }

  static void _validateExerciseFields({
    required String id,
    required String title,
    required int sets,
    required int reps,
    required String unit,
    required int calories,
  }) {
    if (id.trim().isEmpty) {
      throw const FormatException('ID bài tập không được để trống.');
    }
    if (title.trim().isEmpty) {
      throw const FormatException('Tên bài tập không được để trống.');
    }
    if (sets <= 0) {
      throw const FormatException('Số hiệp phải là số nguyên lớn hơn 0.');
    }
    if (reps <= 0) {
      throw const FormatException(
        'Số lượng mỗi hiệp phải là số nguyên lớn hơn 0.',
      );
    }
    if (!ExerciseUnits.isValidUnit(unit)) {
      throw FormatException('Đơn vị bài tập không hợp lệ: $unit');
    }
    if (calories < 0) {
      throw const FormatException(
        'Calo ước tính phải là số nguyên lớn hơn hoặc bằng 0.',
      );
    }
  }

  static void _validateScheduleIntegrity({
    required String scheduleType,
    required String? scheduledDate,
    required List<int> repeatDays,
    required String startDate,
    required String effectiveFrom,
    required String? endDate,
    required bool needsScheduleReview,
    required List<SchedulePeriod> scheduleHistory,
  }) {
    if (!DateUtilsHelper.isValidDateKey(startDate) ||
        !DateUtilsHelper.isValidDateKey(effectiveFrom)) {
      throw const FormatException('startDate hoặc effectiveFrom không hợp lệ.');
    }
    if (endDate != null) {
      if (!DateUtilsHelper.isValidDateKey(endDate) ||
          startDate.compareTo(endDate) > 0) {
        throw const FormatException(
          'endDate không hợp lệ hoặc nhỏ hơn startDate.',
        );
      }
    }
    if (scheduleType == ScheduleTypes.once) {
      if (!DateUtilsHelper.isValidDateKey(scheduledDate)) {
        throw const FormatException('Lịch một lần thiếu scheduledDate hợp lệ.');
      }
    } else if (scheduleType == ScheduleTypes.weekly) {
      if (!needsScheduleReview &&
          (repeatDays.isEmpty || repeatDays.any((d) => d < 1 || d > 7))) {
        throw const FormatException('Lịch lặp hằng tuần thiếu thứ hợp lệ.');
      }
    } else if (scheduleType != ScheduleTypes.unrecognized) {
      throw const FormatException('scheduleType không hợp lệ.');
    }

    // Kiểm tra các giai đoạn lịch sử không chồng lấn và đúng thứ tự
    for (int i = 0; i < scheduleHistory.length; i++) {
      final current = scheduleHistory[i];
      if (i > 0) {
        final prev = scheduleHistory[i - 1];
        if (prev.effectiveTo.compareTo(current.effectiveFrom) >= 0) {
          throw const FormatException(
            'Các giai đoạn trong scheduleHistory bị chồng lấn.',
          );
        }
      }
    }
  }

  /// Chuỗi hiển thị khối lượng tập nhất quán (vd: "3 hiệp × 10 lần", "3 hiệp × 60 giây")
  String get volumeLabel => ExerciseUnits.formatVolume(sets, reps, unit);

  /// Kiểm tra bài tập có được lên lịch vào ngày địa phương [date] hay không
  bool isScheduledOn(DateTime date) {
    final localDate = DateUtilsHelper.normalizeLocalDate(date);
    final dateKey = DateUtilsHelper.toDateKey(localDate);
    return isScheduledOnDateKey(dateKey, localDate: localDate);
  }

  /// Kiểm tra bài tập có được lên lịch vào khóa ngày [dateKey] ('yyyy-MM-dd')
  bool isScheduledOnDateKey(String dateKey, {DateTime? localDate}) {
    final dt = localDate ?? DateUtilsHelper.tryParseDateKey(dateKey);
    if (dt == null) return false;

    // 1. Nếu ngày nằm trong phạm vi của một giai đoạn lịch quá khứ
    for (final period in scheduleHistory) {
      if (dateKey.compareTo(period.effectiveFrom) >= 0 &&
          dateKey.compareTo(period.effectiveTo) <= 0) {
        return period.matchesDate(dt, dateKey);
      }
    }

    // 2. Nếu ngày thuộc phạm vi trước hiệu lực của quy tắc hiện tại
    // nhưng không nằm trong giai đoạn lịch sử nào -> không có lịch
    if (dateKey.compareTo(effectiveFrom) < 0) {
      return false;
    }

    // 3. Kiểm tra quy tắc lịch hiện tại
    if (isStopped ||
        needsScheduleReview ||
        scheduleType == ScheduleTypes.unrecognized) {
      return false;
    }
    if (endDate != null && dateKey.compareTo(endDate!) > 0) {
      return false;
    }

    if (scheduleType == ScheduleTypes.once) {
      return scheduledDate == dateKey;
    }
    if (scheduleType == ScheduleTypes.weekly) {
      return dateKey.compareTo(startDate) >= 0 &&
          repeatDays.contains(dt.weekday);
    }
    return false;
  }

  /// Chuỗi hiển thị lịch tập thân thiện trên giao diện
  String get scheduleLabel {
    if (needsScheduleReview || scheduleType == ScheduleTypes.unrecognized) {
      return '$dayOfWeek (Cần chọn lại lịch)';
    }
    if (scheduleType == ScheduleTypes.once && scheduledDate != null) {
      return 'Một lần: ${DateUtilsHelper.formatDisplayDateKey(scheduledDate!)}';
    }
    if (scheduleType == ScheduleTypes.weekly) {
      final daysText = DateUtilsHelper.formatRepeatDays(repeatDays);
      final startText = DateUtilsHelper.formatDisplayDateKey(startDate);
      if (endDate != null) {
        final endText = DateUtilsHelper.formatDisplayDateKey(endDate!);
        return '$daysText ($startText - $endText)';
      }
      return '$daysText (từ $startText)';
    }
    return dayOfWeek;
  }

  /// Tạo bản sao bài tập với lịch mới có hiệu lực từ [todayKey] trở đi,
  /// bảo toàn lịch đã lên kế hoạch ở các ngày trước (< todayKey).
  Exercise applyScheduleUpdate({
    required String newTitle,
    required String newCategory,
    required int newSets,
    required int newReps,
    String? newUnit,
    required int newCalories,
    required String newNotes,
    required String newScheduleType,
    String? newScheduledDate,
    List<int>? newRepeatDays,
    required String newStartDate,
    String? newEndDate,
    required String todayKey,
  }) {
    final yesterdayKey = DateUtilsHelper.addDaysToKey(todayKey, -1);
    final updatedHistory = _buildHistoryUpToYesterday(yesterdayKey);

    final String resolvedStartDate = newScheduleType == ScheduleTypes.once
        ? newScheduledDate!
        : newStartDate;
    final String resolvedEffectiveFrom =
        resolvedStartDate.compareTo(todayKey) > 0
        ? resolvedStartDate
        : todayKey;

    final String computedDayOfWeek = newScheduleType == ScheduleTypes.once
        ? 'Ngày ${DateUtilsHelper.formatDisplayDateKey(newScheduledDate!)}'
        : DateUtilsHelper.formatRepeatDays(newRepeatDays ?? const []);

    return Exercise(
      id: id,
      title: newTitle.trim(),
      category: newCategory,
      sets: newSets,
      reps: newReps,
      unit: newUnit ?? unit,
      calories: newCalories,
      dayOfWeek: computedDayOfWeek,
      notes: newNotes,
      imagePath: imagePath,
      isCompleted: false,
      createdAt: createdAt,
      scheduleType: newScheduleType,
      scheduledDate: newScheduleType == ScheduleTypes.once
          ? newScheduledDate
          : null,
      repeatDays: newScheduleType == ScheduleTypes.weekly
          ? (newRepeatDays ?? const [])
          : const [],
      startDate: resolvedStartDate,
      effectiveFrom: resolvedEffectiveFrom,
      endDate: newEndDate,
      isStopped: false,
      needsScheduleReview: false,
      legacyCompletedWithoutDate: legacyCompletedWithoutDate,
      scheduleHistory: updatedHistory,
    );
  }

  /// Ngừng lịch tập từ [todayKey] trở đi, giữ nguyên lịch sử các ngày trước (< todayKey)
  Exercise stopScheduleFromToday(String todayKey) {
    final yesterdayKey = DateUtilsHelper.addDaysToKey(todayKey, -1);
    final updatedHistory = _buildHistoryUpToYesterday(yesterdayKey);

    return copyWith(
      isStopped: true,
      effectiveFrom: todayKey,
      scheduleHistory: updatedHistory,
    );
  }

  List<SchedulePeriod> _buildHistoryUpToYesterday(String yesterdayKey) {
    final List<SchedulePeriod> result = scheduleHistory
        .where((p) => p.effectiveTo.compareTo(yesterdayKey) <= 0)
        .toList();

    if (!isStopped &&
        !needsScheduleReview &&
        (scheduleType == ScheduleTypes.once ||
            scheduleType == ScheduleTypes.weekly)) {
      final String ruleStart = scheduleType == ScheduleTypes.once
          ? (scheduledDate ?? startDate)
          : startDate;
      String candFrom = effectiveFrom.compareTo(ruleStart) >= 0
          ? effectiveFrom
          : ruleStart;
      if (result.isNotEmpty) {
        final dayAfterLast = DateUtilsHelper.addDaysToKey(
          result.last.effectiveTo,
          1,
        );
        if (dayAfterLast.compareTo(candFrom) > 0) {
          candFrom = dayAfterLast;
        }
      }

      String candTo = yesterdayKey;
      if (scheduleType == ScheduleTypes.once && scheduledDate != null) {
        if (scheduledDate!.compareTo(candTo) < 0) {
          candTo = scheduledDate!;
        }
      } else if (endDate != null && endDate!.compareTo(candTo) < 0) {
        candTo = endDate!;
      }

      if (candFrom.compareTo(candTo) <= 0) {
        result.add(
          SchedulePeriod(
            scheduleType: scheduleType,
            scheduledDate: scheduledDate,
            repeatDays: repeatDays,
            startDate: startDate,
            effectiveFrom: candFrom,
            effectiveTo: candTo,
          ),
        );
      }
    }
    return result;
  }

  /// Chuyển đổi một bản ghi bài tập từ JSON cũ (exercises_v2) sang Exercise v3
  /// với ngày cố định [migrationDate] ('yyyy-MM-dd').
  /// Mặc định đơn vị là 'lần' khi dữ liệu cũ chưa có trường unit (không suy đoán theo tên bài).
  factory Exercise.migrateFromLegacyJson(
    Map<String, dynamic> json, {
    required String migrationDate,
  }) {
    if (!DateUtilsHelper.isValidDateKey(migrationDate)) {
      throw const FormatException('migrationDate không hợp lệ.');
    }

    final rawId = json['id']?.toString().trim() ?? '';
    final rawTitle = json['title']?.toString().trim() ?? '';
    if (rawId.isEmpty || rawTitle.isEmpty) {
      throw const FormatException(
        'Dữ liệu bài tập cũ thiếu id hoặc title hợp lệ.',
      );
    }

    final rawSets = json['sets'] ?? 3;
    final rawReps = json['reps'] ?? 12;
    final rawCalories = json['calories'] ?? 100;
    if (rawSets is! int ||
        rawSets <= 0 ||
        rawReps is! int ||
        rawReps <= 0 ||
        rawCalories is! int ||
        rawCalories < 0) {
      throw const FormatException(
        'Dữ liệu bài tập cũ có thông số sets/reps/calories không hợp lệ.',
      );
    }

    final String parsedUnit = _parseOrDefaultUnit(json['unit']);

    final rawDayOfWeek = json['dayOfWeek']?.toString() ?? 'Hôm nay';
    final bool wasCompleted =
        json['isCompleted'] == true || json['isCompleted'] == 1;

    final parsedSchedule = _parseLegacyDayOfWeek(
      rawDayOfWeek,
      migrationDate: migrationDate,
    );

    return Exercise(
      id: rawId,
      title: rawTitle,
      category: json['category']?.toString() ?? 'Tăng cơ',
      sets: rawSets,
      reps: rawReps,
      unit: parsedUnit,
      calories: rawCalories,
      dayOfWeek: rawDayOfWeek,
      notes: json['notes']?.toString() ?? 'Khởi động kỹ 5 phút trước khi tập.',
      imagePath: json['imagePath']?.toString() ?? '',
      isCompleted: false,
      createdAt: json['createdAt']?.toString(),
      scheduleType: parsedSchedule.scheduleType,
      scheduledDate: parsedSchedule.scheduledDate,
      repeatDays: parsedSchedule.repeatDays,
      startDate: migrationDate,
      effectiveFrom: migrationDate,
      isStopped: false,
      needsScheduleReview: parsedSchedule.needsReview,
      legacyCompletedWithoutDate: wasCompleted,
      scheduleHistory: const [],
    );
  }

  static String _parseOrDefaultUnit(dynamic rawUnit) {
    if (rawUnit == null) return ExerciseUnits.defaultUnit;
    final unitStr = rawUnit.toString().trim();
    if (!ExerciseUnits.isValidUnit(unitStr)) {
      throw FormatException('Đơn vị bài tập trong JSON không hợp lệ: $rawUnit');
    }
    return unitStr;
  }

  static ({
    String scheduleType,
    String? scheduledDate,
    List<int> repeatDays,
    bool needsReview,
  })
  _parseLegacyDayOfWeek(String rawLabel, {required String migrationDate}) {
    final normalized = rawLabel
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();

    if (normalized == 'hôm nay') {
      return (
        scheduleType: ScheduleTypes.once,
        scheduledDate: migrationDate,
        repeatDays: const <int>[],
        needsReview: false,
      );
    }

    if (normalized == 'mỗi ngày' || normalized == 'hằng ngày') {
      return (
        scheduleType: ScheduleTypes.weekly,
        scheduledDate: null,
        repeatDays: const <int>[1, 2, 3, 4, 5, 6, 7],
        needsReview: false,
      );
    }

    // Kiểm tra danh sách các thứ phân tách bởi '-' hoặc ','
    final parts = normalized
        .split(RegExp(r'\s*[-,]\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.isNotEmpty) {
      final List<int> weekdays = [];
      bool allValid = true;
      for (final part in parts) {
        final day = _matchExactVietnameseWeekday(part);
        if (day == null) {
          allValid = false;
          break;
        }
        weekdays.add(day);
      }
      if (allValid && weekdays.isNotEmpty) {
        final uniqueSorted = weekdays.toSet().toList()..sort();
        return (
          scheduleType: ScheduleTypes.weekly,
          scheduledDate: null,
          repeatDays: uniqueSorted,
          needsReview: false,
        );
      }
    }

    // Nhãn không nhận diện được: giữ nguyên nhãn gốc, đánh dấu cần chọn lại lịch
    return (
      scheduleType: ScheduleTypes.unrecognized,
      scheduledDate: null,
      repeatDays: const <int>[],
      needsReview: true,
    );
  }

  static int? _matchExactVietnameseWeekday(String token) {
    switch (token) {
      case 'thứ 2':
      case 'thứ hai':
      case 't2':
        return DateTime.monday;
      case 'thứ 3':
      case 'thứ ba':
      case 't3':
        return DateTime.tuesday;
      case 'thứ 4':
      case 'thứ tư':
      case 't4':
        return DateTime.wednesday;
      case 'thứ 5':
      case 'thứ năm':
      case 't5':
        return DateTime.thursday;
      case 'thứ 6':
      case 'thứ sáu':
      case 't6':
        return DateTime.friday;
      case 'thứ 7':
      case 'thứ bảy':
      case 't7':
        return DateTime.saturday;
      case 'chủ nhật':
      case 'cn':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  // ---- JSON Serialization (Store v3 & tương thích ngược) ----

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'sets': sets,
    'reps': reps,
    'unit': unit,
    'calories': calories,
    'dayOfWeek': dayOfWeek,
    'notes': notes,
    'imagePath': imagePath,
    'isCompleted': isCompleted,
    'createdAt': createdAt,
    'scheduleType': scheduleType,
    'scheduledDate': scheduledDate,
    'repeatDays': repeatDays,
    'startDate': startDate,
    'effectiveFrom': effectiveFrom,
    'endDate': endDate,
    'isStopped': isStopped,
    'needsScheduleReview': needsScheduleReview,
    'legacyCompletedWithoutDate': legacyCompletedWithoutDate,
    'scheduleHistory': scheduleHistory.map((p) => p.toJson()).toList(),
  };

  /// Đọc Exercise từ JSON (hỗ trợ cả JSON Store v3 và JSON cũ thiếu trường unit)
  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    String? fallbackDateKey,
  }) {
    if (!json.containsKey('scheduleType')) {
      final dateKey =
          fallbackDateKey ?? DateUtilsHelper.toDateKey(DateTime.now());
      final migrated = Exercise.migrateFromLegacyJson(
        json,
        migrationDate: dateKey,
      );
      return migrated.copyWith(
        isCompleted: json['isCompleted'] == true || json['isCompleted'] == 1,
      );
    }

    final rawId = json['id']?.toString().trim() ?? '';
    final rawTitle = json['title']?.toString().trim() ?? '';
    if (rawId.isEmpty || rawTitle.isEmpty) {
      throw const FormatException('Exercise JSON thiếu id hoặc title.');
    }

    final sets = json['sets'];
    final reps = json['reps'];
    final calories = json['calories'];
    if (sets is! int ||
        sets <= 0 ||
        reps is! int ||
        reps <= 0 ||
        calories is! int ||
        calories < 0) {
      throw const FormatException(
        'Exercise JSON có thông số sets/reps/calories không hợp lệ.',
      );
    }

    final String parsedUnit = _parseOrDefaultUnit(json['unit']);

    final rawScheduleType = json['scheduleType']?.toString() ?? '';
    final rawStartDate = json['startDate']?.toString() ?? '';
    final rawEffectiveFrom = json['effectiveFrom']?.toString() ?? rawStartDate;
    final rawEndDate = json['endDate']?.toString();
    final rawScheduledDate = json['scheduledDate']?.toString();

    final rawRepeatDays = json['repeatDays'];
    final List<int> parsedRepeatDays = [];
    if (rawRepeatDays is List) {
      for (final d in rawRepeatDays) {
        if (d is! int || d < 1 || d > 7) {
          throw const FormatException(
            'repeatDays trong Exercise không hợp lệ.',
          );
        }
        parsedRepeatDays.add(d);
      }
    }

    final rawHistory = json['scheduleHistory'];
    final List<SchedulePeriod> parsedHistory = [];
    if (rawHistory != null) {
      if (rawHistory is! List) {
        throw const FormatException('scheduleHistory phải là danh sách.');
      }
      for (final item in rawHistory) {
        if (item is! Map) {
          throw const FormatException('Phần tử scheduleHistory không hợp lệ.');
        }
        parsedHistory.add(
          SchedulePeriod.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }

    return Exercise(
      id: rawId,
      title: rawTitle,
      category: json['category']?.toString() ?? 'Tăng cơ',
      sets: sets,
      reps: reps,
      unit: parsedUnit,
      calories: calories,
      dayOfWeek: json['dayOfWeek']?.toString() ?? 'Hôm nay',
      notes: json['notes']?.toString() ?? 'Khởi động kỹ 5 phút trước khi tập.',
      imagePath: json['imagePath']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true || json['isCompleted'] == 1,
      createdAt: json['createdAt']?.toString(),
      scheduleType: rawScheduleType,
      scheduledDate: rawScheduledDate,
      repeatDays: parsedRepeatDays,
      startDate: rawStartDate,
      effectiveFrom: rawEffectiveFrom,
      endDate: rawEndDate,
      isStopped: json['isStopped'] == true,
      needsScheduleReview: json['needsScheduleReview'] == true,
      legacyCompletedWithoutDate: json['legacyCompletedWithoutDate'] == true,
      scheduleHistory: parsedHistory,
    );
  }

  // ---- SQLite Serialization (Bài 6 P1 - sqflite) ----

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'sets': sets,
    'reps': reps,
    'calories': calories,
    'dayOfWeek': dayOfWeek,
    'notes': notes,
    'imagePath': imagePath,
    'isCompleted': isCompleted ? 1 : 0,
    'createdAt': createdAt,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id']?.toString() ?? '',
    title: map['title'] ?? '',
    category: map['category'] ?? 'Tăng cơ',
    sets: map['sets'] ?? 3,
    reps: map['reps'] ?? 12,
    unit: _parseOrDefaultUnit(map['unit']),
    calories: map['calories'] ?? 100,
    dayOfWeek: map['dayOfWeek'] ?? 'Hôm nay',
    notes: map['notes'] ?? 'Khởi động kỹ 5 phút trước khi tập.',
    imagePath: map['imagePath'] ?? '',
    isCompleted: map['isCompleted'] == 1,
    createdAt: map['createdAt'],
  );

  // ---- Copy with ----

  Exercise copyWith({
    String? id,
    String? title,
    String? category,
    int? sets,
    int? reps,
    String? unit,
    int? calories,
    String? dayOfWeek,
    String? notes,
    String? imagePath,
    bool? isCompleted,
    String? createdAt,
    String? scheduleType,
    String? scheduledDate,
    bool clearScheduledDate = false,
    List<int>? repeatDays,
    String? startDate,
    String? effectiveFrom,
    String? endDate,
    bool clearEndDate = false,
    bool? isStopped,
    bool? needsScheduleReview,
    bool? legacyCompletedWithoutDate,
    List<SchedulePeriod>? scheduleHistory,
  }) {
    return Exercise(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduledDate: clearScheduledDate
          ? null
          : (scheduledDate ?? this.scheduledDate),
      repeatDays: repeatDays ?? this.repeatDays,
      startDate: startDate ?? this.startDate,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isStopped: isStopped ?? this.isStopped,
      needsScheduleReview: needsScheduleReview ?? this.needsScheduleReview,
      legacyCompletedWithoutDate:
          legacyCompletedWithoutDate ?? this.legacyCompletedWithoutDate,
      scheduleHistory: scheduleHistory ?? this.scheduleHistory,
    );
  }

  /// Lấy đường dẫn ảnh mặc định theo category
  String get displayImage {
    if (imagePath.isNotEmpty) return imagePath;
    switch (category) {
      case 'Tăng cơ':
        return 'assets/images/tang_co.jpg';
      case 'Cardio':
        return 'assets/images/cardio.jpg';
      case 'Thể lực':
        return 'assets/images/the_luc.jpg';
      default:
        return 'assets/images/default_exercise.jpg';
    }
  }
}
