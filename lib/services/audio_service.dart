import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPaused = false;

  // 진폭 스트림을 위한 컨트롤러
  StreamController<double>? _amplitudeController;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  // 권한 확인
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // 녹음 상태 확인
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentRecordingPath => _currentRecordingPath;

  // 진폭 스트림 노출
  Stream<double>? get amplitudeStream => _amplitudeController?.stream;

  // 저장 경로 생성
  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    return '${directory.path}/$fileName';
  }

  // 녹음 시작
  Future<String?> startRecording() async {
    try {
      if (!await checkPermission()) {
        throw Exception('마이크 권한이 필요합니다');
      }

      final path = await _getRecordingPath();
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      await _audioRecorder.start(config, path: path);
      _currentRecordingPath = path;
      _isRecording = true;
      _isPaused = false;

      // 진폭 스트림 시작
      _startAmplitudeStream();

      return path;
    } catch (e) {
      print('녹음 시작 오류: $e');
      return null;
    }
  }

  // 녹음 일시정지
  Future<bool> pauseRecording() async {
    try {
      await _audioRecorder.pause();
      _isPaused = true;
      return true;
    } catch (e) {
      print('녹음 일시정지 오류: $e');
      return false;
    }
  }

  // 녹음 재개
  Future<bool> resumeRecording() async {
    try {
      await _audioRecorder.resume();
      _isPaused = false;
      return true;
    } catch (e) {
      print('녹음 재개 오류: $e');
      return false;
    }
  }

  // 녹음 중지
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      _isPaused = false;
      _currentRecordingPath = null;

      _stopAmplitudeStream();

      return path;
    } catch (e) {
      print('녹음 중지 오류: $e');
      return null;
    }
  }

  // 녹음 취소
  Future<void> cancelRecording() async {
    try {
      await _audioRecorder.stop();
      if (_currentRecordingPath != null &&
          File(_currentRecordingPath!).existsSync()) {
        await File(_currentRecordingPath!).delete();
      }
      _isRecording = false;
      _isPaused = false;
      _currentRecordingPath = null;

      // 진폭 스트림 중지
      _stopAmplitudeStream();
    } catch (e) {
      print('녹음 취소 오류: $e');
    }
  }

  // 진폭 스트림 시작
  void _startAmplitudeStream() {
    _amplitudeController = StreamController<double>.broadcast();

    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amplitude) {
          double rawAmp = amplitude.current;
          double normalizedAmp = (rawAmp + 60).clamp(0, 60) / 60;

          double sensitivityExp = 2.5;
          double curvedAmp = Math.pow(normalizedAmp, sensitivityExp).toDouble();

          _amplitudeController?.add(curvedAmp);

          double scaleValue = 1.0 + (curvedAmp * 3.0);

          sendToUnity(
            "Cube",
            "SetScaleFromAmplitude",
            scaleValue.toStringAsFixed(2),
          );
        });
  }

  // 진폭 스트림 중지
  void _stopAmplitudeStream() {
    _amplitudeSubscription?.cancel();
    _amplitudeController?.close();
    _amplitudeSubscription = null;
    _amplitudeController = null;
  }

  // 오디오 재생
  Future<void> playAudio(String path) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      print('재생 오류: $e');
    }
  }

  // 재생 중지
  Future<void> stopPlaying() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('재생 중지 오류: $e');
    }
  }

  // 리소스 해제
  void dispose() {
    _stopAmplitudeStream();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
