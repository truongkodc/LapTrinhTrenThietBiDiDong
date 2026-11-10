import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../helpers/date_utils_helper.dart';
import '../helpers/plan_suggestion_helper.dart';
import '../providers/workout_provider.dart';

// =========================================================
// MÀN HÌNH GỢI Ý KẾ HOẠCH TẬP LUYỆN THEO QUY TẮC CỐ ĐỊNH
// Cho phép chọn mục tiêu + các thứ tập -> Xem gợi ý ->
// Bỏ chọn bài không muốn -> Thêm vào kế hoạch (bắt đầu từ hôm nay).
// =========================================================
class PlanSuggestionScreen extends StatefulWidget {
  const PlanSuggestionScreen({super.key});

  @override
  State<PlanSuggestionScreen> createState() => _PlanSuggestionScreenState();
}

class _PlanSuggestionScreenState extends State<PlanSuggestionScreen> {
  String _selectedGoal = SuggestionGoals.muscleGain;
  List<int> _selectedWeekdays = <int>[
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  ];

  PlanSuggestionPreview? _preview;
  Set<String> _selectedTemplateCodes = <String>{};
  bool _isPreviewStale = false;

  String? _weekdayValidationError;
  String? _templateSelectionError;
  String? _submitError;
  bool _isSubmitting = false;

  void _onGoalChanged(String goal) {
    if (_isSubmitting || _selectedGoal == goal) return;
    setState(() {
      _selectedGoal = goal;
      _submitError = null;
      if (_preview != null) {
        _isPreviewStale = true;
      }
    });
  }

  void _toggleWeekday(int weekday, bool selected) {
    if (_isSubmitting) return;
    setState(() {
      if (selected) {
        if (!_selectedWeekdays.contains(weekday)) {
          _selectedWeekdays.add(weekday);
          _selectedWeekdays.sort();
        }
      } else {
        _selectedWeekdays.remove(weekday);
      }
      _weekdayValidationError = null;
      _submitError = null;
      if (_preview != null) {
        _isPreviewStale = true;
      }
    });
  }

  void _selectEveryDay() {
    if (_isSubmitting) return;
    setState(() {
      _selectedWeekdays = <int>[1, 2, 3, 4, 5, 6, 7];
      _weekdayValidationError = null;
      _submitError = null;
      if (_preview != null) {
        _isPreviewStale = true;
      }
    });
  }

  void _generatePreview(WorkoutProvider provider) {
    if (_isSubmitting) return;
    final normalizedDays = PlanSuggestionHelper.normalizeWeekdays(
      _selectedWeekdays,
    );
    if (normalizedDays.isEmpty) {
      setState(() {
        _weekdayValidationError = 'Vui lòng chọn ít nhất một thứ trong tuần.';
      });
      return;
    }

    final preview = PlanSuggestionHelper.buildPreview(
      goal: _selectedGoal,
      repeatDays: normalizedDays,
      startDateKey: provider.todayDateKey,
    );

    setState(() {
      _preview = preview;
      _selectedTemplateCodes = preview.templates.map((t) => t.code).toSet();
      _isPreviewStale = false;
      _weekdayValidationError = null;
      _templateSelectionError = null;
      _submitError = null;
    });
  }

  void _toggleTemplateSelection(String code, bool selected) {
    if (_isSubmitting) return;
    setState(() {
      if (selected) {
        _selectedTemplateCodes.add(code);
      } else {
        _selectedTemplateCodes.remove(code);
      }
      _templateSelectionError = null;
      _submitError = null;
    });
  }

