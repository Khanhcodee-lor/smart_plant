String translateDiseaseLabel(String diseaseName) {
  final normalized = _normalizeDiseaseKey(diseaseName);

  const diseaseTranslations = <String, String>{
    '0': 'Bệnh đốm vòng sớm trên lá cà chua',
    '1': 'Bệnh đốm lá Septoria trên cà chua',
    '2': 'Bệnh đốm vi khuẩn trên lá cà chua',
    '3': 'Lá cà chua khỏe mạnh',
    '4': 'Bệnh mốc sương trên lá cà chua',
    '5': 'Bệnh mốc lá cà chua',
    '6': 'Bệnh khảm lá cà chua do virus',
    '7': 'Lá cà chua bị nhện đỏ',
    '8': 'Bệnh đốm mục tiêu trên lá cà chua',
    '9': 'Bệnh xoăn vàng lá cà chua do virus',
    // Tomato model classes (hyphens and underscores are normalized to spaces).
    'tomato early blight leaf': 'Bệnh đốm vòng sớm trên lá cà chua',
    'tomato septoria spot leaf': 'Bệnh đốm lá Septoria trên cà chua',
    'tomato bacterial spot leaf': 'Bệnh đốm vi khuẩn trên lá cà chua',
    'tomato healthy leaf': 'Lá cà chua khỏe mạnh',
    'tomato late blight leaf': 'Bệnh mốc sương trên lá cà chua',
    'tomato mold leaf': 'Bệnh mốc lá cà chua',
    'tomato mosaic virus leaf': 'Bệnh khảm lá cà chua do virus',
    'tomato spider mites leaf': 'Lá cà chua bị nhện đỏ',
    'tomato target spot leaf': 'Bệnh đốm mục tiêu trên lá cà chua',
    'tomato yellow virus leaf': 'Bệnh xoăn vàng lá cà chua do virus',
    'no disease detected': 'Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh',
    'khong phat hien benh': 'Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh',
    'healthy': 'Khỏe mạnh',
    'tomato healthy': 'Khỏe mạnh',
    'khỏe mạnh': 'Khỏe mạnh',
    'cây khỏe mạnh': 'Khỏe mạnh',
    'khoe manh': 'Khỏe mạnh',
    'tomato leaf bacterial spot': 'Lá cà chua bệnh đốm vi khuẩn',
    'tomato leaf late blight': 'Bệnh mốc sương trên lá cà chua',
    'tomato late blight': 'Bệnh mốc sương trên lá cà chua',
    'tomato leaf early blight': 'Bệnh đốm vòng trên lá cà chua',
    'tomato early blight': 'Bệnh đốm vòng trên lá cà chua',
    'tomato leaf mold': 'Bệnh nấm lá cà chua',
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
      normalized == '3' ||
      normalized == 'khỏe mạnh' ||
      normalized == 'cây khỏe mạnh' ||
      normalized == 'cây khỏe mạnh (healthy)' ||
      normalized == 'khoe manh' ||
      normalized == 'no disease detected' ||
      normalized == 'khong phat hien benh' ||
      normalized ==
          _normalizeDiseaseKey('Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh') ||
      normalized.contains('healthy') ||
      normalized.contains('khỏe mạnh') ||
      normalized.contains('khoe manh') ||
      normalized.contains('no disease') ||
      normalized.contains('khong phat hien benh');
}

String _normalizeDiseaseKey(String diseaseName) {
  return diseaseName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
