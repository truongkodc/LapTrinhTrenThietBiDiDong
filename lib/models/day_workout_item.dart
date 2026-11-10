import 'exercise.dart';
import 'workout_completion.dart';

// =============================================
// VIEW-MODEL BÀI TẬP THEO NGÀY ĐANG CHỌN
// Hợp nhất lịch tập và bản ghi hoàn thành (snapshot)
// =============================================

class DayWorkoutItem {
  final String exerciseId;
  final String dateKey;
  final Exercise? exercise;
  final WorkoutCompletion? completion;
  final bool isScheduledOnDate;

  const DayWorkoutItem({
    required this.exerciseId,
    required this.dateKey,
    this.exercise,
    this.completion,
    required this.isScheduledOnDate,
  });

  bool get isCompleted => completion != null;

  /// Bài tập đã hoàn thành vào ngày này nhưng lịch hiện tại đã sửa/ngừng
  bool get isHistoricalCompletionOnly => isCompleted && !isScheduledOnDate;

  /// Dùng thông tin từ snapshot khi bài tập đã hoàn thành trong ngày đó
  String get displayTitle =>
      completion?.titleSnapshot ?? exercise?.title ?? 'Bài tập đã lưu';

  String get displayCategory =>
      completion?.categorySnapshot ?? exercise?.category ?? 'Tăng cơ';

  int get displaySets => completion?.setsSnapshot ?? exercise?.sets ?? 1;

  int get displayReps => completion?.repsSnapshot ?? exercise?.reps ?? 1;

  int get displayCalories =>
      completion?.caloriesSnapshot ?? exercise?.calories ?? 0;

  String get displayNotes => completion?.notesSnapshot ?? exercise?.notes ?? '';

  String get displayScheduleLabel {
    if (completion != null && completion!.scheduleLabelSnapshot.isNotEmpty) {
      return completion!.scheduleLabelSnapshot;
    }
    return exercise?.scheduleLabel ?? '';
  }

  bool get legacyCompletedWithoutDate =>
      exercise?.legacyCompletedWithoutDate ?? false;

  /// Tạo đối tượng Exercise tương ứng để truyền sang màn hình chi tiết
  Exercise toDisplayExercise() {
    if (completion != null) {
      return Exercise(
        id: exerciseId,
        title: displayTitle,
        category: displayCategory,
        sets: displaySets,
        reps: displayReps,
        calories: displayCalories,
        dayOfWeek: displayScheduleLabel,
        notes: displayNotes,
        imagePath: exercise?.imagePath ?? '',
        isCompleted: true,
        createdAt: exercise?.createdAt,
        scheduleType: exercise?.scheduleType ?? ScheduleTypes.weekly,
        scheduledDate: exercise?.scheduledDate,
        repeatDays: exercise?.repeatDays,
        startDate: exercise?.startDate ?? dateKey,
        effectiveFrom: exercise?.effectiveFrom ?? dateKey,
        endDate: exercise?.endDate,
        isStopped: exercise?.isStopped ?? false,
        needsScheduleReview: exercise?.needsScheduleReview ?? false,
        legacyCompletedWithoutDate: legacyCompletedWithoutDate,
        scheduleHistory: exercise?.scheduleHistory,
      );
    }
    return exercise!;
  }
}
