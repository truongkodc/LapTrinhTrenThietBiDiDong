import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../helpers/date_utils_helper.dart';
import '../models/day_workout_item.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import 'exercise_detail_screen.dart';

// =========================================================
// 5. TAB 1: DANH SÁCH KẾ HOẠCH TẬP THEO NGÀY + ĐẦY ĐỦ CRUD
// =========================================================
class WorkoutPlanTab extends StatelessWidget {
  const WorkoutPlanTab({super.key});

  Future<void> _pickViewDate(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Chọn ngày xem lịch tập',
    );
    if (picked != null) {
      provider.selectDate(picked);
    }
  }

  // Hộp thoại dùng chung cho cả THÊM MỚI và CẬP NHẬT (SỬA)
  void _showExerciseFormDialog(BuildContext context, {Exercise? existing}) {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    if (provider.hasLoadError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.loadErrorMessage ??
                'Không thể chỉnh sửa khi dữ liệu chưa tải thành công.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isEditing = existing != null;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final setsCtrl = TextEditingController(
      text: (existing?.sets ?? 4).toString(),
    );
    final repsCtrl = TextEditingController(
      text: (existing?.reps ?? 12).toString(),
    );
    final calCtrl = TextEditingController(
      text: (existing?.calories ?? 150).toString(),
    );
    final notesCtrl = TextEditingController(
      text: existing?.notes ?? 'Khởi động kỹ 5 phút trước khi tập.',
    );

    String selectedCategory = existing?.category ?? 'Tăng cơ';
    String selectedUnit = existing?.unit ?? ExerciseUnits.defaultUnit;
    String scheduleType =
        (existing != null && existing.scheduleType == ScheduleTypes.once)
        ? ScheduleTypes.once
        : ScheduleTypes.weekly;

    String scheduledDateKey =
        existing?.scheduledDate ??
        (isEditing ? provider.todayDateKey : provider.selectedDateKey);

    List<int> repeatDays =
        (existing != null &&
            existing.scheduleType == ScheduleTypes.weekly &&
            existing.repeatDays.isNotEmpty)
        ? List<int>.from(existing.repeatDays)
        : <int>[provider.selectedDate.weekday];

    String startDateKey = existing != null
        ? (existing.startDate.compareTo(provider.todayDateKey) < 0 && isEditing
              ? provider.todayDateKey
              : existing.startDate)
        : provider.selectedDateKey;

    String? scheduleValidationError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: Text(isEditing ? 'Cập nhật bài tập' : 'Thêm bài tập mới'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditing) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Text(
                        'Lưu ý: Thay đổi lịch tập có hiệu lực từ hôm nay (${DateUtilsHelper.formatDisplayDateKey(provider.todayDateKey)}) trở đi, không làm thay đổi lịch và kết quả các ngày trước.',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                  TextFormField(
                    key: const Key('exercise_title_field'),
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên bài tập *',
                      errorMaxLines: 2,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập tên bài tập'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Nhóm bài tập',
                    ),
                    items: ['Tăng cơ', 'Cardio', 'Thể lực']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: isSubmitting
                        ? null
                        : (val) =>
                              setDialogState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('exercise_unit_dropdown'),
                    isExpanded: true,
                    initialValue: selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị mỗi hiệp',
                    ),
                    items: ExerciseUnits.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: isSubmitting
                        ? null
                        : (val) => setDialogState(() => selectedUnit = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('exercise_sets_field'),
                          controller: setsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số hiệp',
                            errorMaxLines: 3,
                          ),
                          validator: (v) =>
                              WorkoutProvider.tryParsePositiveInt(v) == null
                              ? 'Số hiệp phải là số nguyên dương (> 0)'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const Key('exercise_quantity_field'),
                          controller: repsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: ExerciseUnits.quantityInputLabel(
                              selectedUnit,
                            ),
                            errorMaxLines: 3,
                          ),
                          validator: (v) =>
                              WorkoutProvider.tryParsePositiveInt(v) == null
                              ? '${ExerciseUnits.quantityInputLabel(selectedUnit)} phải là số nguyên dương (> 0)'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('exercise_calories_field'),
                    controller: calCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calo ước tính (kcal)',
                      errorMaxLines: 2,
                    ),
                    validator: (v) =>
                        WorkoutProvider.tryParseNonNegativeInt(v) == null
                        ? 'Kcal phải là số nguyên từ 0 trở lên'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: scheduleType,
                    decoration: const InputDecoration(
                      labelText: 'Kiểu lịch tập',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ScheduleTypes.once,
                        child: Text(
                          'Tập một lần vào ngày cụ thể',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: ScheduleTypes.weekly,
                        child: Text(
                          'Lặp hằng tuần theo thứ',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: isSubmitting
                        ? null
                        : (val) {
                            setDialogState(() {
                              scheduleType = val!;
                              scheduleValidationError = null;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  if (scheduleType == ScheduleTypes.once) ...[
                    OutlinedButton.icon(
                      key: const Key('pick_once_date_button'),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final initial =
                                  DateUtilsHelper.tryParseDateKey(
                                    scheduledDateKey,
                                  ) ??
                                  provider.selectedDate;
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: initial,
                                firstDate: DateTime(2020, 1, 1),
                                lastDate: DateTime(2035, 12, 31),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  scheduledDateKey = DateUtilsHelper.toDateKey(
                                    picked,
                                  );
                                  scheduleValidationError = null;
                                });
                              }
                            },
                      icon: const Icon(Icons.event),
                      label: Text(
                        'Ngày tập: ${DateUtilsHelper.formatDisplayDateKey(scheduledDateKey)}',
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Chọn các thứ trong tuần:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  setDialogState(() {
                                    repeatDays = [1, 2, 3, 4, 5, 6, 7];
                                    scheduleValidationError = null;
                                  });
                                },
                          child: const Text('Mỗi ngày'),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: List.generate(7, (idx) {
                        final weekday = idx + 1;
                        final isSelected = repeatDays.contains(weekday);
                        return FilterChip(
                          key: Key('weekday_chip_$weekday'),
                          label: Text(
                            DateUtilsHelper.weekdayShortLabel(weekday),
                          ),
                          selected: isSelected,
                          onSelected: isSubmitting
                              ? null
                              : (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      repeatDays.add(weekday);
                                      repeatDays.sort();
                                    } else {
                                      repeatDays.remove(weekday);
                                    }
                                    scheduleValidationError = null;
                                  });
                                },
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('pick_start_date_button'),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final initial =
                                  DateUtilsHelper.tryParseDateKey(
                                    startDateKey,
                                  ) ??
                                  provider.selectedDate;
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: initial,
                                firstDate: DateTime(2020, 1, 1),
                                lastDate: DateTime(2035, 12, 31),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  startDateKey = DateUtilsHelper.toDateKey(
                                    picked,
                                  );
                                  scheduleValidationError = null;
                                });
                              }
                            },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        'Ngày bắt đầu: ${DateUtilsHelper.formatDisplayDateKey(startDateKey)}',
                      ),
                    ),
                  ],
                  if (scheduleValidationError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      scheduleValidationError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú kỹ thuật tập',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              key: const Key('save_exercise_button'),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final isFormValid = formKey.currentState!.validate();
                      String? nextScheduleError;

                      if (scheduleType == ScheduleTypes.once) {
                        if (DateUtilsHelper.tryParseDateKey(scheduledDateKey) ==
                            null) {
                          nextScheduleError = 'Vui lòng chọn ngày tập hợp lệ.';
                        } else if (isEditing &&
                            scheduledDateKey.compareTo(provider.todayDateKey) <
                                0) {
                          nextScheduleError =
                              'Khi cập nhật lịch, ngày tập một lần phải từ hôm nay (${DateUtilsHelper.formatDisplayDateKey(provider.todayDateKey)}) trở đi.';
                        }
                      } else if (scheduleType == ScheduleTypes.weekly) {
                        if (repeatDays.isEmpty) {
                          nextScheduleError =
                              'Vui lòng chọn ít nhất một thứ trong tuần.';
                        } else if (DateUtilsHelper.tryParseDateKey(
                              startDateKey,
                            ) ==
                            null) {
                          nextScheduleError =
                              'Vui lòng chọn ngày bắt đầu hợp lệ.';
                        }
                      } else {
                        nextScheduleError = 'Kiểu lịch tập không hợp lệ.';
                      }

                      if (nextScheduleError != scheduleValidationError) {
                        setDialogState(() {
                          scheduleValidationError = nextScheduleError;
                        });
                      }

                      if (!isFormValid || nextScheduleError != null) {
                        return;
                      }

                      final parsedSets = WorkoutProvider.tryParsePositiveInt(
                        setsCtrl.text,
                      );
                      final parsedReps = WorkoutProvider.tryParsePositiveInt(
                        repsCtrl.text,
                      );
                      final parsedCalories =
                          WorkoutProvider.tryParseNonNegativeInt(calCtrl.text);

                      if (parsedSets == null ||
                          parsedReps == null ||
                          parsedCalories == null ||
                          !ExerciseUnits.isValidUnit(selectedUnit)) {
                        return;
                      }

                      final String resolvedStart =
                          scheduleType == ScheduleTypes.once
                          ? scheduledDateKey
                          : startDateKey;
                      final String dayOfWeekLabel =
                          scheduleType == ScheduleTypes.once
                          ? 'Ngày ${DateUtilsHelper.formatDisplayDateKey(scheduledDateKey)}'
                          : DateUtilsHelper.formatRepeatDays(repeatDays);

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        final exerciseObj = Exercise(
                          id: isEditing
                              ? existing.id
                              : DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                          title: titleCtrl.text.trim(),
                          category: selectedCategory,
                          sets: parsedSets,
                          reps: parsedReps,
                          unit: selectedUnit,
                          calories: parsedCalories,
                          dayOfWeek: dayOfWeekLabel,
                          notes: notesCtrl.text.trim(),
                          imagePath: isEditing ? existing.imagePath : '',
                          isCompleted: false,
                          createdAt: isEditing ? existing.createdAt : null,
                          scheduleType: scheduleType,
                          scheduledDate: scheduleType == ScheduleTypes.once
                              ? scheduledDateKey
                              : null,
                          repeatDays: scheduleType == ScheduleTypes.weekly
                              ? repeatDays
                              : const [],
                          startDate: resolvedStart,
                          effectiveFrom: resolvedStart,
                          legacyCompletedWithoutDate: isEditing
                              ? existing.legacyCompletedWithoutDate
                              : false,
                          scheduleHistory: isEditing
                              ? existing.scheduleHistory
                              : const [],
                        );

                        final bool success = isEditing
                            ? await provider.updateExercise(exerciseObj)
                            : await provider.addExercise(exerciseObj);

                        if (!ctx.mounted) return;
                        if (success) {
                          Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Đã cập nhật "${exerciseObj.title}" (hiệu lực từ hôm nay)!'
                                      : 'Đã thêm "${exerciseObj.title}" vào lịch tập!',
                                ),
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isSubmitting = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.lastErrorMessage ??
                                    'Không thể lưu dữ liệu. Vui lòng thử lại.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() {
                            isSubmitting = false;
                          });
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.lastErrorMessage ??
                                    'Dữ liệu không hợp lệ hoặc không thể lưu.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Text(isEditing ? 'Cập nhật' : 'Lưu bài tập'),
            ),
          ],
        ),
      ),
    );
  }

  // Hộp thoại AlertDialog xác nhận trước khi xóa/ngừng lịch
  void _confirmDelete(
    BuildContext context,
    WorkoutProvider provider,
    Exercise item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ngừng lịch "${item.title}"'),
        content: const Text(
          'Ngừng lịch tập này từ hôm nay? Kết quả đã hoàn thành vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel_stop_schedule_button'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            key: const Key('confirm_stop_schedule_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final bool deleted = await provider.deleteExercise(item.id);
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).clearSnackBars();
              if (deleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã ngừng lịch "${item.title}" từ hôm nay.'),
                    action: SnackBarAction(
                      label: 'Hoàn tác (Undo)',
                      onPressed: () async {
                        final restored = await provider.restoreDeletedExercise(
                          item.id,
                        );
                        if (!context.mounted) return;
                        if (!restored) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.lastErrorMessage ??
                                    'Không thể hoàn tác lịch tập.',
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.lastErrorMessage ??
                          'Không thể ngừng lịch bài tập. Vui lòng thử lại.',
                    ),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text(
              'Ngừng lịch',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Kế Hoạch Tập Luyện'),
              centerTitle: true,
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.list), text: 'Tất cả'),
                  Tab(icon: Icon(Icons.fitness_center), text: 'Tăng cơ'),
                  Tab(icon: Icon(Icons.directions_run), text: 'Cardio'),
                  Tab(icon: Icon(Icons.bolt), text: 'Thể lực'),
                ],
              ),
            ),
            body: provider.hasLoadError
                ? _buildLoadErrorView(context, provider)
                : Column(
                    children: [
                      _buildDateSelectorBar(context, provider),
                      _buildProgressSummary(context, provider),
                      if (provider.isSelectedDateInPast)
                        _buildStatusBanner(
                          icon: Icons.history,
                          color: Colors.blueGrey,
                          text:
                              'Đang xem ngày quá khứ. Việc sửa hoặc ngừng lịch sẽ có hiệu lực từ hôm nay (${DateUtilsHelper.formatDisplayDateKey(provider.todayDateKey)}).',
                        ),
                      if (provider.isSelectedDateInFuture)
                        _buildStatusBanner(
                          icon: Icons.info_outline,
                          color: Colors.orange.shade800,
                          text: 'Đang xem ngày tương lai. Chỉ có thể đánh dấu hoàn thành cho hôm nay hoặc ngày đã qua.',
                        ),
                      if (provider.exercisesNeedingScheduleReview.isNotEmpty)
                        _buildUnrecognizedScheduleBanner(context, provider),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildExerciseList(context, provider, 'Tất cả'),
                            _buildExerciseList(context, provider, 'Tăng cơ'),
                            _buildExerciseList(context, provider, 'Cardio'),
                            _buildExerciseList(context, provider, 'Thể lực'),
                          ],
                        ),
                      ),
                    ],
                  ),
            floatingActionButton: provider.hasLoadError
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _showExerciseFormDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm bài tập'),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildLoadErrorView(BuildContext context, WorkoutProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              provider.loadErrorMessage ?? 'Không thể tải dữ liệu lịch tập. Đã tạm khóa chỉnh sửa để bảo vệ dữ liệu gốc.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('retry_load_button'),
              onPressed: () => provider.loadData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectorBar(BuildContext context, WorkoutProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('prev_day_button'),
            tooltip: 'Ngày trước',
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
            onPressed: provider.goToPreviousDay,
          ),
          Expanded(
            child: InkWell(
              key: const Key('select_date_button'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _pickViewDate(context, provider),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        DateUtilsHelper.formatFullVietnameseDate(
                          provider.selectedDate,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (provider.isSelectedDateToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.amberAccentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Hôm nay',
                          style: TextStyle(
                            color: AppTheme.amberOnColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('next_day_button'),
            tooltip: 'Ngày sau',
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
            onPressed: provider.goToNextDay,
          ),
          if (!provider.isSelectedDateToday)
            TextButton(
              key: const Key('go_today_button'),
              onPressed: provider.goToToday,
              child: const Text(
                'Hôm nay',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context, WorkoutProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceTint,
        border: Border(bottom: BorderSide(color: Color(0xFFB2DFDB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Tiến độ hoàn thành: ${provider.completedCount}/${provider.totalCountForSelectedDate} bài',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '🔥 ${provider.totalCaloriesBurned} kcal (ước tính)',
                style: const TextStyle(
                  color: AppTheme.accentCaloriesColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: provider.progressPercentage,
            minHeight: 8,
            color: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnrecognizedScheduleBanner(
    BuildContext context,
    WorkoutProvider provider,
  ) {
    final reviewList = provider.exercisesNeedingScheduleReview;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Bài tập có nhãn lịch cũ cần chọn lại lịch:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...reviewList.map(
            (ex) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '• ${ex.title} (Nhãn gốc: "${ex.dayOfWeek}")',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    key: Key('review_schedule_${ex.id}'),
                    onPressed: () =>
                        _showExerciseFormDialog(context, existing: ex),
                    child: const Text('Chọn lại lịch'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    WorkoutProvider provider,
    String filter,
  ) {
    final allItems = provider.itemsForSelectedDate;
    final list = filter == 'Tất cả'
        ? allItems
        : allItems.where((item) => item.displayCategory == filter).toList();

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Chưa có bài tập nào trong mục này cho ngày ${DateUtilsHelper.formatDisplayDate(provider.selectedDate)}.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final DayWorkoutItem item = list[index];
        final Exercise? activeEx =
            (item.exercise != null && !item.exercise!.isStopped)
            ? item.exercise
            : null;
        final Color catColor = AppTheme.categoryColor(item.displayCategory);

        return Card(
          color: item.isCompleted
              ? AppTheme.completedCardBackground
              : AppTheme.cardBackground,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            side: BorderSide(
              color: item.isCompleted
                  ? AppTheme.primaryColor.withValues(alpha: 0.45)
                  : const Color(0xFFD5E3E0),
              width: item.isCompleted ? 1.3 : 1.0,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(
                    exercise: item.toDisplayExercise(),
                    selectedDate: provider.selectedDate,
                    isCompletedOnDate: item.isCompleted,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dòng riêng cho tiêu đề bài tập (Checkbox + Tiêu đề toàn chiều ngang)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        key: Key('checkbox_exercise_${item.exerciseId}'),
                        value: item.isCompleted,
                        activeColor: AppTheme.primaryColor,
                        visualDensity: VisualDensity.compact,
                        onChanged: (_) async {
                          final ok = await provider.toggleComplete(
                            item.exerciseId,
                            dateKey: item.dateKey,
                          );
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.lastErrorMessage ?? 'Không thể cập nhật trạng thái hoàn thành.',
                                ),
                                backgroundColor: Colors.orange.shade900,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.displayTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Nhóm bài tập và khối lượng
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppTheme.categoryIcon(item.displayCategory),
                                    size: 13,
                                    color: catColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.displayCategory,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: catColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.displayVolumeLabel,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 3. Kcal ước tính
                        Text(
                          '🔥 ~${item.displayCalories} kcal (ước tính)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentCaloriesColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 4. Lịch tập
                        Text(
                          '📅 ${item.displayScheduleLabel}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        // 5. Ghi chú lịch sử nếu có
                        if (item.legacyCompletedWithoutDate)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '✓ Đã hoàn thành trước đây',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (item.isHistoricalCompletionOnly)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Kết quả đã lưu từ lịch trước đây',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        // 6. Vùng riêng cho huy hiệu "Đã hoàn thành" và nút Sửa / Ngừng lịch
                        if (item.isCompleted || activeEx != null) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (item.isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: AppTheme.primaryColor,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Đã hoàn thành',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                if (activeEx != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        key: Key(
                                          'edit_exercise_${activeEx.id}',
                                        ),
                                        tooltip: 'Sửa bài tập',
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppTheme.primaryColor,
                                        ),
                                        onPressed: () =>
                                            _showExerciseFormDialog(
                                              context,
                                              existing: activeEx,
                                            ),
                                      ),
                                      IconButton(
                                        key: Key(
                                          'delete_exercise_${activeEx.id}',
                                        ),
                                        tooltip: 'Ngừng lịch bài tập',
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppTheme.errorColor,
                                        ),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          provider,
                                          activeEx,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
