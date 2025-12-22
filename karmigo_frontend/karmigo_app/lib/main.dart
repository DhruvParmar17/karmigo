import 'package:flutter/material.dart';
import 'customer/screens/login_screen.dart';

import 'core/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthState.init();
  runApp(const KarmigoApp());
}

class KarmigoApp extends StatelessWidget {
  const KarmigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karmigo',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
