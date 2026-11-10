import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/date_utils_helper.dart';
import '../models/day_workout_item.dart';
import '../models/exercise.dart';
import '../models/workout_completion.dart';

// ==================================================
// ADAPTER LƯU TRỮ (Cho phép giả lập lỗi lưu trong kiểm thử)
// ==================================================
abstract class WorkoutStorageAdapter {
  Future<String?> getString(String key);
  Future<bool> setString(String key, String value);
  Future<bool?> getBool(String key);
  Future<bool> setBool(String key, bool value);
  Future<double?> getDouble(String key);
  Future<bool> setDouble(String key, double value);
}

class SharedPreferencesStorageAdapter implements WorkoutStorageAdapter {
  const SharedPreferencesStorageAdapter();

  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }

  @override
  Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setDouble(key, value);
  }
}

class _DeletedExerciseSnapshot {
  final int originalIndex;
  final Exercise exerciseBeforeDelete;

  const _DeletedExerciseSnapshot({
    required this.originalIndex,
    required this.exerciseBeforeDelete,
  });
}

// ==================================================
// 2. STATE MANAGEMENT VỚI PROVIDER (BÀI 7)
// Quản lý lịch tập theo ngày, đơn vị bài tập, kiểm tra dữ liệu,
// lịch sử hoàn thành độc lập, migration và hàng đợi lưu tuần tự.
// ==================================================
class WorkoutProvider extends ChangeNotifier {
  static const String storeKeyV3 = 'fitplan_workout_store_v3';
  static const String legacyExercisesKey = 'exercises_v2';
  static const String legacyBackupKey = 'exercises_v2_backup';
  static const String migrationDateLockKey = 'fitplan_migration_date_v3';
  static const int currentSchemaVersion = 3;

  static final RegExp _positiveIntRegex = RegExp(r'^\d+$');
  static final RegExp _decimalMetricRegex = RegExp(r'^\d+([.,]\d+)?$');

  final DateTime Function() _clock;
  final WorkoutStorageAdapter _storage;

  bool _isLoggedIn = false;
  String _userEmail = '';
  double _weight = 68.0;
  double _height = 172.0;

  List<Exercise> _exercises = [];
  List<WorkoutCompletion> _completions = [];
  String? _migrationDate;
  late DateTime _selectedDate;

  bool _hasLoadError = false;
  String? _loadErrorMessage;
  String? _lastErrorMessage;

  final Map<String, _DeletedExerciseSnapshot> _deletedSnapshots = {};

  /// Hàng đợi tuần tự hóa toàn bộ thao tác đọc trạng thái -> tạo bản ứng viên -> lưu -> cập nhật bộ nhớ
  Future<void> _mutationQueue = Future<void>.value();

  WorkoutProvider({DateTime Function()? clock, WorkoutStorageAdapter? storage})
    : _clock = clock ?? DateTime.now,
      _storage = storage ?? const SharedPreferencesStorageAdapter() {
    _selectedDate = DateUtilsHelper.normalizeLocalDate(_clock());
  }

  // ---- Tiện ích kiểm tra dữ liệu nhập ----

