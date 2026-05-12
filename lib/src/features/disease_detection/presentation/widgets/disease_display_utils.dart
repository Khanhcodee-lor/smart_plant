String translateDiseaseLabel(String diseaseName) {
  final normalized = _normalizeDiseaseKey(diseaseName);

  const diseaseTranslations = <String, String>{
    'no disease detected': 'Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh',
    'khong phat hien benh': 'Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh',
    'healthy': 'Khỏe mạnh',
    'tomato healthy': 'Khỏe mạnh',
    'tomato leaf bacterial spot': 'Lá cà chua bệnh đốm vi khuẩn',
    'tomato leaf late blight': 'Bệnh mốc sương trên lá cà chua',
    'tomato late blight': 'Bệnh mốc sương trên lá cà chua',
    'tomato leaf early blight': 'Bệnh đốm vòng trên lá cà chua',
    'tomato early blight': 'Bệnh đốm vòng trên lá cà chua',
    'tomato leaf mold': 'Bệnh nấm lá cà chua',
    'tomato mold leaf': 'Bệnh nấm lá cà chua',
    'tomato yellow leaf curl virus': 'Bệnh xoăn vàng lá do virus',
    'tomato mosaic virus': 'Bệnh khảm lá do virus',
    'tomato septoria leaf spot': 'Bệnh đốm lá Septoria',
    'tomato spider mites two-spotted spider mite': 'Nhện đỏ',
    'tomato target spot': 'Bệnh đốm vòng (Target Spot)',
    'tomato bacterial spot': 'Bệnh đốm vi khuẩn',
  };

  return diseaseTranslations[normalized] ?? diseaseName;
}

bool isHealthyDisease(String diseaseName) {
  final normalized = _normalizeDiseaseKey(diseaseName);
  return normalized == 'healthy' ||
      normalized == 'tomato healthy' ||
      normalized == 'no disease detected' ||
      normalized == 'khong phat hien benh' ||
      normalized ==
          _normalizeDiseaseKey('Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh');
}

String _normalizeDiseaseKey(String diseaseName) {
  return diseaseName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
