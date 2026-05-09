import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const diseaseImageUploadEndpoint = String.fromEnvironment(
  'DISEASE_UPLOAD_API_URL',
  defaultValue: 'https://khanhsssd-khanhdz.hf.space/api/detect',
);

class DiseaseImageUploadException implements Exception {
  const DiseaseImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DiseaseImageUploadService {
  const DiseaseImageUploadService(this._dio);

  final Dio _dio;

  Future<void> uploadImage({
    required String plantId,
    required XFile image,
  }) async {
    final endpoint = diseaseImageUploadEndpoint.trim();
    if (endpoint.isEmpty) {
      throw const DiseaseImageUploadException(
        'Chưa cấu hình API upload ảnh. Thêm --dart-define=DISEASE_UPLOAD_API_URL=https://server-cua-ban/detect khi chạy app.',
      );
    }

    final normalizedPlantId = plantId.trim();
    if (normalizedPlantId.isEmpty) {
      throw const DiseaseImageUploadException('Không tìm thấy mã cây để gửi.');
    }

    final bytes = await image.readAsBytes();
    final frame = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    try {
      await _dio.post<dynamic>(
        endpoint,
        data: {
          'frame': frame,
          'device_id': normalizedPlantId,
          'device': normalizedPlantId,
          'plant_id': normalizedPlantId,
          'source': 'mobile_app',
          'captured_at': DateTime.now().toUtc().toIso8601String(),
          'persist': true,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final serverMessage = error.response?.data?.toString();
      final message = serverMessage == null || serverMessage.trim().isEmpty
          ? error.message
          : serverMessage;

      throw DiseaseImageUploadException(
        statusCode == null
            ? 'Gửi ảnh lên server thất bại: $message'
            : 'Server trả lỗi $statusCode: $message',
      );
    }
  }
}

final diseaseImageUploadDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );
});

final diseaseImageUploadServiceProvider = Provider<DiseaseImageUploadService>((
  ref,
) {
  return DiseaseImageUploadService(ref.watch(diseaseImageUploadDioProvider));
});

final diseaseImageUploadInFlightProvider = StateProvider.autoDispose
    .family<bool, String>((ref, plantId) => false);
