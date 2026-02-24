/// mock_detections_data.dart
/// Dữ liệu giả – hỗ trợ nhiều loại cây

class MockDetectionsData {
  /// ===== THEO LOẠI CÂY =====
  static const Map<String, dynamic> plants = {
    "tomato": {
      "name": "Cà chua",
      "latest": {
        "class": "Tomato leaf late blight",
        "confidence": 0.6217,
        "snapshot":
            "detections/snapshots/tomato_20260126_190413_late_blight.jpg",
        "time": "2026-01-26 19:04:13",
      },
      "history": [
        {
          "id": "-T1",
          "class": "Tomato leaf late blight",
          "confidence": 0.7143,
          "snapshot":
              "detections/snapshots/tomato_20260126_185310_late_blight.jpg",
          "time": "2026-01-26 18:53:10",
        },
        {
          "id": "-T2",
          "class": "Tomato leaf early blight",
          "confidence": 0.8321,
          "snapshot":
              "detections/snapshots/tomato_20260126_181120_early_blight.jpg",
          "time": "2026-01-26 18:11:20",
        },
      ],
    },

    "chili": {
      "name": "Ớt",
      "latest": {
        "class": "Chili leaf curl virus",
        "confidence": 0.7812,
        "snapshot": "detections/snapshots/chili_20260126_191530_leaf_curl.jpg",
        "time": "2026-01-26 19:15:30",
      },
      "history": [
        {
          "id": "-C1",
          "class": "Chili leaf curl virus",
          "confidence": 0.7812,
          "snapshot":
              "detections/snapshots/chili_20260126_191530_leaf_curl.jpg",
          "time": "2026-01-26 19:15:30",
        },
        {
          "id": "-C2",
          "class": "Healthy",
          "confidence": 0.9456,
          "snapshot": "detections/snapshots/chili_20260126_174900_healthy.jpg",
          "time": "2026-01-26 17:49:00",
        },
      ],
    },

    "cucumber": {
      "name": "Dưa leo",
      "latest": {
        "class": "Cucumber powdery mildew",
        "confidence": 0.6924,
        "snapshot":
            "detections/snapshots/cucumber_20260126_193020_powdery_mildew.jpg",
        "time": "2026-01-26 19:30:20",
      },
      "history": [
        {
          "id": "-CU1",
          "class": "Cucumber powdery mildew",
          "confidence": 0.6924,
          "snapshot":
              "detections/snapshots/cucumber_20260126_193020_powdery_mildew.jpg",
          "time": "2026-01-26 19:30:20",
        },
        {
          "id": "-CU2",
          "class": "Healthy",
          "confidence": 0.9631,
          "snapshot":
              "detections/snapshots/cucumber_20260126_171200_healthy.jpg",
          "time": "2026-01-26 17:12:00",
        },
      ],
    },
  };

  /// ===== STREAM CAMERA =====
  static const Map<String, dynamic> stream = {
    "video_url": "https://705e73c177eb.ngrok-free.app/video",
    "status": "online",
  };
}
