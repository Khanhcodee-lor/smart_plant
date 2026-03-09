import 'package:app_iot/src/core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// Lớp cơ sở (base class) chung cho các UseCase trong Clean Architecture.
/// Dùng cho các tác vụ CÓ yêu cầu tham số đầu vào và CÓ trả về kết quả.
/// - [Type]: Kiểu dữ liệu sẽ trả về nếu thực thi thành công.
/// - [Params]: Kiểu tham số truyền vào để thực thi UseCase.
/// Sử dụng Either để xử lý kết quả:
/// - Left: chứa [Failure] nếu có lỗi xảy ra.
/// - Right: chứa dữ liệu kiểu [Type] nếu thành công.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Lớp cơ sở cho các UseCase KHÔNG yêu cầu tham số đầu vào nhưng CÓ trả về kết quả.
/// Ví dụ: Lấy danh sách toàn bộ dữ liệu, lấy thông tin user hiện tại đang lưu local.
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Lớp cơ sở hoạt động giống hệt [UseCase], CÓ tham số đầu vào và CÓ kết quả trả về.
/// Tên gọi `WithParams` giúp thể hiện rõ hơn là UseCase này bắt buộc có tham số.
abstract class UseCaseWithParams<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Lớp cơ sở cho các UseCase CÓ tham số đầu vào nhưng KHÔNG yêu cầu trả về kết quả cụ thể.
/// Hàm này trả về `Future<void>`, nên lỗi (thường) sẽ văng Exception trực tiếp hoặc chỉ chạy ngầm.
/// Ví dụ: Gửi log, lưu cache nội bộ...
abstract class UseCaseWithParamsNoReturn<Type, Params> {
  Future<void> call(Params params);
}

/// Lớp cơ sở cho các UseCase KHÔNG tham số đầu vào và KHÔNG trả về kết quả.
/// Hàm trả về `Future<void>`.
/// Ví dụ: Xóa cache nội bộ, đăng xuất tài khoản.
abstract class UseCaseNoParamsNoReturn<Type> {
  Future<void> call();
}

/// Lớp tương tự như [UseCaseWithParamsNoReturn] (CÓ tham số, KHÔNG trả về kết quả).
/// (Có thể đây là code thừa bị trùng lặp chức năng trong quá trình dev).
abstract class UseCaseWithParamsNoReturnNoParams<Type, Params> {
  Future<void> call(Params params);
}

/// Lớp tương tự như [UseCaseNoParamsNoReturn] (KHÔNG tham số, KHÔNG trả về kết quả).
/// (Có thể đây là code thừa bị trùng lặp chức năng trong quá trình dev).
abstract class UseCaseNoParamsNoReturnNoParams<Type> {
  Future<void> call();
}
