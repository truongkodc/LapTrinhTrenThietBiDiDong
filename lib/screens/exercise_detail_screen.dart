import 'package:flutter/material.dart';

import '../app_theme.dart';
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
    final Color catColor = AppTheme.categoryColor(exercise.category);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi Tiết Bài Tập')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppTheme.categoryIcon(exercise.category),
                        size: 30,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nhóm bài tập: ${exercise.category}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: catColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 Lịch tập: ${exercise.scheduleLabel}',
                      style: const TextStyle(
                        fontSize: 15.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (selectedDate != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '📌 Trạng thái ngày ${DateUtilsHelper.formatDisplayDate(selectedDate!)}: ${completed ? "Đã hoàn thành" : "Chưa hoàn thành"}',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: completed
                              ? AppTheme.primaryColor
                              : AppTheme.warningColor,
                        ),
                      ),
                    ],
                    if (exercise.legacyCompletedWithoutDate) ...[
                      const SizedBox(height: 10),
                      const Text(
                        '✓ Đã hoàn thành trước đây',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Text(
                      '🔁 Khối lượng: ${exercise.volumeLabel}',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '🔥 Năng lượng tiêu hao (ước tính): ~${exercise.calories} kcal',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentCaloriesColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hướng dẫn kỹ thuật:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.notes.isEmpty
                          ? 'Chưa có ghi chú kỹ thuật cho bài tập này.'
                          : exercise.notes,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
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
