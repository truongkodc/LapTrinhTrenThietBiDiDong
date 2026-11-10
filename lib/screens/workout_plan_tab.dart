import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import 'exercise_detail_screen.dart';

// =========================================================
// 5. TAB 1: DANH SÁCH KẾ HOẠCH TẬP + ĐẦY ĐỦ CRUD (THÊM/SỬA/XÓA)
// =========================================================
class WorkoutPlanTab extends StatelessWidget {
  const WorkoutPlanTab({super.key});

  // Hộp thoại dùng chung cho cả THÊM MỚI và CẬP NHẬT (SỬA)
  void _showExerciseFormDialog(BuildContext context, {Exercise? existing}) {
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
    String selectedDay = existing?.dayOfWeek ?? 'Hôm nay';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Cập nhật bài tập' : 'Thêm bài tập mới'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      labelText: 'Calo tiêu thụ (kcal)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: 'Lịch tập'),
                    items:
                        [
                              'Hôm nay',
                              'Thứ 2 - Thứ 5',
                              'Thứ 3 - Thứ 6',
                              'Thứ 4 - Thứ 7',
                              'Mỗi ngày',
                            ]
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedDay = val!),
                  ),
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final provider = Provider.of<WorkoutProvider>(
                    context,
                    listen: false,
                  );
                  final exerciseObj = Exercise(
                    id: isEditing
                        ? existing.id
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text.trim(),
                    category: selectedCategory,
                    sets: int.tryParse(setsCtrl.text) ?? 3,
                    reps: int.tryParse(repsCtrl.text) ?? 10,
                    calories: int.tryParse(calCtrl.text) ?? 100,
                    dayOfWeek: selectedDay,
                    notes: notesCtrl.text.trim(),
                    imagePath: isEditing ? existing.imagePath : '',
                    isCompleted: isEditing ? existing.isCompleted : false,
                    createdAt: isEditing ? existing.createdAt : null,
                  );

                  if (isEditing) {
                    provider.updateExercise(exerciseObj);
                  } else {
                    provider.addExercise(exerciseObj);
                  }

                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Đã cập nhật "${exerciseObj.title}"!'
                            : 'Đã thêm "${exerciseObj.title}" vào lịch tập!',
                      ),
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

  // Hộp thoại AlertDialog xác nhận trước khi xóa (Bài 4 - Visual Feedback)
  void _confirmDelete(
    BuildContext context,
    WorkoutProvider provider,
    Exercise item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài tập "${item.title}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.deleteExercise(item.id);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa "${item.title}"'),
                  action: SnackBarAction(
                    label: 'Hoàn tác (Undo)',
                    onPressed: () => provider.addExercise(item),
                  ),
                ),
              );
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
      child: Scaffold(
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
        body: Consumer<WorkoutProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiến độ hoàn thành: ${provider.completedCount}/${provider.exercises.length} bài',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '🔥 ${provider.totalCaloriesBurned} kcal',
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
                ),
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
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showExerciseFormDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm bài tập'),
        ),
      ),
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    WorkoutProvider provider,
    String filter,
  ) {
    final list = filter == 'Tất cả'
        ? provider.exercises
        : provider.exercises.where((e) => e.category == filter).toList();

    if (list.isEmpty) {
      return const Center(child: Text('Chưa có bài tập nào trong mục này.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final item = list[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            // Bấm vào dòng bài tập sẽ chuyển sang Màn hình Chi tiết (Bài 3 - Navigator.push)
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(exercise: item),
                ),
              );
            },
            leading: Checkbox(
              value: item.isCompleted,
              activeColor: Colors.teal,
              onChanged: (_) => provider.toggleComplete(item.id),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              '${item.category} • ${item.sets} hiệp x ${item.reps} lần • ${item.calories} kcal\n📅 ${item.dayOfWeek}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Sửa bài tập',
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () =>
                      _showExerciseFormDialog(context, existing: item),
                ),
                IconButton(
                  tooltip: 'Xóa bài tập',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, provider, item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
