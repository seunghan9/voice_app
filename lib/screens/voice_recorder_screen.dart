import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/audio_player_widget.dart';

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({Key? key}) : super(key: key);

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen> {
  String? _recordedAudioPath;
  bool _showPlayer = false;

  void _onRecordingComplete(String path) {
    setState(() {
      _recordedAudioPath = path;
      _showPlayer = true;
    });
  }

  void _onBackToRecorder() {
    setState(() {
      _showPlayer = false;
    });
  }

  void _onDeleteRecording() {
    setState(() {
      _recordedAudioPath = null;
      _showPlayer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _showPlayer ? '녹음 재생' : '음성 녹음',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: _showPlayer && _recordedAudioPath != null
                ? AudioPlayerWidget(
                    audioPath: _recordedAudioPath!,
                    onBack: _onBackToRecorder,
                    onDelete: _onDeleteRecording,
                  )
                : AudioRecorderWidget(
                    onRecordingComplete: _onRecordingComplete,
                  ),
          ),
        ],
      ),
    );
  }
}
