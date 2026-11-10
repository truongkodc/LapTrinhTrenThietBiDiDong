import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/workout_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => WorkoutProvider()..loadData(),
      child: const FitPlanApp(),
    ),
  );
}
