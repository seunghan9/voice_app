class AudioRecord {
  final String path;
  final DateTime recordedAt;
  final Duration duration;
  final String fileName;

  AudioRecord({
    required this.path,
    required this.recordedAt,
    required this.duration,
    required this.fileName,
  });

  // 파일 크기 가져오기
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 파일명 (확장자 제외)
  String get displayName {
    return fileName.replaceAll('.m4a', '');
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'recordedAt': recordedAt.toIso8601String(),
      'duration': duration.inMilliseconds,
      'fileName': fileName,
    };
  }

  factory AudioRecord.fromJson(Map<String, dynamic> json) {
    return AudioRecord(
      path: json['path'],
      recordedAt: DateTime.parse(json['recordedAt']),
      duration: Duration(milliseconds: json['duration']),
      fileName: json['fileName'],
    );
  }
}
