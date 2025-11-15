import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:gemini_chat/home_screen.dart';
import 'package:gemini_chat/widget/const.dart';

void main() {
  Gemini.init(apiKey: GEMINI_API_KRY);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gemini Chat',
      home: HomeScreen()
    );
  }
}
