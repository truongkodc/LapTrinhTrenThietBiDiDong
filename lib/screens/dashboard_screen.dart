import 'package:flutter/material.dart';

import 'bmi_and_stats_tab.dart';
import 'profile_tab.dart';
import 'workout_plan_tab.dart';

// =========================================================
// 4. MÀN HÌNH DASHBOARD & BOTTOM NAVIGATION BAR (BÀI 3 & 4)
// =========================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    WorkoutPlanTab(),
    BmiAndStatsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: (index) => setState(() => _selectedIndex = index),
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
            label: 'Hồ sơ nhóm',
          ),
        ],
      ),
    );
  }
}

