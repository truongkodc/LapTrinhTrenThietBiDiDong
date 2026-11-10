import '../helpers/date_utils_helper.dart';
import 'exercise.dart';

// =============================================
// BẢN GHI HOÀN THÀNH BÀI TẬP THEO NGÀY (SNAPSHOT)
// Định danh duy nhất bởi: exerciseId + dateKey
// =============================================

class WorkoutCompletion {
  final String exerciseId;
  final String dateKey; // Ngày tập được ghi nhận (yyyy-MM-dd)
  final String completedAt; // Thời điểm người dùng nhấn hoàn thành (ISO-8601)
  final String titleSnapshot;
  final String categorySnapshot;
  final int setsSnapshot;
  final int repsSnapshot;
  final String
  unitSnapshot; // Đơn vị tại thời điểm hoàn thành ('lần' | 'giây' | 'phút')
  final int caloriesSnapshot; // Kcal ước tính tại thời điểm hoàn thành
  final String notesSnapshot;
  final String scheduleLabelSnapshot;

  WorkoutCompletion({
    required this.exerciseId,
    required this.dateKey,
    required this.completedAt,
    required this.titleSnapshot,
    required this.categorySnapshot,
    required this.setsSnapshot,
    required this.repsSnapshot,
    this.unitSnapshot = ExerciseUnits.defaultUnit,
    required this.caloriesSnapshot,
    required this.notesSnapshot,
    required this.scheduleLabelSnapshot,
  }) {
    if (!ExerciseUnits.isValidUnit(unitSnapshot)) {
      throw FormatException(
        'Đơn vị trong bản ghi hoàn thành không hợp lệ: $unitSnapshot',
      );
    }
  }

  /// Khóa định danh duy nhất cho cặp bài tập + ngày tập
  String get recordKey => '${exerciseId}__$dateKey';

  /// Chuỗi khối lượng từ snapshot (vd: "3 hiệp × 60 giây")
  String get volumeSnapshotLabel =>
      ExerciseUnits.formatVolume(setsSnapshot, repsSnapshot, unitSnapshot);

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'dateKey': dateKey,
    'completedAt': completedAt,
    'titleSnapshot': titleSnapshot,
    'categorySnapshot': categorySnapshot,
    'setsSnapshot': setsSnapshot,
    'repsSnapshot': repsSnapshot,
    'unitSnapshot': unitSnapshot,
    'caloriesSnapshot': caloriesSnapshot,
    'notesSnapshot': notesSnapshot,
    'scheduleLabelSnapshot': scheduleLabelSnapshot,
  };

  factory WorkoutCompletion.fromJson(Map<String, dynamic> json) {
    final rawExerciseId = json['exerciseId']?.toString().trim() ?? '';
    final rawDateKey = json['dateKey']?.toString().trim() ?? '';
    if (rawExerciseId.isEmpty || !DateUtilsHelper.isValidDateKey(rawDateKey)) {
      throw const FormatException(
        'Bản ghi hoàn thành không hợp lệ (thiếu exerciseId hoặc dateKey sai định dạng).',
      );
    }

    final sets = json['setsSnapshot'];
    final reps = json['repsSnapshot'];
    final calories = json['caloriesSnapshot'];
    if (sets is! int ||
        sets <= 0 ||
        reps is! int ||
        reps <= 0 ||
        calories is! int ||
        calories < 0) {
      throw const FormatException(
        'Snapshot thông số bài tập trong bản ghi hoàn thành không hợp lệ.',
      );
    }

    final rawUnit = json['unitSnapshot'];
    final String parsedUnit = rawUnit == null
        ? ExerciseUnits.defaultUnit
        : rawUnit.toString().trim();
    if (!ExerciseUnits.isValidUnit(parsedUnit)) {
      throw FormatException(
        'unitSnapshot trong bản ghi hoàn thành không hợp lệ: $rawUnit',
      );
    }

    final title = json['titleSnapshot']?.toString().trim() ?? '';
    if (title.isEmpty) {
      throw const FormatException(
        'Bản ghi hoàn thành thiếu tên bài tập snapshot.',
      );
    }

    return WorkoutCompletion(
      exerciseId: rawExerciseId,
      dateKey: rawDateKey,
      completedAt: json['completedAt']?.toString() ?? rawDateKey,
      titleSnapshot: title,
      categorySnapshot: json['categorySnapshot']?.toString() ?? 'Tăng cơ',
      setsSnapshot: sets,
      repsSnapshot: reps,
      unitSnapshot: parsedUnit,
      caloriesSnapshot: calories,
      notesSnapshot: json['notesSnapshot']?.toString() ?? '',
      scheduleLabelSnapshot: json['scheduleLabelSnapshot']?.toString() ?? '',
    );
  }
}
