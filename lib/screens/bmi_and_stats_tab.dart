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
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<WorkoutProvider>(context, listen: false);
    if (WorkoutProvider.isValidBodyMetricValue(p.weight)) {
      _weightCtrl.text = p.weight.toString();
    }
    if (WorkoutProvider.isValidBodyMetricValue(p.height)) {
      _heightCtrl.text = p.height.toString();
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  String _bmiEvaluate(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân (Cần tăng cơ & dinh dưỡng)';
    if (bmi < 24.9) return 'Bình thường (Duy trì lịch tập đều đặn)';
    if (bmi < 29.9) return 'Thừa cân (Ưu tiên thêm bài tập Cardio)';
    return 'Béo phì (Cần kết hợp HIIT và thâm hụt Calo)';
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập cân nặng (kg)';
    }
    final parsed = WorkoutProvider.tryParseBodyMetric(value);
    if (parsed == null) {
      return 'Cân nặng phải là số hợp lệ > 0 (dùng dấu chấm hoặc phẩy cho phần thập phân)';
    }
    final parsedHeight = WorkoutProvider.tryParseBodyMetric(_heightCtrl.text);
    if (parsedHeight != null &&
        WorkoutProvider.calculateValidBmi(parsed, parsedHeight) == null) {
      return 'Cân nặng và chiều cao không tính được chỉ số BMI hợp lệ';
    }
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập chiều cao (cm)';
    }
    final parsed = WorkoutProvider.tryParseBodyMetric(value);
    if (parsed == null) {
      return 'Chiều cao phải là số hợp lệ > 0 (dùng dấu chấm hoặc phẩy cho phần thập phân)';
    }
    final parsedWeight = WorkoutProvider.tryParseBodyMetric(_weightCtrl.text);
    if (parsedWeight != null &&
        WorkoutProvider.calculateValidBmi(parsedWeight, parsed) == null) {
      return 'Cân nặng và chiều cao không tính được chỉ số BMI hợp lệ';
    }
    return null;
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
          final validBmi = provider.validBmi;
          final dateText = DateUtilsHelper.formatDisplayDate(
            provider.selectedDate,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
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
                          if (validBmi != null) ...[
                            Text(
                              validBmi.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            Text(
                              _bmiEvaluate(validBmi),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 36,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Dữ liệu cân nặng hoặc chiều cao đang lưu không hợp lệ. Vui lòng nhập và cập nhật lại chỉ số bên dưới.',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('weight_input_field'),
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Cân nặng (kg)',
                            border: OutlineInputBorder(),
                            errorMaxLines: 3,
                          ),
                          validator: _validateWeight,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const Key('height_input_field'),
                          controller: _heightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Chiều cao (cm)',
                            border: OutlineInputBorder(),
                            errorMaxLines: 3,
                          ),
                          validator: _validateHeight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    key: const Key('update_bmi_button'),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            setState(() {
                              _isSaving = true;
                            });

                            try {
                              final ok = await provider
                                  .updateBodyMetricsFromInput(
                                    _weightCtrl.text,
                                    _heightCtrl.text,
                                  );
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
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isSaving = false;
                                });
                              }
                            }
                          },
                    icon: const Icon(Icons.calculate),
                    label: const Text('Cập nhật chỉ số cơ thể'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
