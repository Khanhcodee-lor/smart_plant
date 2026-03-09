import 'package:firebase_database/firebase_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_realtime_database_service.g.dart';

/// Service hỗ trợ thao tác với Firebase Realtime Database
/// Cung cấp các phương thức cơ bản: lấy dữ liệu 1 lần, lắng nghe realtime, thêm, sửa, xóa
class FirebaseRealtimeDatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Lấy dữ liệu một lần (Future)
  Future<DataSnapshot> getData(String path) async {
    final ref = _db.ref(path);
    return await ref.get();
  }

  /// Lắng nghe dữ liệu (Stream) thay đổi realtime
  Stream<DatabaseEvent> streamData(String path) {
    return _db.ref(path).onValue;
  }

  /// Lắng nghe dữ liệu khi có thay đổi (Child added, changed, removed, moved)
  Stream<DatabaseEvent> streamChildAdded(String path) {
    return _db.ref(path).onChildAdded;
  }

  /// Ghi đè toàn bộ dữ liệu tại đường dẫn (Set)
  Future<void> setData(String path, dynamic data) async {
    await _db.ref(path).set(data);
  }

  /// Cập nhật một phần dữ liệu tại đường dẫn (Update) - Thường dùng Map<String, dynamic>
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _db.ref(path).update(data);
  }

  /// Xóa dữ liệu tại đường dẫn
  Future<void> deleteData(String path) async {
    await _db.ref(path).remove();
  }

  /// Tạo một node mới với key tự động sinh ra và đẩy dữ liệu vào
  Future<void> pushData(String path, dynamic data) async {
    final newRef = _db.ref(path).push();
    await newRef.set(data);
  }
}

@riverpod
FirebaseRealtimeDatabaseService firebaseRealtimeDatabaseService(
  FirebaseRealtimeDatabaseServiceRef ref,
) {
  return FirebaseRealtimeDatabaseService();
}
