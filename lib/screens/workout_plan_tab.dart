import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên bài tập *',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập tên bài tập'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Nhóm bài tập',
                    ),
                    items: ['Tăng cơ', 'Cardio', 'Thể lực']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: setsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số hiệp (Sets)',
                          ),
                          validator: (v) =>
                              (int.tryParse(v ?? '') ?? 0) <= 0 ? '> 0' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: repsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số lần (Reps)',
                          ),
                          validator: (v) =>
                              (int.tryParse(v ?? '') ?? 0) <= 0 ? '> 0' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: calCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calo ước tính (kcal)',
                    ),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? -1) < 0 ? '>= 0' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: scheduleType,
                    decoration: const InputDecoration(
                      labelText: 'Kiểu lịch tập',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ScheduleTypes.once,
                        child: Text('Tập một lần vào ngày cụ thể'),
                      ),
                      DropdownMenuItem(
                        value: ScheduleTypes.weekly,
                        child: Text('Lặp hằng tuần theo thứ'),
                      ),
                    ],
                    onChanged: (val) {
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
                      onPressed: () async {
                        final initial =
                            DateUtilsHelper.tryParseDateKey(scheduledDateKey) ??
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
                        const Text(
                          'Chọn các thứ trong tuần:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {
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
                          onSelected: (selected) {
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
                      onPressed: () async {
                        final initial =
                            DateUtilsHelper.tryParseDateKey(startDateKey) ??
                            provider.selectedDate;
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: initial,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime(2035, 12, 31),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDateKey = DateUtilsHelper.toDateKey(picked);
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                if (scheduleType == ScheduleTypes.weekly &&
                    repeatDays.isEmpty) {
                  setDialogState(() {
                    scheduleValidationError =
                        'Vui lòng chọn ít nhất một thứ trong tuần.';
                  });
                  return;
                }

                if (isEditing &&
                    scheduleType == ScheduleTypes.once &&
                    scheduledDateKey.compareTo(provider.todayDateKey) < 0) {
                  setDialogState(() {
                    scheduleValidationError =
                        'Khi cập nhật lịch, ngày tập một lần phải từ hôm nay (${DateUtilsHelper.formatDisplayDateKey(provider.todayDateKey)}) trở đi.';
                  });
                  return;
                }

                final String resolvedStart = scheduleType == ScheduleTypes.once
                    ? scheduledDateKey
                    : startDateKey;
                final String dayOfWeekLabel = scheduleType == ScheduleTypes.once
                    ? 'Ngày ${DateUtilsHelper.formatDisplayDateKey(scheduledDateKey)}'
                    : DateUtilsHelper.formatRepeatDays(repeatDays);

                final exerciseObj = Exercise(
                  id: isEditing
                      ? existing.id
                      : DateTime.now().microsecondsSinceEpoch.toString(),
                  title: titleCtrl.text.trim(),
                  category: selectedCategory,
                  sets: int.tryParse(setsCtrl.text) ?? 3,
                  reps: int.tryParse(repsCtrl.text) ?? 10,
                  calories: int.tryParse(calCtrl.text) ?? 100,
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
        title: const Text('Xác nhận xóa / ngừng lịch'),
        content: Text(
          'Bạn có chắc chắn muốn ngừng bài tập "${item.title}" từ hôm nay (${DateUtilsHelper.formatDisplayDateKey(provider.todayDateKey)}) trở đi không?\n\nLịch sử và kết quả đã hoàn thành vẫn được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final bool deleted = await provider.deleteExercise(item.id);
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).clearSnackBars();
              if (deleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa "${item.title}"'),
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
                                    'Không thể hoàn tác xóa bài tập.',
                              ),
                              backgroundColor: Colors.red,
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
                          'Không thể xóa bài tập. Vui lòng thử lại.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('prev_day_button'),
            tooltip: 'Ngày trước',
            icon: const Icon(Icons.chevron_left),
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
                      color: Colors.teal,
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
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (provider.isSelectedDateToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Hôm nay',
                          style: TextStyle(color: Colors.white, fontSize: 11),
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
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.goToNextDay,
          ),
          if (!provider.isSelectedDateToday)
            TextButton(
              key: const Key('go_today_button'),
              onPressed: provider.goToToday,
              child: const Text('Hôm nay'),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context, WorkoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ hoàn thành: ${provider.completedCount}/${provider.totalCountForSelectedDate} bài',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '🔥 ${provider.totalCaloriesBurned} kcal (ước tính)',
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: provider.progressPercentage,
            minHeight: 8,
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
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final DayWorkoutItem item = list[index];
        final Exercise? activeEx =
            (item.exercise != null && !item.exercise!.isStopped)
            ? item.exercise
            : null;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
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
            leading: Checkbox(
              value: item.isCompleted,
              activeColor: Colors.teal,
              onChanged: (_) async {
                final ok = await provider.toggleComplete(
                  item.exerciseId,
                  dateKey: item.dateKey,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.lastErrorMessage ??
                            'Không thể cập nhật trạng thái hoàn thành.',
                      ),
                      backgroundColor: Colors.orange.shade900,
                    ),
                  );
                }
              },
            ),
            title: Text(
              item.displayTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.displayCategory} • ${item.displaySets} hiệp x ${item.displayReps} lần • ~${item.displayCalories} kcal (ước tính)\n📅 ${item.displayScheduleLabel}',
                ),
                if (item.legacyCompletedWithoutDate)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '✓ Đã hoàn thành trước đây',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (item.isHistoricalCompletionOnly)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Lưu từ lịch sử hoàn thành (lịch hiện tại đã thay đổi/ngừng)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: activeEx == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sửa bài tập',
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                        ),
                        onPressed: () => _showExerciseFormDialog(
                          context,
                          existing: activeEx,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa bài tập',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _confirmDelete(context, provider, activeEx),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
