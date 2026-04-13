import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';

void main() async {
  try {
    debugPrint('=== ETHAPE 1: Démarrage de Flutter ===');
    WidgetsFlutterBinding.ensureInitialized();
    
    // Catch global Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('=== ERREUR FLUTTER INTERNE ===');
      debugPrint(details.exceptionAsString());
      debugPrint(details.stack.toString());
    };

    // Catch asynchronous Dart errors
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('=== ERREUR ASYNCHRONE ===');
      debugPrint(error.toString());
      debugPrint(stack.toString());
      return true;
    };

    // Replace the default grey screen with a readable error message
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.red.shade900,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'CRASH INTERFACE :\n${details.exceptionAsString()}\n\n${details.stack}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    };

    debugPrint('=== ETHAPE 2: Initialisation de Supabase ===');
    await SupabaseConfig.initialize();
    
    debugPrint('=== ETHAPE 3: Configuration de Timeago ===');
    timeago.setLocaleMessages('fr', timeago.FrMessages());

    debugPrint('=== ETHAPE 4: Lancement de runApp ===');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('=== ERREUR FATALE ===');
    debugPrint(e.toString());
    debugPrint(stackTrace.toString());
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Text(
                'Erreur fatale de démarrage :\n\n$e\n\n$stackTrace',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KHEDMAA - La plateforme N1 en Tunisie pour les etudiants',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