  Future<void> _confirmAddToPlan(WorkoutProvider provider) async {
    if (_isSubmitting) return;

    final normalizedDays = PlanSuggestionHelper.normalizeWeekdays(
      _selectedWeekdays,
    );
    if (normalizedDays.isEmpty) {
      setState(() {
        _weekdayValidationError = 'Vui lòng chọn ít nhất một thứ trong tuần.';
      });
      return;
    }

    if (_preview == null || _isPreviewStale) {
      setState(() {
        _templateSelectionError = 'Vui lòng nhấn "Xem gợi ý" để cập nhật bản xem trước trước khi thêm.';
      });
      return;
    }

    final keptTemplates = _preview!.templates
        .where((tpl) => _selectedTemplateCodes.contains(tpl.code))
        .toList();
    if (keptTemplates.isEmpty) {
      setState(() {
        _templateSelectionError =
            'Vui lòng giữ lại ít nhất một bài tập trước khi thêm vào kế hoạch.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _weekdayValidationError = null;
      _templateSelectionError = null;
      _submitError = null;
    });

    final result = await provider.addSuggestedExercises(
      selectedTemplates: keptTemplates,
      repeatDays: _preview!.repeatDays,
    );

    if (!mounted) return;

    if (result.success) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.summaryMessage),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final String errMsg =
          result.errorMessage ??
          provider.lastErrorMessage ??
          'Không thể lưu kế hoạch gợi ý. Vui lòng thử lại.';
      setState(() {
        _isSubmitting = false;
        _submitError = errMsg;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final todayDisplay = DateUtilsHelper.formatDisplayDateKey(
      provider.todayDateKey,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gợi Ý Kế Hoạch Tập'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ghi chú tham khảo trung thực
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.mintSurfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        PlanSuggestionHelper.referenceNotice,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bước 1: Chọn mục tiêu & các thứ tập
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '1. Chọn mục tiêu tập luyện',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SuggestionGoals.values.map((goal) {
                          final bool isSelected = _selectedGoal == goal;
                          return ChoiceChip(
                            key: Key('suggest_goal_chip_$goal'),
                            label: Text(
                              goal,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.amberOnColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.amberAccentColor,
                            backgroundColor: AppTheme.backgroundColor,
                            onSelected: _isSubmitting
                                ? null
                                : (_) => _onGoalChanged(goal),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        SuggestionGoals.descriptionForGoal(_selectedGoal),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              '2. Chọn các thứ muốn tập trong tuần',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const Key('suggest_every_day_button'),
                            onPressed: _isSubmitting ? null : _selectEveryDay,
                            child: const Text('Mỗi ngày'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(7, (idx) {
                          final weekday = idx + 1;
                          final isSelected = _selectedWeekdays.contains(
                            weekday,
                          );
                          return FilterChip(
                            key: Key('suggest_weekday_chip_$weekday'),
                            label: Text(
                              DateUtilsHelper.weekdayShortLabel(weekday),
                            ),
                            selected: isSelected,
                            onSelected: _isSubmitting
                                ? null
                                : (selected) =>
                                      _toggleWeekday(weekday, selected),
                          );
                        }),
                      ),
                      if (_weekdayValidationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _weekdayValidationError!,
                          key: const Key('suggest_weekday_error_text'),
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.event_repeat,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    PlanSuggestionHelper.scheduleRuleNotice,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ngày bắt đầu: $todayDisplay',
                              key: const Key('suggest_start_date_text'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          key: const Key('generate_suggestion_preview_button'),
                          onPressed: _isSubmitting
                              ? null
                              : () => _generatePreview(provider),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Xem gợi ý'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bước 2: Bản xem trước gợi ý
              if (_preview != null) ...[
                const SizedBox(height: 16),
                Card(
                  key: const Key('suggestion_preview_card'),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Bản xem trước kế hoạch mẫu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_isPreviewStale)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: const Text(
                              'Bạn vừa thay đổi mục tiêu hoặc thứ tập ở trên. Nhấn "Xem gợi ý" để tạo lại bản xem trước.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.mintSurfaceColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• Mục tiêu: ${_preview!.goal}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Các thứ tập: ${_preview!.repeatDaysLabel}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Ngày bắt đầu: ${_preview!.formattedStartDate}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tất cả bài tập được giữ lại bên dưới sẽ lặp hằng tuần vào các thứ đã chọn.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._preview!.templates.map((tpl) {
                          final bool isChecked = _selectedTemplateCodes
                              .contains(tpl.code);
                          final Color catColor = AppTheme.categoryColor(
                            tpl.category,
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? Colors.white
                                  : AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isChecked
                                    ? AppTheme.primaryColor.withValues(
                                        alpha: 0.45,
                                      )
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _isSubmitting
                                  ? null
                                  : () => _toggleTemplateSelection(
                                      tpl.code,
                                      !isChecked,
                                    ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  8,
                                  10,
                                  12,
                                  10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Checkbox(
                                          key: Key(
                                            'preview_template_checkbox_${tpl.code}',
                                          ),
                                          value: isChecked,
                                          activeColor: AppTheme.primaryColor,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: _isSubmitting
                                              ? null
                                              : (val) =>
                                                    _toggleTemplateSelection(
                                                      tpl.code,
                                                      val ?? false,
                                                    ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            tpl.title,
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        top: 4,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: catColor.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  tpl.category,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: catColor,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                tpl.volumeLabel,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '🔥 ~${tpl.calories} kcal (ước tính)',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  AppTheme.accentCaloriesColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tpl.notes,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        if (_templateSelectionError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _templateSelectionError!,
                            key: const Key('suggest_template_error_text'),
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (_submitError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _submitError!,
                            key: const Key('suggest_submit_error_text'),
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton(
                              key: const Key('cancel_plan_suggestion_button'),
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton.icon(
                              key: const Key(
                                'confirm_add_suggested_plan_button',
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _confirmAddToPlan(provider),
                              icon: const Icon(Icons.playlist_add_check),
                              label: Text(
                                _isSubmitting
                                    ? 'Đang thêm...'
                                    : 'Thêm vào kế hoạch',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
