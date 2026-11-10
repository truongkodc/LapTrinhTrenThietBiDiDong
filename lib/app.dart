import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'providers/workout_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_choice_screen.dart';

class FitPlanApp extends StatelessWidget {
  const FitPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPlan HUTECH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          final bool disableAnimations =
              MediaQuery.maybeDisableAnimationsOf(context) ?? false;
          final Widget activeScreen;
          if (!provider.isLoggedIn) {
            activeScreen = const LoginScreen(key: ValueKey('login_screen'));
          } else if (provider.showPostLoginWelcome) {
            activeScreen = const WelcomeChoiceScreen(
              key: ValueKey('welcome_screen'),
            );
          } else {
            activeScreen = const DashboardScreen(
              key: ValueKey('dashboard_screen'),
            );
          }

          return AnimatedSwitcher(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              if (disableAnimations) {
                return child;
              }
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slideAnimation, child: child),
              );
            },
            child: activeScreen,
          );
        },
      ),
    );
  }
}
