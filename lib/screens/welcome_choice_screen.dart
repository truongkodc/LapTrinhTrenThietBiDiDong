import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/workout_provider.dart';

// =========================================================
// MÀN HÌNH CHÀO & LỰA CHỌN SAU ĐĂNG NHẬP
// Hiển thị sau mỗi lần đăng nhập thành công; cho phép người dùng
// chọn điểm bắt đầu hoặc nhấn "Vào ứng dụng".
// =========================================================
class WelcomeChoiceScreen extends StatelessWidget {
  const WelcomeChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final email = provider.userEmail.isNotEmpty ? provider.userEmail : 'bạn';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightStatusBarStyle,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: AppTheme.headerTealGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppTheme.amberAccentColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_run,
                              size: 30,
                              color: AppTheme.amberOnColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Xin chào, $email!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE0F2F1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Bạn muốn bắt đầu từ đâu?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Chọn một mục bên dưới để mở nhanh phần bạn cần trong FitPlan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFFD8EEEA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WelcomeOptionCard(
                      cardKey: const Key('welcome_option_today_plan'),
                      icon: Icons.calendar_today,
                      title: 'Kế hoạch hôm nay',
                      subtitle: 'Xem danh sách bài tập và đánh dấu hoàn thành cho hôm nay.',
                      badgeText: 'Gợi ý',
                      isHighlighted: true,
                      onTap: provider.openTodayPlanFromWelcome,
                    ),
                    const SizedBox(height: 10),
                    _WelcomeOptionCard(
                      cardKey: const Key('welcome_option_today_stats'),
                      icon: Icons.bar_chart,
                      title: 'Xem tiến độ',
                      subtitle: 'Theo dõi số bài đã hoàn thành và lượng kcal ước tính hôm nay.',
                      onTap: provider.openTodayStatsFromWelcome,
                    ),
                    const SizedBox(height: 10),
                    _WelcomeOptionCard(
                      cardKey: const Key('welcome_option_update_bmi'),
                      icon: Icons.monitor_weight_outlined,
                      title: 'Cập nhật chỉ số cơ thể',
                      subtitle: 'Nhập cân nặng, chiều cao để tính và theo dõi chỉ số BMI.',
                      onTap: provider.openBodyMetricsUpdateFromWelcome,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        key: const Key('welcome_enter_app_button'),
                        onPressed: provider.openTodayPlanFromWelcome,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Vào ứng dụng'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeOptionCard extends StatefulWidget {
  final Key cardKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _WelcomeOptionCard({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
    this.isHighlighted = false,
  });

  @override
  State<_WelcomeOptionCard> createState() => _WelcomeOptionCardState();
}

class _WelcomeOptionCardState extends State<_WelcomeOptionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Duration animDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 120);

    return AnimatedScale(
      scale: (_isPressed && !disableAnimations) ? 0.98 : 1.0,
      duration: animDuration,
      child: Card(
        color: widget.isHighlighted
            ? AppTheme.mintSurfaceColor
            : AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          side: BorderSide(
            color: widget.isHighlighted
                ? AppTheme.primaryColor.withValues(alpha: 0.55)
                : const Color(0xFFD5E4E2),
            width: widget.isHighlighted ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          key: widget.cardKey,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          onHighlightChanged: (value) {
            if (_isPressed != value) {
              setState(() {
                _isPressed = value;
              });
            }
          },
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isHighlighted
                        ? AppTheme.amberAccentColor
                        : AppTheme.mintSurfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.isHighlighted
                        ? AppTheme.amberOnColor
                        : AppTheme.primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (widget.badgeText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.amberAccentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.badgeText!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.amberOnColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
