import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customer/screens/splash_screen.dart';
import 'core/app_router.dart';
import 'core/auth_state.dart';
import 'package:karmigo_app/core/app_translations.dart';
import 'theme/porter_theme.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthState.init();
  await AppTranslations.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const KarmigoApp(initialRoute: SplashScreen()),
    ),
  );
}

class KarmigoApp extends StatelessWidget {
  final Widget initialRoute;
  
  const KarmigoApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Note: Locale isn't natively supported by MaterialApp without localizationsDelegates, 
    // but for our simple implementation we might just rebuild or pass locale if we add delegates later.
    // For now we rely on our manual AppTranslations.get call in widgets.
    // To ensure rebuild on language change, we can listen to provider.
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
          title: 'Karmigo',
          debugShowCheckedModeBanner: false,
          theme: PorterTheme.themeData, // Light Theme
          home: initialRoute,
          onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
