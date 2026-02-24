import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_firestore_service.g.dart';

class FirebaseFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get a collection stream
  Stream<List<Map<String, dynamic>>> collectionStream(String path) {
    return _db.collection(path).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Get a document stream
  Stream<Map<String, dynamic>?> documentStream(String path) {
    return _db.doc(path).snapshots().map((snapshot) => snapshot.data());
  }

  // Create or Update
  Future<void> setData(String path, Map<String, dynamic> data, {bool merge = true}) async {
    await _db.doc(path).set(data, SetOptions(merge: merge));
  }

  // Add document to collection
  Future<DocumentReference> addDocument(String path, Map<String, dynamic> data) async {
    return await _db.collection(path).add(data);
  }

  // Delete
  Future<void> deleteData(String path) async {
    await _db.doc(path).delete();
  }
}

@riverpod
FirebaseFirestoreService firebaseFirestoreService(FirebaseFirestoreServiceRef ref) {
  return FirebaseFirestoreService();
}
