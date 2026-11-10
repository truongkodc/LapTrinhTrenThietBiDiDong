import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils_helper.dart';
import '../providers/workout_provider.dart';

// =========================================================
// 7. TAB 2: TÍNH CHỈ SỐ BMI & THỐNG KÊ THEO NGÀY (BÀI 3 & BÀI 4)
// =========================================================
class BmiAndStatsTab extends StatefulWidget {
  const BmiAndStatsTab({super.key});

  @override
  State<BmiAndStatsTab> createState() => _BmiAndStatsTabState();
}

class _BmiAndStatsTabState extends State<BmiAndStatsTab> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = Provider.of<WorkoutProvider>(context, listen: false);
    _weightCtrl.text = p.weight.toString();
    _heightCtrl.text = p.height.toString();
  }

  String _bmiEvaluate(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân (Cần tăng cơ & dinh dưỡng)';
    if (bmi < 24.9) return 'Bình thường (Duy trì lịch tập đều đặn)';
    if (bmi < 29.9) return 'Thừa cân (Ưu tiên thêm bài tập Cardio)';
    return 'Béo phì (Cần kết hợp HIIT và thâm hụt Calo)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê & Chỉ Số Cơ Thể'),
        centerTitle: true,
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          final bmi = provider.bmi;
          final dateText = DateUtilsHelper.formatDisplayDate(
            provider.selectedDate,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'THỐNG KÊ NGÀY ĐANG CHỌN ($dateText)',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hoàn thành: ${provider.completedCount}/${provider.totalCountForSelectedDate} bài',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'CHỈ SỐ BMI HIỆN TẠI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bmi.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        Text(
                          _bmiEvaluate(bmi),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cân nặng (kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Chiều cao (cm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final w = double.tryParse(_weightCtrl.text) ?? 68.0;
                    final h = double.tryParse(_heightCtrl.text) ?? 172.0;
                    final ok = await provider.updateBodyMetrics(w, h);
                    if (!context.mounted) return;
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã cập nhật chỉ số BMI!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.lastErrorMessage ??
                                'Không thể lưu chỉ số BMI.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('Cập nhật chỉ số cơ thể'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
