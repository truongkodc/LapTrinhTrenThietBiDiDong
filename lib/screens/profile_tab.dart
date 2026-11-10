import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/workout_provider.dart';

// =========================================================
// 8. TAB 3: CÁ NHÂN & VỀ ỨNG DỤNG
// =========================================================
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isProcessingLogout = false;

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
                            Icons.verified_user,
                            size: 16,
                            color: AppTheme.amberOnColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.userEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Phiên làm việc cục bộ trên thiết bị',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
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
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Về ứng dụng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.fitness_center,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        'FitPlan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Ứng dụng lập kế hoạch tập thể dục theo ngày, theo dõi tiến độ hoàn thành và tính chỉ số BMI.',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.school, color: AppTheme.primaryColor),
                      title: Text(
                        'Thông tin môn học',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Môn: Lập trình trên thiết bị di động - HUTECH',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.phone_android,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        'Lưu trữ dữ liệu',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Lịch tập và kết quả được lưu trên thiết bị này.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
