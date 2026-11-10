import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/workout_provider.dart';
import 'bmi_and_stats_tab.dart';
import 'profile_tab.dart';
import 'workout_plan_tab.dart';

// =========================================================
// 4. MÀN HÌNH DASHBOARD & BOTTOM NAVIGATION BAR (BÀI 3 & 4)
// =========================================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const List<Widget> _pages = [
    WorkoutPlanTab(),
    BmiAndStatsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final currentIndex = provider.dashboardTabIndex.clamp(
          0,
          _pages.length - 1,
        );
        return Scaffold(
          body: _pages[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            selectedItemColor: AppTheme.primaryColor,
            onTap: provider.setDashboardTabIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Kế hoạch tập',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Thống kê & BMI',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Cá nhân',
              ),
            ],
          ),
        );
      },
    );
  }
}
