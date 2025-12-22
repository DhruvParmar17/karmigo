import 'package:flutter/material.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';

void main() {
  runApp(const KarmigoApp());
}

class KarmigoApp extends StatelessWidget {
  const KarmigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karmigo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

