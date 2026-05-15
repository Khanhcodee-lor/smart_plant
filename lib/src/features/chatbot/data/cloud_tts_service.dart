import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service đọc văn bản bằng giọng nói qua Google Cloud Text-to-Speech API.
/// Hoạt động trên MỌI thiết bị, không phụ thuộc vào TTS engine trên máy.
class CloudTtsService {
  final AudioPlayer _player = AudioPlayer();
  bool _isSpeaking = false;
  bool _disposed = false;
  VoidCallback? onStart;
  VoidCallback? onComplete;

  CloudTtsService() {
    _player.onPlayerStateChanged.listen((state) {
      if (_disposed) return;
      if (state == PlayerState.playing) {
        _isSpeaking = true;
        onStart?.call();
      } else if (state == PlayerState.completed ||
          state == PlayerState.stopped) {
        _isSpeaking = false;
        onComplete?.call();
      }
    });
  }

  bool get isSpeaking => _isSpeaking;

  /// Đọc văn bản bằng giọng nói tiếng Việt qua Google Cloud TTS.
  /// Tự động chia nhỏ text dài thành nhiều đoạn để phát lần lượt.
  Future<void> speak(String text, String apiKey) async {
    if (text.isEmpty || apiKey.isEmpty || _disposed) return;

    // Dừng audio đang phát nếu có
    if (_isSpeaking) {
      await stop();
    }

    // Chia text thành các đoạn nhỏ (< 4500 bytes để an toàn)
    final chunks = _splitTextByByteLimit(text, 4500);

    for (final chunk in chunks) {
      if (_disposed) return;

      try {
        final response = await http.post(
          Uri.parse(
            'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'input': {'text': chunk},
            'voice': {
              'languageCode': 'vi-VN',
              'name': 'vi-VN-Standard-A',
              'ssmlGender': 'FEMALE',
            },
            'audioConfig': {
              'audioEncoding': 'MP3',
              'speakingRate': 1.0,
              'pitch': 0.0,
            },
          }),
        );

        if (_disposed) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final audioContent = data['audioContent'] as String;
          final bytes = base64Decode(audioContent);

          final tempFile = File(
            '${Directory.systemTemp.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
          );
          await tempFile.writeAsBytes(bytes);

          if (_disposed) {
            try { tempFile.deleteSync(); } catch (_) {}
            return;
          }

          await _player.play(DeviceFileSource(tempFile.path));

          // Chờ phát xong rồi mới phát đoạn tiếp theo
          await _player.onPlayerComplete.first;

          try { tempFile.deleteSync(); } catch (_) {}
        } else {
          debugPrint('Cloud TTS error ${response.statusCode}: ${response.body}');
          break;
        }
      } catch (e) {
        debugPrint('Cloud TTS exception: $e');
        _isSpeaking = false;
        if (!_disposed) onComplete?.call();
        return;
      }
    }

    // Phát xong tất cả các đoạn
    _isSpeaking = false;
    if (!_disposed) onComplete?.call();
  }

  /// Chia text thành các đoạn nhỏ sao cho mỗi đoạn < [maxBytes] bytes.
  /// Ưu tiên cắt tại dấu chấm câu hoặc xuống dòng.
  List<String> _splitTextByByteLimit(String text, int maxBytes) {
    final chunks = <String>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      final bytes = utf8.encode(remaining);
      if (bytes.length <= maxBytes) {
        chunks.add(remaining);
        break;
      }

      // Tìm vị trí cắt an toàn (tại dấu chấm, xuống dòng, hoặc dấu cách)
      var cutIndex = remaining.length;
      var byteCount = 0;
      for (var i = 0; i < remaining.length; i++) {
        byteCount = utf8.encode(remaining.substring(0, i + 1)).length;
        if (byteCount > maxBytes) {
          cutIndex = i;
          break;
        }
      }

      // Tìm vị trí dấu chấm/xuống dòng gần nhất để cắt đẹp
      var bestCut = cutIndex;
      for (var i = cutIndex - 1; i > cutIndex ~/ 2; i--) {
        final c = remaining[i];
        if (c == '.' || c == '\n' || c == '!' || c == '?' || c == ';') {
          bestCut = i + 1;
          break;
        }
      }

      chunks.add(remaining.substring(0, bestCut).trim());
      remaining = remaining.substring(bestCut).trim();
    }

    return chunks.where((c) => c.isNotEmpty).toList();
  }

  /// Dừng phát âm thanh
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _isSpeaking = false;
  }

  /// Giải phóng tài nguyên
  void dispose() {
    _disposed = true;
    onStart = null;
    onComplete = null;
    try {
      _player.dispose();
    } catch (_) {}
  }
}
