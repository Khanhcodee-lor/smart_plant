import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_display_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('translates tomato bacterial spot labels to Vietnamese', () {
    expect(
      translateDiseaseLabel('Tomato leaf bacterial spot'),
      'Lá cà chua bệnh đốm vi khuẩn',
    );
    expect(
      translateDiseaseLabel('Tomato___Bacterial_spot'),
      'Bệnh đốm vi khuẩn',
    );
  });

  test('treats tomato healthy labels as healthy', () {
    expect(isHealthyDisease('Tomato healthy'), isTrue);
    expect(isHealthyDisease('Tomato___healthy'), isTrue);
    expect(isHealthyDisease('Cây khỏe mạnh (Healthy)'), isTrue);
    expect(isHealthyDisease('cây khỏe mạnh'), isTrue);
    expect(isHealthyDisease('No disease detected'), isTrue);
    expect(isHealthyDisease('Không phát hiện bệnh'), isTrue);
    expect(isHealthyDisease('Tomato leaf late blight'), isFalse);
  });
}
