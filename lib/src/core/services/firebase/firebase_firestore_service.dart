import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_firestore_service.g.dart';

class FirestoreDocumentData {
  const FirestoreDocumentData({
    required this.id,
    required this.data,
    this.path = '',
  });

  final String id;
  final Map<String, dynamic> data;
  final String path;
}

class FirebaseFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get a collection stream
  Stream<List<Map<String, dynamic>>> collectionStream(String path) {
    return _db.collection(path).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Get a collection stream with document ids
  Stream<List<FirestoreDocumentData>> collectionStreamWithIds(String path) {
    return _db.collection(path).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => FirestoreDocumentData(
              id: doc.id,
              data: doc.data(),
              path: doc.reference.path,
            ),
          )
          .toList();
    });
  }

  // Get a document stream
  Stream<Map<String, dynamic>?> documentStream(String path) {
    return _db.doc(path).snapshots().map((snapshot) => snapshot.data());
  }

  // Create or Update
  Future<void> setData(
    String path,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    await _db.doc(path).set(data, SetOptions(merge: merge));
  }

  // Add document to collection
  Future<DocumentReference> addDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    return await _db.collection(path).add(data);
  }

  // Delete
  Future<void> deleteData(String path) async {
    await _db.doc(path).delete();
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _db.doc(path).update(data);
  }

  Future<int> deleteCollectionDocuments(
    String path, {
    int batchSize = 400,
  }) async {
    if (batchSize <= 0 || batchSize > 500) {
      throw ArgumentError('batchSize must be between 1 and 500.');
    }

    var deletedCount = 0;
    while (true) {
      final snapshot = await _db.collection(path).limit(batchSize).get();
      if (snapshot.docs.isEmpty) {
        return deletedCount;
      }

      final batch = _db.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();

      deletedCount += snapshot.docs.length;
      if (snapshot.docs.length < batchSize) {
        return deletedCount;
      }
    }
  }
}

@riverpod
FirebaseFirestoreService firebaseFirestoreService(
  FirebaseFirestoreServiceRef ref,
) {
  return FirebaseFirestoreService();
}
