const {onValueWritten} = require("firebase-functions/v2/database");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp({
  databaseURL:
    "https://pi4-iot-1b7bb-default-rtdb.asia-southeast1.firebasedatabase.app",
});

const database = admin.database();
const messaging = admin.messaging();

exports.notifyPlantCaptureCompleted = onValueWritten(
  {
    ref: "/plants/{plantId}/plant_captures/{captureId}",
    instance: "pi4-iot-1b7bb-default-rtdb",
    region: "asia-southeast1",
    retry: true,
  },
  async (event) => {
    const capture = event.data.after.val();
    if (!capture || String(capture.status).toLowerCase() !== "completed") {
      return;
    }

    const previousStatus = String(
      event.data.before.child("status").val() || "",
    ).toLowerCase();
    if (previousStatus === "completed") {
      return;
    }

    const {plantId, captureId} = event.params;
    const dispatchRef = database.ref(
      `notification_dispatches/${plantId}/${captureId}`,
    );
    const claim = await dispatchRef.transaction((current) => {
      if (current?.status === "sent") return;
      if (
        current?.status === "sending" &&
        Date.now() - Number(current.updated_at || 0) < 5 * 60 * 1000
      ) {
        return;
      }
      return {status: "sending", updated_at: Date.now()};
    });
    if (!claim.committed) return;

    const label = extractDiseaseLabel(capture);
    const healthy = isHealthyLabel(label);
    const title = healthy
      ? "Cây khỏe mạnh"
      : label
        ? "Phát hiện sâu bệnh"
        : "Đã phân tích xong";
    const body = label
      ? `Cây ${plantId}: ${label}`
      : `Pi đã phân tích xong ảnh của cây ${plantId}.`;
    const notificationId = `${plantId}_${captureId}`;
    const message = {
      topic: `plant_${plantId}`,
      notification: {title, body},
      data: {
        type: "plant_detection",
        plant_id: String(plantId),
        capture_id: String(captureId),
        notification_id: notificationId,
        title,
        body,
        disease: label,
        created_at: String(Date.now()),
      },
      android: {
        priority: "high",
        notification: {channelId: "plant_alerts", sound: "default"},
      },
      apns: {payload: {aps: {sound: "default"}}},
    };

    try {
      await messaging.send(message);
      await dispatchRef.set({status: "sent", updated_at: Date.now()});
      logger.info("Sent plant detection notification", {
        plantId,
        captureId,
        topic: message.topic,
      });
    } catch (error) {
      await dispatchRef.set({status: "failed", updated_at: Date.now()});
      logger.error("Failed to send plant detection notification", error);
      throw error;
    }
  },
);

function extractDiseaseLabel(capture) {
  const payload = asObject(capture.data || capture.result || capture);
  const directFields = [
    "class_name_vi",
    "class_vi",
    "label_vi",
    "disease_vi",
    "disease_name_vi",
    "class_name",
    "class",
    "label",
    "disease",
    "diseaseClass",
    "disease_name",
    "prediction",
    "result",
  ];
  for (const field of directFields) {
    const value = payload[field];
    if (typeof value === "string" && value.trim()) return value.trim();
  }

  for (const field of [
    "disease_list_unique_top",
    "disease_list",
    "disease_objects",
    "latest_objects",
    "detected_objects",
    "objects",
    "detections",
  ]) {
    const items = payload[field];
    if (Array.isArray(items) && items.length) {
      const first = items[0];
      if (typeof first === "string") return first.trim();
      if (first && typeof first === "object") {
        for (const key of directFields) {
          if (typeof first[key] === "string" && first[key].trim()) {
            return first[key].trim();
          }
        }
      }
    }
  }
  return "";
}

function isHealthyLabel(label) {
  const normalized = label.trim().toLowerCase();
  return (
    normalized.includes("healthy") ||
    normalized.includes("khỏe mạnh") ||
    normalized.includes("khoe manh") ||
    normalized.includes("no disease") ||
    normalized.includes("không phát hiện bệnh") ||
    normalized.includes("khong phat hien benh")
  );
}

function asObject(value) {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value
    : {};
}
