import 'package:flutter/material.dart';
import 'package:vada_analyser/Presentation/screen_splash.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScreenSplash()
    );
  }
}