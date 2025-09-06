import 'package:flutter/material.dart';
import 'package:youtube_mini_video_demo/youtube_mini_video_sreen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: YoutubeMiniVideoSreen());
  }
}
