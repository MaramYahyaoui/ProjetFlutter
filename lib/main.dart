import 'package:devmob_edulycee/presentation/pages/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';

const bool kForceLogout = bool.fromEnvironment(
  'FORCE_LOGOUT',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // DEV helper: démarre toujours sur Login quand FORCE_LOGOUT=true
  // Exemple: flutter run --dart-define=FORCE_LOGOUT=true
  if (kDebugMode && kForceLogout) {
    await FirebaseAuth.instance.signOut();
  }

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
          debugPrint(
            ' Theme Mode: ${themeController.isDarkMode ? "DARK" : "LIGHT"}',
          );
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
