import 'package:flutter/material.dart';

import '../helpers/date_utils_helper.dart';
import '../models/exercise.dart';

// =========================================================
// 6. MÀN HÌNH CHI TIẾT BÀI TẬP (BÀI 3 - NAVIGATOR PUSH/POP)
// =========================================================
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  final DateTime? selectedDate;
  final bool? isCompletedOnDate;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.selectedDate,
    this.isCompletedOnDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool completed = isCompletedOnDate ?? exercise.isCompleted;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi Tiết Bài Tập')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.teal.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.fitness_center,
                  size: 40,
                  color: Colors.teal,
                ),
                title: Text(
                  exercise.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Nhóm bài tập: ${exercise.category}'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '📅 Lịch tập: ${exercise.scheduleLabel}',
              style: const TextStyle(fontSize: 16),
            ),
            if (selectedDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '📌 Trạng thái ngày ${DateUtilsHelper.formatDisplayDate(selectedDate!)}: ${completed ? "Đã hoàn thành" : "Chưa hoàn thành"}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: completed ? Colors.teal : Colors.orange.shade800,
                ),
              ),
            ],
            if (exercise.legacyCompletedWithoutDate) ...[
              const SizedBox(height: 8),
              const Text(
                '✓ Đã hoàn thành trước đây (dữ liệu phiên bản trước)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.teal,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '🔁 Khối lượng: ${exercise.sets} hiệp x ${exercise.reps} lần',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '🔥 Năng lượng tiêu hao (ước tính): ~${exercise.calories} kcal',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 32),
            const Text(
              'Hướng dẫn kỹ thuật:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(exercise.notes, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại danh sách'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
