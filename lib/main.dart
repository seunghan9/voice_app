import 'package:flutter/material.dart';
import 'screens/voice_recorder_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '음성 녹음 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VoiceRecorderScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
