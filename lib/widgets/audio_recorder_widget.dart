import 'package:flutter/material.dart';
import 'dart:async';
import '../services/audio_service.dart';

enum RecordingState { idle, recording, paused }

class AudioRecorderWidget extends StatefulWidget {
  final Function(String path) onRecordingComplete;

  const AudioRecorderWidget({Key? key, required this.onRecordingComplete})
    : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();

  RecordingState _recordingState = RecordingState.idle;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _resetTimer() {
    _stopTimer();
    _recordingDuration = Duration.zero;
  }

  void _continueTimer() {
    final currentSeconds = _recordingDuration.inSeconds;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: currentSeconds + timer.tick);
      });
    });
  }

  Future<void> _startRecording() async {
    final path = await _audioService.startRecording();
    if (path != null) {
      setState(() {
        _recordingState = RecordingState.recording;
      });
      _startTimer();
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _pauseRecording() async {
    final success = await _audioService.pauseRecording();
    if (success) {
      setState(() {
        _recordingState = RecordingState.paused;
      });
      _stopTimer();
      _pulseController.stop();
    }
  }

  Future<void> _resumeRecording() async {
    final success = await _audioService.resumeRecording();
    if (success) {
      setState(() {
        _recordingState = RecordingState.recording;
      });
      _continueTimer();
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioService.stopRecording();
    if (path != null) {
      setState(() {
        _recordingState = RecordingState.idle;
      });
      _resetTimer();
      _pulseController.stop();
      _pulseController.reset();
      widget.onRecordingComplete(path);
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    setState(() {
      _recordingState = RecordingState.idle;
    });
    _resetTimer();
    _pulseController.stop();
    _pulseController.reset();
  }

  Color _getButtonColor() {
    switch (_recordingState) {
      case RecordingState.idle:
        return Colors.blue;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.paused:
        return Colors.orange;
    }
  }

  IconData _getButtonIcon() {
    switch (_recordingState) {
      case RecordingState.idle:
        return Icons.mic;
      case RecordingState.recording:
        return Icons.stop;
      case RecordingState.paused:
        return Icons.play_arrow;
    }
  }

  String _getStatusText() {
    switch (_recordingState) {
      case RecordingState.idle:
        return '녹음 시작하기';
      case RecordingState.recording:
        return '녹음 중...';
      case RecordingState.paused:
        return '일시정지 중';
    }
  }

  void _onMainButtonPressed() {
    switch (_recordingState) {
      case RecordingState.idle:
        _startRecording();
        break;
      case RecordingState.recording:
        _stopRecording();
        break;
      case RecordingState.paused:
        _resumeRecording();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // 녹음 시간 표시
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // 상태 텍스트
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Text(
              _getStatusText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          // 버튼 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 취소 버튼 (녹음 중일 때만 표시)
              if (_recordingState != RecordingState.idle)
                FloatingActionButton(
                  onPressed: _cancelRecording,
                  backgroundColor: Colors.grey,
                  heroTag: "cancel",
                  child: const Icon(Icons.clear, color: Colors.white),
                )
              else
                const SizedBox(width: 56), // 공간 유지
              // 메인 녹음 버튼
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _recordingState == RecordingState.recording
                        ? _pulseAnimation.value
                        : 1.0,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: FloatingActionButton(
                        onPressed: _onMainButtonPressed,
                        backgroundColor: _getButtonColor(),
                        heroTag: "main",
                        child: Icon(
                          _getButtonIcon(),
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 일시정지 버튼 (녹음 중일 때만 표시)
              if (_recordingState == RecordingState.recording)
                FloatingActionButton(
                  onPressed: _pauseRecording,
                  backgroundColor: Colors.orange,
                  heroTag: "pause",
                  child: const Icon(Icons.pause, color: Colors.white),
                )
              else
                const SizedBox(width: 56), // 공간 유지
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
