import 'package:flutter/material.dart';

import '../models/exercise.dart';

// =========================================================
// 6. MÀN HÌNH CHI TIẾT BÀI TẬP (BÀI 3 - NAVIGATOR PUSH/POP)
// =========================================================
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
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
              '📅 Lịch tập: ${exercise.dayOfWeek}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '🔁 Khối lượng: ${exercise.sets} hiệp x ${exercise.reps} lần',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '🔥 Năng lượng tiêu hao: ${exercise.calories} kcal',
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
