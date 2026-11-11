import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
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
  final _bodyMetricsFormCardKey = GlobalKey();
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
    return WorkoutProvider.evaluateBmiDetail(bmi);
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

  Widget _buildWeightField() {
    return TextFormField(
      key: const Key('weight_input_field'),
      controller: _weightCtrl,
      enabled: !_isSaving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Cân nặng (kg)',
        errorMaxLines: 6,
      ),
      validator: _validateWeight,
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      key: const Key('height_input_field'),
      controller: _heightCtrl,
      enabled: !_isSaving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Chiều cao (cm)',
        errorMaxLines: 6,
      ),
      validator: _validateHeight,
    );
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
          if (provider.pendingScrollToBodyMetricsForm) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              provider.consumePendingScrollToBodyMetricsForm();
              final targetContext = _bodyMetricsFormCardKey.currentContext;
              if (targetContext != null) {
                final disableAnimations =
                    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
                Scrollable.ensureVisible(
                  targetContext,
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
          final validBmi = provider.validBmi;
          final dateText = DateUtilsHelper.formatDisplayDate(
            provider.selectedDate,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
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
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'THỐNG KÊ NGÀY ĐANG CHỌN ($dateText)',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Hoàn thành: ${provider.completedCount}/${provider.totalCountForSelectedDate} bài',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: provider.progressPercentage,
                            minHeight: 8,
                            color: AppTheme.primaryColor,
                            backgroundColor: AppTheme.surfaceTint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: AppTheme.surfaceTint,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const Text(
                            'CHỈ SỐ BMI HIỆN TẠI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (validBmi != null) ...[
                            Text(
                              validBmi.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bmiEvaluate(validBmi),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.warningColor,
                              size: 36,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Dữ liệu cân nặng hoặc chiều cao đang lưu không hợp lệ. Vui lòng nhập và cập nhật lại chỉ số bên dưới.',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    key: _bodyMetricsFormCardKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Cập nhật cân nặng & chiều cao',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final textScale = MediaQuery.textScalerOf(context)
                                  .scale(1.0);
                              final shouldStackVertically =
                                  constraints.maxWidth < 480 ||
                                  textScale > 1.15;
                              if (shouldStackVertically) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildWeightField(),
                                    const SizedBox(height: 12),
                                    _buildHeightField(),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildWeightField()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildHeightField()),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
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
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Đã cập nhật chỉ số BMI!',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.primaryColor,
                                                ),
                                              );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                provider.lastErrorMessage ??
                                                    'Không thể lưu chỉ số BMI.',
                                              ),
                                              backgroundColor:
                                                  AppTheme.errorColor,
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
                              label: Text(
                                _isSaving
                                    ? 'Đang cập nhật...'
                                    : 'Cập nhật chỉ số cơ thể',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
