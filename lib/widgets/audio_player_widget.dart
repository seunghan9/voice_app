import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import '../models/audio_record.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final VoidCallback? onDelete;
  final VoidCallback? onBack;

  const AudioPlayerWidget({
    Key? key,
    required this.audioPath,
    this.onDelete,
    this.onBack,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    _audioPlayer = AudioPlayer();

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      setState(() => _playerState = state);
    });

    // 오디오 파일을 미리 로드하여 duration 정보를 가져온다
    _preloadAudio();
  }

  Future<void> _preloadAudio() async {
    try {
      await _audioPlayer.setSource(DeviceFileSource(widget.audioPath));
    } catch (e) {
      print('오디오 파일 로드 오류: $e');
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    await _audioPlayer.play(DeviceFileSource(widget.audioPath));
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String _getFileName() {
    return widget.audioPath.split('/').last.replaceAll('.m4a', '');
  }

  IconData _getPlayIcon() {
    switch (_playerState) {
      case PlayerState.playing:
        return Icons.pause;
      case PlayerState.paused:
      case PlayerState.stopped:
      case PlayerState.completed:
        return Icons.play_arrow;
      default:
        return Icons.play_arrow;
    }
  }

  void _onPlayPressed() {
    switch (_playerState) {
      case PlayerState.playing:
        _pause();
        break;
      case PlayerState.paused:
      case PlayerState.stopped:
      case PlayerState.completed:
        _play();
        break;
      default:
        _play();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 뒤로 가기 버튼
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              iconSize: 30,
            ),
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.audiotrack, size: 60, color: Colors.blue),
                const SizedBox(height: 15),
                Text(
                  _getFileName(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 재생 컨트롤
          Column(
            children: [
              // 진행 바
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    trackHeight: 4,
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Colors.blue,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 1.0,
                    value: _position.inMilliseconds.toDouble().clamp(
                      0.0,
                      _duration.inMilliseconds > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0,
                    ),
                    onChanged: (value) {
                      final position = Duration(milliseconds: value.toInt());
                      _seek(position);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 되감기 5초
                  FloatingActionButton(
                    onPressed: () {
                      final newPosition =
                          _position - const Duration(seconds: 5);
                      _seek(
                        newPosition > Duration.zero
                            ? newPosition
                            : Duration.zero,
                      );
                    },
                    backgroundColor: Colors.grey[300],
                    heroTag: "backward",
                    child: const Icon(Icons.replay_5, color: Colors.black87),
                  ),
                  // 빨리감기 5초
                  FloatingActionButton(
                    onPressed: () {
                      final newPosition =
                          _position + const Duration(seconds: 5);
                      _seek(newPosition < _duration ? newPosition : _duration);
                    },
                    backgroundColor: Colors.grey[300],
                    heroTag: "forward",
                    child: const Icon(Icons.forward_5, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 재생 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 정지
                  FloatingActionButton(
                    onPressed: _stop,
                    backgroundColor: Colors.red,
                    heroTag: "stop",
                    child: const Icon(Icons.stop, color: Colors.white),
                  ),
                  // 재생/일시정지
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: FloatingActionButton(
                      onPressed: _onPlayPressed,
                      backgroundColor: Colors.blue,
                      heroTag: "play",
                      child: Icon(
                        _getPlayIcon(),
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // 삭제
                  if (widget.onDelete != null)
                    FloatingActionButton(
                      onPressed: () {
                        _showDeleteDialog();
                      },
                      backgroundColor: Colors.red[300],
                      heroTag: "delete",
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('녹음 파일 삭제'),
          content: const Text('이 녹음 파일을 삭제하시겠습니까?\n삭제된 파일은 복구할 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('삭제'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete?.call();
              },
            ),
          ],
        );
      },
    );
  }
}
