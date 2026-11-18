import 'package:app_iot/src/core/services/firebase/firebase_storage_service.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/snapshot_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public Pi image URL is used without resolving it through Firebase',
    () async {
      const url =
          'https://storage.googleapis.com/example-bucket/detections/snapshot.jpg';

      expect(
        await FirebaseStorageService().resolveDownloadUrl('  $url  '),
        url,
      );
      expect(isNetworkSnapshotImageUrl(url), isTrue);
      expect(isNetworkSnapshotImageUrl('detections/snapshot.jpg'), isFalse);
    },
  );

  testWidgets('signed image URL is not changed by the cache key', (
    tester,
  ) async {
    const url =
        'https://storage.googleapis.com/example-bucket/snapshot.jpg?X-Goog-Signature=abc';

    await tester.pumpWidget(
      const MaterialApp(
        home: SnapshotImage(imageUrl: url, cacheBustKey: 'capture-123'),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, url);
  });

  testWidgets('public image URLs still receive a cache key', (tester) async {
    const url =
        'https://storage.googleapis.com/example-bucket/detections/snapshot.jpg';

    await tester.pumpWidget(
      const MaterialApp(
        home: SnapshotImage(imageUrl: url, cacheBustKey: 'capture-123'),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      '$url?_app_cache_bust=capture-123',
    );
  });
}
