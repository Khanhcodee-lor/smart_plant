import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// Service ghi âm giọng nói và gửi lên Google Cloud Speech-to-Text API
/// để chuyển đổi thành văn bản.
/// Phương pháp này hoạt động trên MỌI điện thoại, không phụ thuộc vào
/// dịch vụ nhận diện giọng nói trên máy (Google, Mi AI, v.v.).
class VoiceTranscriptionService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Kiểm tra quyền ghi âm
  Future<bool> get hasPermission => _recorder.hasPermission();

  /// Kiểm tra đang ghi âm hay không
  Future<bool> get isRecording => _recorder.isRecording();

  /// Bắt đầu ghi âm (WAV 16kHz mono - tối ưu cho Google Speech API)
  Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        return false;
      }

      final path =
          '${Directory.systemTemp.path}/voice_chat_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      return true;
    } catch (e) {
      debugPrint('VoiceService startRecording error: $e');
      return false;
    }
  }

  /// Dừng ghi âm và gửi audio lên Google Cloud Speech-to-Text API.
  /// Trả về transcript (văn bản) nếu thành công, null nếu thất bại.
  Future<String?> stopAndTranscribe(String apiKey) async {
    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();

      // Dọn file tạm
      try {
        await file.delete();
      } catch (_) {}

      if (bytes.isEmpty) return null;

      // Encode audio thành base64 để gửi qua REST API
      final base64Audio = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
          'https://speech.googleapis.com/v1/speech:recognize?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'config': {
            'encoding': 'LINEAR16',
            'sampleRateHertz': 16000,
            'languageCode': 'vi-VN',
            'enableAutomaticPunctuation': true,
          },
          'audio': {
            'content': base64Audio,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final alternatives =
              results.first['alternatives'] as List<dynamic>?;
          if (alternatives != null && alternatives.isNotEmpty) {
            return alternatives.first['transcript'] as String?;
          }
        }
        // API trả về OK nhưng không nhận diện được giọng nói
        return null;
      } else {
        debugPrint(
          'Speech API error ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('VoiceService transcribe error: $e');
      return null;
    }
  }

  /// Hủy ghi âm đang thực hiện
  Future<void> cancelRecording() async {
    try {
      final path = await _recorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
  }

  /// Giải phóng tài nguyên
  void dispose() {
    _recorder.dispose();
  }
}
