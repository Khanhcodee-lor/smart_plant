String translateDiseaseLabel(String diseaseName) {
  final normalized = diseaseName.trim().toLowerCase();

  const diseaseTranslations = <String, String>{
    'healthy': 'Khỏe mạnh',
    'tomato leaf late blight': 'Bệnh mốc sương trên lá cà chua',
    'tomato leaf early blight': 'Bệnh đốm vòng trên lá cà chua',
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
  return diseaseName.trim().toLowerCase() == 'healthy';
}
