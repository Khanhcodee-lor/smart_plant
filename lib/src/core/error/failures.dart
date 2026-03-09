import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Lớp trừu tượng (abstract class) đại diện cho các lỗi có thể xảy ra trong ứng dụng.
/// Sử dụng Freezed để tạo các trường hợp lỗi cụ thể (sealed union).
/// Các trường hợp lỗi bao gồm:
/// - [ServerFailure]: Lỗi xảy ra từ phía server (ví dụ: lỗi 500, lỗi API).
/// - [NetworkFailure]: Lỗi kết nối mạng (ví dụ: không có internet).
/// - [CacheFailure]: Lỗi liên quan đến bộ nhớ đệm (ví dụ: không đọc được dữ liệu cache).
@freezed
class Failure with _$Failure {
  const factory Failure.serverError([String? message]) = ServerFailure;
  const factory Failure.networkError() = NetworkFailure;
  const factory Failure.cacheError() = CacheFailure;
}
