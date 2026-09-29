import 'package:flutter/material.dart';

import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'state/app_controller.dart';

void main() {
  runApp(const MiniTubeApp());
}

class MiniTubeApp extends StatefulWidget {
  const MiniTubeApp({super.key});

  @override
  State<MiniTubeApp> createState() => _MiniTubeAppState();
}

class _MiniTubeAppState extends State<MiniTubeApp> {
  final controller = AppController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MiniTube',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return controller.autenticado
              ? HomePage(controller: controller)
              : AuthPage(controller: controller);
        },
      ),
    );
  }
}
