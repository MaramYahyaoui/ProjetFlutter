import 'package:devmob_edulycee/presentation/pages/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ThemeController - gère le thème clair/sombre
        ChangeNotifierProvider(create: (_) => ThemeController()),
        // AuthController - gère l'authentification et l'état utilisateur
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          debugPrint('🎨 Theme Mode: ${themeController.isDarkMode ? "DARK" : "LIGHT"}');
          return MaterialApp(
            title: 'DevMob EduLycée',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            home: const AuthGate(), // Route protection
          );
        },
      ),
    );
  }
}
