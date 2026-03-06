import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:skillaura/core/constants/app_router.dart';
import 'package:skillaura/core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue anyway - app can work without Firebase for now
  }

  runApp(const InternMatchApp());
}

class InternMatchApp extends StatelessWidget {
  const InternMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'InternMatch AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
