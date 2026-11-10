import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/workout_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

class FitPlanApp extends StatelessWidget {
  const FitPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPlan HUTECH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          return provider.isLoggedIn
              ? const DashboardScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}

