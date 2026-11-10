import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/workout_provider.dart';

// =========================================================
// 8. TAB 3: CÁ NHÂN, CHỈ SỐ CƠ THỂ, HƯỚNG DẪN & VỀ ỨNG DỤNG
// =========================================================
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isProcessingLogout = false;

  Future<void> _showEditDisplayNameDialog(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: provider.hasCustomDisplayName ? provider.customDisplayName : '',
    );
    bool isSaving = false;
    String? saveErrorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: const Text('Chỉnh sửa tên hiển thị'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập tên hiển thị cho hồ sơ cục bộ trên thiết bị (từ 1 đến 50 ký tự).',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('display_name_input_field'),
                    controller: nameController,
                    enabled: !isSaving,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      hintText: 'Ví dụ: Minh Anh',
                      prefixIcon: Icon(Icons.badge_outlined),
                      errorMaxLines: 3,
                    ),
                    validator: WorkoutProvider.validateDisplayName,
                    onChanged: (_) {
                      if (saveErrorText != null) {
                        setDialogState(() {
                          saveErrorText = null;
                        });
                      }
                    },
                  ),
                  if (saveErrorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      saveErrorText!,
                      key: const Key('display_name_save_error_text'),
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              key: const Key('cancel_display_name_button'),
              onPressed: isSaving
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              key: const Key('save_display_name_button'),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      setDialogState(() {
                        isSaving = true;
                        saveErrorText = null;
                      });

                      final bool ok = await provider.updateDisplayName(
                        nameController.text,
                      );
                      if (!dialogContext.mounted) return;

                      if (ok) {
                        Navigator.of(dialogContext).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã lưu tên hiển thị!'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        }
                      } else {
                        final String errMsg =
                            provider.lastErrorMessage ??
                            'Không thể lưu tên hiển thị. Vui lòng thử lại.';
                        setDialogState(() {
                          isSaving = false;
                          saveErrorText = errMsg;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errMsg),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      }
                    },
              child: Text(isSaving ? 'Đang lưu...' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUsageGuideBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (sheetContext, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Hướng dẫn sử dụng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('close_usage_guide_button'),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    _GuideItem(
                      icon: Icons.event_repeat,
                      title: '1. Thêm bài tập và chọn kiểu lịch',
                      description: 'Nhấn nút "Thêm bài tập" ở tab Kế hoạch tập, chọn tập một lần vào ngày cụ thể hoặc lặp hằng tuần theo các thứ đã chọn.',
                    ),
                    _GuideItem(
                      icon: Icons.timer_outlined,
                      title: '2. Chọn đơn vị cho mỗi hiệp',
                      description: 'Mỗi bài tập hỗ trợ 3 đơn vị: lần, giây hoặc phút. Nhập số hiệp và số lượng mỗi hiệp là số nguyên dương.',
                    ),
                    _GuideItem(
                      icon: Icons.fact_check_outlined,
                      title: '3. Chọn ngày xem lịch và đánh dấu hoàn thành',
                      description: 'Chuyển ngày trên thanh lịch để xem các bài cần tập. Chỉ đánh dấu hoàn thành cho hôm nay hoặc ngày đã qua; không đánh dấu ngày tương lai.',
                    ),
                    _GuideItem(
                      icon: Icons.history_edu_outlined,
                      title: '4. Giữ nguyên thông tin khi hoàn thành',
                      description: 'Kết quả hoàn thành đã lưu giữ lại thông tin bài tập (tên, khối lượng, kcal ước tính) tại đúng thời điểm hoàn thành.',
                    ),
                    _GuideItem(
                      icon: Icons.delete_sweep_outlined,
                      title: '5. Ngừng lịch và Hoàn tác',
                      description: 'Ngừng lịch bài tập từ hôm nay sẽ giữ lại các kết quả đã hoàn thành trước đó. Bạn có thể nhấn "Hoàn tác (Undo)" khi thông báo còn hiển thị.',
                    ),
                    _GuideItem(
                      icon: Icons.save_alt_outlined,
                      title: '6. Lưu trữ cục bộ trên thiết bị',
                      description: 'Dữ liệu hiện được lưu cục bộ trên thiết bị này. Khi đăng xuất, lịch tập, lịch sử hoàn thành, tên hiển thị và chỉ số BMI không bị xóa.',
                    ),
                    _GuideItem(
                      icon: Icons.auto_awesome_outlined,
                      title: '7. Gợi ý kế hoạch tập mẫu',
                      description: 'Nhấn "Gợi ý kế hoạch" ở tab Kế hoạch tập, chọn mục tiêu và các thứ muốn tập để xem trước và thêm bộ bài tập mẫu lặp hằng tuần từ hôm nay.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutAppBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Về ứng dụng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('close_about_app_button'),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.fitness_center, color: AppTheme.primaryColor),
              title: Text(
                'FitPlan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Ứng dụng lập kế hoạch tập thể dục theo ngày, theo dõi tiến độ hoàn thành và tính chỉ số BMI.',
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.school, color: AppTheme.primaryColor),
              title: Text(
                'Thông tin môn học',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Môn: Lập trình trên thiết bị di động - HUTECH'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone_android, color: AppTheme.primaryColor),
              title: Text(
                'Lưu trữ dữ liệu',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Lịch tập và kết quả được lưu trên thiết bị này.'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndLogout(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    if (_isProcessingLogout) return;

    bool dialogBusy = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi phiên hiện tại không?\n\nLịch tập, lịch sử hoàn thành và chỉ số BMI trên thiết bị vẫn được giữ nguyên.',
          ),
          actions: [
            TextButton(
              key: const Key('cancel_logout_button'),
              onPressed: dialogBusy
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              key: const Key('confirm_logout_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              onPressed: dialogBusy
                  ? null
                  : () async {
                      setDialogState(() {
                        dialogBusy = true;
                      });
                      if (mounted) {
                        setState(() {
                          _isProcessingLogout = true;
                        });
                      }

                      try {
                        final ok = await provider.logout();
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (!context.mounted) return;

                        if (ok) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        } else {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.lastErrorMessage ?? 'Không thể lưu trạng thái đăng xuất. Vui lòng thử lại.',
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isProcessingLogout = false;
                          });
                        }
                      }
                    },
              child: Text(dialogBusy ? 'Đang xử lý...' : 'Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cá Nhân'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HỒ SƠ CÁ NHÂN
            Card(
              color: AppTheme.mintSurfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(
                            Icons.person,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppTheme.amberAccentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: AppTheme.amberOnColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.displayName,
                      key: const Key('profile_display_name_text'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.userEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hồ sơ cục bộ trên thiết bị này',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('edit_display_name_button'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () =>
                          _showEditDisplayNameDialog(context, provider),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Chỉnh sửa tên'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. THẺ CHỈ SỐ CƠ THỂ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.monitor_weight_outlined,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chỉ số cơ thể',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _BodyMetricTile(
                          label: 'Cân nặng',
                          value: provider.formattedWeight,
                          valueKey: const Key('profile_weight_value'),
                        ),
                        _BodyMetricTile(
                          label: 'Chiều cao',
                          value: provider.formattedHeight,
                          valueKey: const Key('profile_height_value'),
                        ),
                        _BodyMetricTile(
                          label: 'BMI',
                          value: provider.formattedBmi,
                          valueKey: const Key('profile_bmi_value'),
                          highlight: provider.hasValidBodyMetrics,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        key: const Key('profile_update_bmi_button'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          provider.openBodyMetricsUpdateFromProfile();
                        },
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Cập nhật chỉ số'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. MỤC HƯỚNG DẪN SỬ DỤNG
            Card(
              child: InkWell(
                key: const Key('open_usage_guide_tile'),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                onTap: () => _showUsageGuideBottomSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.mintSurfaceColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_outlined,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hướng dẫn sử dụng',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cách lập lịch tập, đánh dấu hoàn thành và lưu dữ liệu',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4. THU GỌN VỀ ỨNG DỤNG
            Card(
              child: InkWell(
                key: const Key('open_about_app_tile'),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                onTap: () => _showAboutAppBottomSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.mintSurfaceColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Về ứng dụng',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Thông tin FitPlan, môn học HUTECH và lưu trữ cục bộ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. ĐĂNG XUẤT
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('logout_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(
                    color: AppTheme.errorColor,
                    width: 1.4,
                  ),
                ),
                onPressed: _isProcessingLogout
                    ? null
                    : () => _confirmAndLogout(context, provider),
                icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                label: Text(
                  _isProcessingLogout ? 'Đang xử lý...' : 'Đăng xuất',
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;
  final bool highlight;

  const _BodyMetricTile({
    required this.label,
    required this.value,
    required this.valueKey,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.mintSurfaceColor : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuideItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.mintSurfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