  /// Phân tích số nguyên dương (> 0) từ chuỗi nhập. Trả về null nếu không hợp lệ.
  static int? tryParsePositiveInt(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!_positiveIntRegex.hasMatch(trimmed)) return null;
    final val = int.tryParse(trimmed);
    if (val == null || val <= 0) return null;
    return val;
  }

  /// Phân tích số nguyên không âm (>= 0) từ chuỗi nhập. Trả về null nếu không hợp lệ.
  static int? tryParseNonNegativeInt(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!_positiveIntRegex.hasMatch(trimmed)) return null;
    final val = int.tryParse(trimmed);
    if (val == null || val < 0) return null;
    return val;
  }

  /// Phân tích cân nặng / chiều cao: hỗ trợ dấu chấm hoặc dấu phẩy (vd: 67.5 hoặc 67,5),
  /// không hỗ trợ dấu phân cách hàng nghìn, từ chối rỗng, chữ, <= 0, NaN, Infinity.
  static double? tryParseBodyMetric(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!_decimalMetricRegex.hasMatch(trimmed)) return null;

    final normalized = trimmed.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (!isValidBodyMetricValue(parsed)) return null;
    return parsed;
  }

  /// Kiểm tra một số thực có phải là chỉ số cơ thể hợp lệ (hữu hạn và > 0)
  static bool isValidBodyMetricValue(double? value) {
    return value != null && !value.isNaN && value.isFinite && value > 0;
  }

  /// Tính BMI = kg / (cm / 100)^2 và kiểm tra kết quả hữu hạn > 0.
  /// Trả về null nếu đầu vào hoặc kết quả không hợp lệ.
  static double? calculateValidBmi(double? weightKg, double? heightCm) {
    if (!isValidBodyMetricValue(weightKg) ||
        !isValidBodyMetricValue(heightCm)) {
      return null;
    }
    final heightM = heightCm! / 100.0;
    if (!heightM.isFinite || heightM <= 0) return null;
    final denom = heightM * heightM;
    if (!denom.isFinite || denom <= 0) return null;
    final result = weightKg! / denom;
    if (result.isNaN || !result.isFinite || result <= 0) return null;
    return result;
  }

  // ---- Getters thông tin chung & BMI ----
  bool get isLoggedIn => _isLoggedIn;
  String get userEmail => _userEmail;
  double get weight => _weight;
  double get height => _height;

  /// Kiểm tra cân nặng, chiều cao đã lưu và BMI tính ra có hợp lệ không
  bool get hasValidBodyMetrics => calculateValidBmi(_weight, _height) != null;

  /// Giá trị BMI hợp lệ (null nếu dữ liệu cân nặng/chiều cao không hợp lệ)
  double? get validBmi => calculateValidBmi(_weight, _height);

  /// Getter BMI (trả về 0.0 khi dữ liệu không hợp lệ để không gây lỗi NaN/Infinity)
  double get bmi => validBmi ?? 0.0;

  bool get hasLoadError => _hasLoadError;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get migrationDate => _migrationDate;

  // ---- Getters ngày tháng ----
  DateTime get todayDate => DateUtilsHelper.normalizeLocalDate(_clock());
  String get todayDateKey => DateUtilsHelper.toDateKey(todayDate);

  DateTime get selectedDate => _selectedDate;
  String get selectedDateKey => DateUtilsHelper.toDateKey(_selectedDate);

  bool get isSelectedDateToday => selectedDateKey == todayDateKey;
  bool get isSelectedDateInFuture =>
      selectedDateKey.compareTo(todayDateKey) > 0;
  bool get isSelectedDateInPast => selectedDateKey.compareTo(todayDateKey) < 0;

  /// Danh sách bài tập đang hoạt động (chưa ngừng lịch)
  List<Exercise> get exercises =>
      _exercises.where((e) => !e.isStopped).toList(growable: false);

  /// Toàn bộ bài tập (bao gồm cả bài đã ngừng lịch để phục vụ dựng lịch quá khứ)
  List<Exercise> get allExercisesIncludingStopped =>
      List.unmodifiable(_exercises);

  /// Danh sách bản ghi hoàn thành
  List<WorkoutCompletion> get completions => List.unmodifiable(_completions);

  /// Danh sách bài tập có nhãn lịch cũ chưa nhận diện được cần người dùng chọn lại
  List<Exercise> get exercisesNeedingScheduleReview => _exercises
      .where((e) => !e.isStopped && e.needsScheduleReview)
      .toList(growable: false);

  /// Hợp nhất danh sách bài tập hiển thị cho một ngày cụ thể [date]
  /// (Không đếm trùng bài vừa có lịch vừa có bản ghi hoàn thành; ưu tiên dùng snapshot khi đã hoàn thành)
  List<DayWorkoutItem> itemsForDate(DateTime date) {
    final localDate = DateUtilsHelper.normalizeLocalDate(date);
    final dateKey = DateUtilsHelper.toDateKey(localDate);

    final Map<String, WorkoutCompletion> completionMap = {};
    for (final c in _completions) {
      if (c.dateKey == dateKey) {
        completionMap.putIfAbsent(c.exerciseId, () => c);
      }
    }

    final List<DayWorkoutItem> items = [];
    final Set<String> addedIds = {};

    // 1. Duyệt theo thứ tự bài tập trong _exercises
    for (final ex in _exercises) {
      final bool scheduled = ex.isScheduledOnDateKey(
        dateKey,
        localDate: localDate,
      );
      final WorkoutCompletion? comp = completionMap[ex.id];
      if (scheduled || comp != null) {
        items.add(
          DayWorkoutItem(
            exerciseId: ex.id,
            dateKey: dateKey,
            exercise: ex,
            completion: comp,
            isScheduledOnDate: scheduled,
          ),
        );
        addedIds.add(ex.id);
      }
    }

    // 2. Các bản ghi hoàn thành mà không còn tìm thấy đối tượng Exercise gốc
    for (final comp in completionMap.values) {
      if (!addedIds.contains(comp.exerciseId)) {
        items.add(
          DayWorkoutItem(
            exerciseId: comp.exerciseId,
            dateKey: dateKey,
            exercise: null,
            completion: comp,
            isScheduledOnDate: false,
          ),
        );
        addedIds.add(comp.exerciseId);
      }
    }

    return items;
  }

  /// Danh sách bài tập (hợp nhất lịch & lịch sử hoàn thành) của ngày đang chọn
  List<DayWorkoutItem> get itemsForSelectedDate => itemsForDate(_selectedDate);

  /// Tổng số bài trong ngày đang chọn (mẫu số tiến độ, không đếm trùng)
  int get totalCountForSelectedDate => itemsForSelectedDate.length;

  /// Số bài đã hoàn thành trong ngày đang chọn (tử số tiến độ)
  int get completedCount =>
      itemsForSelectedDate.where((item) => item.isCompleted).length;

  /// Tổng kcal ước tính đã hoàn thành trong ngày đang chọn (tính từ snapshot)
  int get totalCaloriesBurned => itemsForSelectedDate
      .where((item) => item.isCompleted)
      .fold(0, (sum, item) => sum + item.displayCalories);

  /// Tỷ lệ hoàn thành của ngày đang chọn (0.0 khi ngày không có bài tập)
  double get progressPercentage {
    final total = totalCountForSelectedDate;
    if (total == 0) return 0.0;
    return completedCount / total;
  }

  /// Kiểm tra một bài tập đã hoàn thành vào ngày [dateKey] (mặc định là ngày đang chọn) chưa
  bool isExerciseCompletedOn(String exerciseId, {String? dateKey}) {
    final targetDateKey = dateKey ?? selectedDateKey;
    return _completions.any(
      (c) => c.exerciseId == exerciseId && c.dateKey == targetDateKey,
    );
  }

  /// Lấy bản ghi hoàn thành của bài tập vào ngày [dateKey]
  WorkoutCompletion? completionForExerciseOn(
    String exerciseId, {
    String? dateKey,
  }) {
    final targetDateKey = dateKey ?? selectedDateKey;
    for (final c in _completions) {
      if (c.exerciseId == exerciseId && c.dateKey == targetDateKey) {
        return c;
      }
    }
    return null;
  }

  // ---- Điều hướng chọn ngày ----
  void selectDate(DateTime date) {
    _selectedDate = DateUtilsHelper.normalizeLocalDate(date);
    notifyListeners();
  }

  void goToPreviousDay() {
    _selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day - 1,
    );
    notifyListeners();
  }

  void goToNextDay() {
    _selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day + 1,
    );
    notifyListeners();
  }

  void goToToday() {
    _selectedDate = todayDate;
    notifyListeners();
  }

  void clearLastError() {
    _lastErrorMessage = null;
    notifyListeners();
  }

  // ---- Hàng đợi tuần tự hóa các thao tác ----
  Future<bool> _enqueueTask(Future<bool> Function() task) {
    final completer = Completer<bool>();
    _mutationQueue = _mutationQueue.then((_) async {
      try {
        final ok = await task();
        completer.complete(ok);
      } catch (e) {
        _lastErrorMessage = 'Đã xảy ra lỗi khi xử lý dữ liệu: $e';
        notifyListeners();
        completer.complete(false);
      }
    });
    return completer.future;
  }

  /// Dữ liệu mẫu dành riêng cho cài mới (Plank dùng giây, chạy bộ dùng phút)
  List<Exercise> _defaultExercises(String initialDateKey) => [
    Exercise(
      id: '1',
      title: 'Đẩy ngực với tạ đòn (Bench Press)',
      category: 'Tăng cơ',
      sets: 4,
      reps: 10,
      unit: ExerciseUnits.reps,
      calories: 180,
      dayOfWeek: 'T2, T5',
      notes: 'Giữ chặt bả vai trên ghế, hạ tạ chạm ngực dưới rồi đẩy thẳng.',
      scheduleType: ScheduleTypes.weekly,
      repeatDays: const [DateTime.monday, DateTime.thursday],
      startDate: initialDateKey,
      effectiveFrom: initialDateKey,
    ),
    Exercise(
      id: '2',
      title: 'Gánh tạ đòn (Barbell Squat)',
      category: 'Tăng cơ',
      sets: 4,
      reps: 12,
      unit: ExerciseUnits.reps,
      calories: 240,
      dayOfWeek: 'T3, T6',
      notes: 'Giữ lưng thẳng tự nhiên, mở gối theo hướng mũi chân.',
      scheduleType: ScheduleTypes.weekly,
      repeatDays: const [DateTime.tuesday, DateTime.friday],
      startDate: initialDateKey,
      effectiveFrom: initialDateKey,
    ),
    Exercise(
      id: '3',
      title: 'Chạy bộ biến tốc (HIIT Treadmill)',
      category: 'Cardio',
      sets: 1,
      reps: 20,
      unit: ExerciseUnits.minutes,
      calories: 300,
      dayOfWeek: 'T4, T7',
      notes: 'Chạy nước rút 30 giây, đi bộ chậm 60 giây lặp lại 20 phút.',
      scheduleType: ScheduleTypes.weekly,
      repeatDays: const [DateTime.wednesday, DateTime.saturday],
      startDate: initialDateKey,
      effectiveFrom: initialDateKey,
    ),
    Exercise(
      id: '4',
      title: 'Plank siết cơ bụng',
      category: 'Thể lực',
      sets: 3,
      reps: 60,
      unit: ExerciseUnits.seconds,
      calories: 90,
      dayOfWeek: 'Mỗi ngày',
      notes: 'Giữ cơ thể tạo thành một đường thẳng từ đầu đến gót chân.',
      scheduleType: ScheduleTypes.weekly,
      repeatDays: const [1, 2, 3, 4, 5, 6, 7],
      startDate: initialDateKey,
      effectiveFrom: initialDateKey,
    ),
  ];

  // ---- Tải dữ liệu & Chuyển đổi dữ liệu cũ (Migration) ----
  Future<bool> loadData() {
    return _enqueueTask(() async {
      try {
        _isLoggedIn = await _storage.getBool('isLoggedIn') ?? false;
        _userEmail =
            await _storage.getString('userEmail') ?? 'nhom.doan@hutech.edu.vn';

        final double? storedWeight = await _storage.getDouble('weight');
        final double? storedHeight = await _storage.getDouble('height');
        if (storedWeight == null && storedHeight == null) {
          _weight = 68.0;
          _height = 172.0;
        } else {
          // Không tự thay thế dữ liệu đã lưu không hợp lệ bằng mặc định
          // để giao diện nhận biết và yêu cầu người dùng cập nhật lại.
          _weight = storedWeight ?? -1.0;
          _height = storedHeight ?? -1.0;
        }

        final String? rawStoreV3 = await _storage.getString(storeKeyV3);

        // Trường hợp 1: Đã có dữ liệu Store v3 -> Kiểm tra tính hợp lệ và đọc trực tiếp
        if (rawStoreV3 != null) {
          final parsed = _parseAndValidateStoreV3(rawStoreV3);
          _exercises = parsed.exercises;
          _completions = parsed.completions;
          _migrationDate = parsed.migrationDate;
          _hasLoadError = false;
          _loadErrorMessage = null;
          _lastErrorMessage = null;
          notifyListeners();
          return true;
        }

        // Trường hợp 2: Chưa có Store v3 nhưng có dữ liệu cũ exercises_v2 -> Chuyển đổi (Migration)
        final String? rawLegacy = await _storage.getString(legacyExercisesKey);
        if (rawLegacy != null) {
          // Kiểm tra dữ liệu cũ hợp lệ trước khi chuyển đổi
          final List<Map<String, dynamic>> legacyMaps =
              _parseAndValidateLegacyList(rawLegacy);

          // Sao lưu nguyên bản exercises_v2 (không ghi đè nếu đã có backup)
          final String? existingBackup = await _storage.getString(
            legacyBackupKey,
          );
          if (existingBackup == null) {
            final backupSaved = await _storage.setString(
              legacyBackupKey,
              rawLegacy,
            );
            if (!backupSaved) {
              _setLoadFailure(
                'Không thể tạo bản sao lưu dữ liệu cũ. Đã dừng chuyển đổi để bảo vệ dữ liệu.',
              );
              return false;
            }
          }

          // Cố định migrationDate qua các lần thử lại hoặc khởi động lại
          String? lockedMigrationDate = await _storage.getString(
            migrationDateLockKey,
          );
          if (!DateUtilsHelper.isValidDateKey(lockedMigrationDate)) {
            lockedMigrationDate = _migrationDate ?? todayDateKey;
            _migrationDate = lockedMigrationDate;
            await _storage.setString(migrationDateLockKey, lockedMigrationDate);
          } else {
            _migrationDate = lockedMigrationDate;
          }

          final String effectiveMigrationDate = lockedMigrationDate!;
          final List<Exercise> migratedExercises = legacyMaps
              .map(
                (m) => Exercise.migrateFromLegacyJson(
                  m,
                  migrationDate: effectiveMigrationDate,
                ),
              )
              .toList();

          final bool saved = await _persistStoreCandidate(
            exercises: migratedExercises,
            completions: const <WorkoutCompletion>[],
            migrationDate: effectiveMigrationDate,
          );
          if (!saved) {
            _setLoadFailure(
              'Không thể lưu dữ liệu sau khi chuyển đổi. Dữ liệu gốc vẫn được giữ nguyên, vui lòng thử lại.',
            );
            return false;
          }

          _exercises = migratedExercises;
          _completions = [];
          _hasLoadError = false;
          _loadErrorMessage = null;
          _lastErrorMessage = null;
          notifyListeners();
          return true;
        }

        // Trường hợp 3: Cài mới hoàn toàn (chưa có Store v3 và chưa có exercises_v2)
        final initialDateKey = todayDateKey;
        final defaults = _defaultExercises(initialDateKey);
        final saved = await _persistStoreCandidate(
          exercises: defaults,
          completions: const <WorkoutCompletion>[],
          migrationDate: initialDateKey,
        );
        if (!saved) {
          _setLoadFailure(
            'Không thể khởi tạo dữ liệu lưu trữ. Vui lòng thử lại.',
          );
          return false;
        }

        _exercises = defaults;
        _completions = [];
        _migrationDate = initialDateKey;
        _hasLoadError = false;
        _loadErrorMessage = null;
        _lastErrorMessage = null;
        notifyListeners();
        return true;
      } on FormatException catch (e) {
        _setLoadFailure(
          'Dữ liệu đã lưu bị lỗi định dạng (${e.message}). Hệ thống đã chặn ghi đè để bảo vệ dữ liệu gốc.',
        );
        return false;
      } catch (e) {
        _setLoadFailure('Không thể đọc dữ liệu đã lưu ($e). Vui lòng thử lại.');
        return false;
      }
    });
  }

  void _setLoadFailure(String message) {
    _hasLoadError = true;
    _loadErrorMessage = message;
    _lastErrorMessage = message;
    notifyListeners();
  }

  List<Map<String, dynamic>> _parseAndValidateLegacyList(String rawLegacy) {
    final dynamic decoded = jsonDecode(rawLegacy);
    if (decoded is! List) {
      throw const FormatException('exercises_v2 không phải là danh sách JSON.');
    }
    final List<Map<String, dynamic>> result = [];
    final Set<String> seenIds = {};
    for (final item in decoded) {
      if (item is! Map) {
        throw const FormatException('Phần tử trong exercises_v2 không hợp lệ.');
      }
      final map = Map<String, dynamic>.from(item);
      final id = map['id']?.toString().trim() ?? '';
      final title = map['title']?.toString().trim() ?? '';
      if (id.isEmpty || title.isEmpty) {
        throw const FormatException(
          'Bài tập trong exercises_v2 thiếu id/title.',
        );
      }
      if (seenIds.contains(id)) {
        throw const FormatException('exercises_v2 có ID bài tập bị trùng.');
      }
      seenIds.add(id);
      result.add(map);
    }
    return result;
  }

  ({
    List<Exercise> exercises,
    List<WorkoutCompletion> completions,
    String? migrationDate,
  })
  _parseAndValidateStoreV3(String rawStore) {
    final dynamic decoded = jsonDecode(rawStore);
    if (decoded is! Map) {
      throw const FormatException('Store v3 không phải đối tượng JSON.');
    }
    final map = Map<String, dynamic>.from(decoded);
    if (map['schemaVersion'] != currentSchemaVersion) {
      throw const FormatException('schemaVersion không khớp phiên bản 3.');
    }

    final String? migDate = map['migrationDate']?.toString();
    if (migDate != null && !DateUtilsHelper.isValidDateKey(migDate)) {
      throw const FormatException('migrationDate trong Store v3 không hợp lệ.');
    }

    final rawExercises = map['exercises'];
    final rawCompletions = map['completions'];
    if (rawExercises is! List || rawCompletions is! List) {
      throw const FormatException(
        'Store v3 thiếu danh sách exercises hoặc completions.',
      );
    }

    final List<Exercise> parsedExercises = [];
    final Set<String> seenExerciseIds = {};
    for (final item in rawExercises) {
      if (item is! Map) {
        throw const FormatException('Phần tử exercise không phải Map.');
      }
      final ex = Exercise.fromJson(
        Map<String, dynamic>.from(item),
        fallbackDateKey: migDate ?? todayDateKey,
      );
      if (seenExerciseIds.contains(ex.id)) {
        throw const FormatException('Store v3 có exerciseId bị trùng lặp.');
      }
      seenExerciseIds.add(ex.id);
      parsedExercises.add(ex);
    }

    final List<WorkoutCompletion> parsedCompletions = [];
    final Set<String> seenRecordKeys = {};
    for (final item in rawCompletions) {
      if (item is! Map) {
        throw const FormatException('Phần tử completion không phải Map.');
      }
      final comp = WorkoutCompletion.fromJson(Map<String, dynamic>.from(item));
      if (!seenRecordKeys.contains(comp.recordKey)) {
        seenRecordKeys.add(comp.recordKey);
        parsedCompletions.add(comp);
      }
    }

    return (
      exercises: parsedExercises,
      completions: parsedCompletions,
      migrationDate: migDate,
    );
  }

  Future<bool> _persistStoreCandidate({
    required List<Exercise> exercises,
    required List<WorkoutCompletion> completions,
    required String? migrationDate,
  }) async {
    final payload = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'migrationDate': migrationDate ?? todayDateKey,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'completions': completions.map((c) => c.toJson()).toList(),
    };
    final String encoded = jsonEncode(payload);
    try {
      return await _storage.setString(storeKeyV3, encoded);
    } catch (_) {
      return false;
    }
  }

  bool _checkCanMutate() {
    if (_hasLoadError) {
      _lastErrorMessage = 'Dữ liệu chưa được tải thành công. Vui lòng tải lại trước khi chỉnh sửa.';
      notifyListeners();
      return false;
    }
    return true;
  }

  bool _validateExerciseForMutation(Exercise exercise, {required bool isEdit}) {
    if (exercise.title.trim().isEmpty) {
      _lastErrorMessage = 'Tên bài tập không được để trống.';
      notifyListeners();
      return false;
    }
    if (exercise.sets <= 0) {
      _lastErrorMessage = 'Số hiệp phải là số nguyên lớn hơn 0.';
      notifyListeners();
      return false;
    }
    if (exercise.reps <= 0) {
      _lastErrorMessage = 'Số lượng mỗi hiệp phải là số nguyên lớn hơn 0.';
      notifyListeners();
      return false;
    }
    if (!ExerciseUnits.isValidUnit(exercise.unit)) {
      _lastErrorMessage = 'Đơn vị bài tập không hợp lệ.';
      notifyListeners();
      return false;
    }
    if (exercise.calories < 0) {
      _lastErrorMessage = 'Calo ước tính phải lớn hơn hoặc bằng 0.';
      notifyListeners();
      return false;
    }
    if (exercise.scheduleType == ScheduleTypes.once) {
      if (!DateUtilsHelper.isValidDateKey(exercise.scheduledDate)) {
        _lastErrorMessage = 'Lịch tập một lần phải có ngày hợp lệ.';
        notifyListeners();
        return false;
      }
      if (isEdit && exercise.scheduledDate!.compareTo(todayDateKey) < 0) {
        _lastErrorMessage =
            'Khi cập nhật lịch, ngày tập một lần phải từ hôm nay trở đi.';
        notifyListeners();
        return false;
      }
    } else if (exercise.scheduleType == ScheduleTypes.weekly) {
      if (exercise.repeatDays.isEmpty ||
          exercise.repeatDays.any((d) => d < 1 || d > 7)) {
        _lastErrorMessage = 'Lịch lặp hằng tuần phải chọn ít nhất một thứ.';
        notifyListeners();
        return false;
      }
      if (!DateUtilsHelper.isValidDateKey(exercise.startDate)) {
        _lastErrorMessage = 'Ngày bắt đầu của lịch lặp không hợp lệ.';
        notifyListeners();
        return false;
      }
    } else {
      _lastErrorMessage = 'Kiểu lịch tập không hợp lệ.';
      notifyListeners();
      return false;
    }
    return true;
  }

  // ---- Đăng nhập / Đăng xuất / BMI ----
  Future<bool> login(String email) {
    return _enqueueTask(() async {
      final ok1 = await _storage.setBool('isLoggedIn', true);
      final ok2 = await _storage.setString('userEmail', email);
      if (!ok1 || !ok2) {
        _lastErrorMessage = 'Không thể lưu thông tin đăng nhập.';
        notifyListeners();
        return false;
      }
      _isLoggedIn = true;
      _userEmail = email;
      _lastErrorMessage = null;
      notifyListeners();
      return true;
    });
  }

  Future<bool> logout() {
    return _enqueueTask(() async {
      final ok = await _storage.setBool('isLoggedIn', false);
      if (!ok) {
        _lastErrorMessage = 'Không thể đăng xuất.';
        notifyListeners();
        return false;
      }
      _isLoggedIn = false;
      _lastErrorMessage = null;
      notifyListeners();
      return true;
    });
  }

  Future<bool> updateBodyMetrics(double newWeight, double newHeight) {
    final double capturedWeight = newWeight;
    final double capturedHeight = newHeight;
    return _enqueueTask(() async {
      if (calculateValidBmi(capturedWeight, capturedHeight) == null) {
        _lastErrorMessage =
            'Cân nặng và chiều cao phải là số dương hữu hạn lớn hơn 0.';
        notifyListeners();
        return false;
      }

      final ok1 = await _storage.setDouble('weight', capturedWeight);
      final ok2 = await _storage.setDouble('height', capturedHeight);
      if (!ok1 || !ok2) {
        _lastErrorMessage = 'Không thể lưu chỉ số cơ thể. Vui lòng thử lại.';
        notifyListeners();
        return false;
      }
      _weight = capturedWeight;
      _height = capturedHeight;
      _lastErrorMessage = null;
      notifyListeners();
      return true;
    });
  }

  /// Cập nhật cân nặng & chiều cao từ chuỗi người dùng nhập (hỗ trợ dấu chấm hoặc dấu phẩy)
  Future<bool> updateBodyMetricsFromInput(String rawWeight, String rawHeight) {
    final parsedWeight = tryParseBodyMetric(rawWeight);
    final parsedHeight = tryParseBodyMetric(rawHeight);
    if (parsedWeight == null || parsedHeight == null) {
      _lastErrorMessage =
          'Vui lòng nhập cân nặng và chiều cao là số dương hợp lệ (> 0).';
      notifyListeners();
      return Future<bool>.value(false);
    }
    return updateBodyMetrics(parsedWeight, parsedHeight);
  }

  // ---- CREATE: Thêm bài tập mới ----
  Future<bool> addExercise(Exercise exercise) {
    final Exercise capturedExercise = exercise;
    return _enqueueTask(() async {
      if (!_checkCanMutate()) return false;
      if (!_validateExerciseForMutation(capturedExercise, isEdit: false)) {
        return false;
      }

      final List<Exercise> candidateExercises = List<Exercise>.from(_exercises);
      final existingIndex = candidateExercises.indexWhere(
        (e) => e.id == capturedExercise.id,
      );
      if (existingIndex != -1) {
        candidateExercises[existingIndex] = capturedExercise;
      } else {
        candidateExercises.insert(0, capturedExercise);
      }

      final saved = await _persistStoreCandidate(
        exercises: candidateExercises,
        completions: _completions,
        migrationDate: _migrationDate,
      );
      if (!saved) {
        _lastErrorMessage = 'Không thể lưu bài tập mới. Vui lòng thử lại.';
        notifyListeners();
        return false;
      }

      _exercises = candidateExercises;
      _lastErrorMessage = null;
      notifyListeners();
      return true;
    });
  }

  // ---- UPDATE: Cập nhật bài tập & lịch tập (có hiệu lực từ hôm nay trở đi) ----
  Future<bool> updateExercise(Exercise updated) {
    final Exercise capturedUpdated = updated;
    final String capturedTodayKey = todayDateKey;
    return _enqueueTask(() async {
      if (!_checkCanMutate()) return false;
      if (!_validateExerciseForMutation(capturedUpdated, isEdit: true)) {
        return false;
      }

      final index = _exercises.indexWhere((e) => e.id == capturedUpdated.id);
      if (index == -1) {
        _lastErrorMessage = 'Không tìm thấy bài tập cần cập nhật.';
        notifyListeners();
        return false;
      }

      final existing = _exercises[index];
      final Exercise versionedUpdated = existing.applyScheduleUpdate(
        newTitle: capturedUpdated.title,
        newCategory: capturedUpdated.category,
        newSets: capturedUpdated.sets,
        newReps: capturedUpdated.reps,
        newUnit: capturedUpdated.unit,
        newCalories: capturedUpdated.calories,
        newNotes: capturedUpdated.notes,
        newScheduleType: capturedUpdated.scheduleType,
        newScheduledDate: capturedUpdated.scheduledDate,
        newRepeatDays: capturedUpdated.repeatDays,
        newStartDate: capturedUpdated.startDate,
        newEndDate: capturedUpdated.endDate,
        todayKey: capturedTodayKey,
      );

      final List<Exercise> candidateExercises = List<Exercise>.from(_exercises);
      candidateExercises[index] = versionedUpdated;

      final saved = await _persistStoreCandidate(
        exercises: candidateExercises,
        completions: _completions,
        migrationDate: _migrationDate,
      );
      if (!saved) {
        _lastErrorMessage = 'Không thể lưu cập nhật bài tập. Vui lòng thử lại.';
        notifyListeners();
        return false;
      }

      _exercises = candidateExercises;
      _lastErrorMessage = null;
      notifyListeners();
      return true;
    });
  }

  // ---- COMPLETE / UNCOMPLETE: Đánh dấu hoàn thành theo ngày ----
  Future<bool> toggleComplete(String id, {String? dateKey}) {
    final String capturedId = id;
    final String capturedDateKey = dateKey ?? selectedDateKey;
    final String capturedTodayKey = todayDateKey;
    final String capturedCompletedAt = _clock().toIso8601String();

    return _enqueueTask(() async {
      if (!_checkCanMutate()) return false;

      final bool currentlyCompleted = _completions.any(
        (c) => c.exerciseId == capturedId && c.dateKey == capturedDateKey,
      );

      if (currentlyCompleted) {
        return _performUncomplete(
          exerciseId: capturedId,
          dateKey: capturedDateKey,
        );
      } else {
        return _performMarkComplete(
          exerciseId: capturedId,
          dateKey: capturedDateKey,
          todayKey: capturedTodayKey,
          completedAt: capturedCompletedAt,
        );
      }
    });
  }

  /// Đánh dấu hoàn thành cho bài tập vào ngày chỉ định.
  /// Nếu bản ghi hoàn thành đã tồn tại cho (exerciseId, dateKey),
  /// tuyệt đối KHÔNG ghi đè snapshot cũ.
  Future<bool> markExerciseCompleted(String id, {String? dateKey}) {
    final String capturedId = id;
    final String capturedDateKey = dateKey ?? selectedDateKey;
    final String capturedTodayKey = todayDateKey;
    final String capturedCompletedAt = _clock().toIso8601String();

    return _enqueueTask(() async {
      if (!_checkCanMutate()) return false;
      return _performMarkComplete(
        exerciseId: capturedId,
        dateKey: capturedDateKey,
        todayKey: capturedTodayKey,
        completedAt: capturedCompletedAt,
      );
    });
  }

  /// Bỏ đánh dấu hoàn thành cho bài tập vào ngày chỉ định (thao tác riêng biệt).
  Future<bool> unmarkExerciseCompleted(String id, {String? dateKey}) {
    final String capturedId = id;
    final String capturedDateKey = dateKey ?? selectedDateKey;

    return _enqueueTask(() async {
      if (!_checkCanMutate()) return false;
      return _performUncomplete(
        exerciseId: capturedId,
        dateKey: capturedDateKey,
      );
    });
  }

  Future<bool> _performMarkComplete({
    required String exerciseId,
    required String dateKey,
    required String todayKey,
    required String completedAt,
  }) async {
    if (dateKey.compareTo(todayKey) > 0) {
      _lastErrorMessage =
          'Không thể đánh dấu hoàn thành cho ngày trong tương lai.';
      notifyListeners();
      return false;
    }

    // Nếu bản ghi hoàn thành đã tồn tại, giữ nguyên snapshot cũ, không ghi đè
    final existingRecord = _completions.any(
      (c) => c.exerciseId == exerciseId && c.dateKey == dateKey,
    );
    if (existingRecord) {
      _lastErrorMessage = null;
      return true;
    }

    final int exIndex = _exercises.indexWhere((e) => e.id == exerciseId);
    if (exIndex == -1) {
      _lastErrorMessage = 'Không tìm thấy bài tập để ghi nhận hoàn thành.';
      notifyListeners();
      return false;
    }

    final Exercise ex = _exercises[exIndex];
    if (!ex.isScheduledOnDateKey(dateKey)) {
      _lastErrorMessage =
          'Bài tập không có trong lịch của ngày ${DateUtilsHelper.formatDisplayDateKey(dateKey)}.';
      notifyListeners();
      return false;
    }

    final newCompletion = WorkoutCompletion(
      exerciseId: ex.id,
      dateKey: dateKey,
      completedAt: completedAt,
      titleSnapshot: ex.title,
      categorySnapshot: ex.category,
      setsSnapshot: ex.sets,
      repsSnapshot: ex.reps,
      unitSnapshot: ex.unit,
      caloriesSnapshot: ex.calories,
      notesSnapshot: ex.notes,
      scheduleLabelSnapshot: ex.scheduleLabel,
    );

    final List<WorkoutCompletion> candidateCompletions = [
      ..._completions,
      newCompletion,
    ];

    final saved = await _persistStoreCandidate(
      exercises: _exercises,
      completions: candidateCompletions,
      migrationDate: _migrationDate,
    );
    if (!saved) {
      _lastErrorMessage =
          'Không thể lưu trạng thái hoàn thành. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }

    _completions = candidateCompletions;
    _lastErrorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> _performUncomplete({
    required String exerciseId,
    required String dateKey,
  }) async {
    final List<WorkoutCompletion> candidateCompletions = _completions
        .where((c) => !(c.exerciseId == exerciseId && c.dateKey == dateKey))
        .toList();

    if (candidateCompletions.length == _completions.length) {
      _lastErrorMessage = null;
      return true;
    }

    final saved = await _persistStoreCandidate(
      exercises: _exercises,
      completions: candidateCompletions,
      migrationDate: _migrationDate,
    );
    if (!saved) {
      _lastErrorMessage = 'Không thể lưu thay đổi. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }

    _completions = candidateCompletions;
    _lastErrorMessage = null;
    notifyListeners();
    return true;
  }

  // ---- DELETE & UNDO: Ngừng lịch từ hôm nay, giữ lịch sử và hoàn tác ----
  Future<bool> deleteExercise(String id) {
    final String capturedId = id;
    final String capturedTodayKey = todayDateKey;

    return _enqueueTask(() async {
      if (!_checkCanMutate()) return false;

      final index = _exercises.indexWhere((e) => e.id == capturedId);
      if (index == -1) {
        _lastErrorMessage = 'Không tìm thấy bài tập cần xóa.';
        notifyListeners();
        return false;
      }

      final Exercise beforeDelete = _exercises[index];
      final Exercise stoppedExercise = beforeDelete.stopScheduleFromToday(
        capturedTodayKey,
      );

      final List<Exercise> candidateExercises = List<Exercise>.from(_exercises);
      candidateExercises[index] = stoppedExercise;

      final saved = await _persistStoreCandidate(
        exercises: candidateExercises,
        completions: _completions,
        migrationDate: _migrationDate,
      );
      if (!saved) {
        _lastErrorMessage = 'Không thể xóa bài tập. Vui lòng thử lại.';
        notifyListeners();
        return false;
      }

      _deletedSnapshots[capturedId] = _DeletedExerciseSnapshot(
        originalIndex: index,
        exerciseBeforeDelete: beforeDelete,
      );
      _exercises = candidateExercises;
      _lastErrorMessage = null;
      notifyListeners();
      return true;
    });
  }

  /// Hoàn tác xóa bài tập: khôi phục đúng trạng thái lịch và vị trí thứ tự ban đầu,
  /// không nhân đôi bản ghi hoàn thành.
  Future<bool> restoreDeletedExercise(String id) {
    final String capturedId = id;

    return _enqueueTask(() async {
      if (!_checkCanMutate()) return false;

      final snapshot = _deletedSnapshots[capturedId];
      if (snapshot == null) {
        _lastErrorMessage = 'Không tìm thấy thông tin bài tập để hoàn tác.';
        notifyListeners();
        return false;
      }

      final List<Exercise> candidateExercises = List<Exercise>.from(_exercises);
      final currentIndex = candidateExercises.indexWhere(
        (e) => e.id == capturedId,
      );

      if (currentIndex != -1) {
        candidateExercises.removeAt(currentIndex);
      }
      final int insertIndex = snapshot.originalIndex.clamp(
        0,
        candidateExercises.length,
      );
      candidateExercises.insert(insertIndex, snapshot.exerciseBeforeDelete);

      final saved = await _persistStoreCandidate(
        exercises: candidateExercises,
        completions: _completions,
        migrationDate: _migrationDate,
      );
      if (!saved) {
        _lastErrorMessage = 'Không thể hoàn tác xóa bài tập. Vui lòng thử lại.';
        notifyListeners();
        return false;
      }

      _deletedSnapshots.remove(capturedId);
      _exercises = candidateExercises;
      _lastErrorMessage = null;
      notifyListeners();
      return true;
    });
  }
}
