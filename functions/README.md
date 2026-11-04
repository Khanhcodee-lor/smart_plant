# Plant detection push notifications

The mobile app subscribes to one FCM topic per plant: `plant_<plantId>`. The
Realtime Database function watches
`plants/{plantId}/plant_captures/{captureId}` and sends a push when `status`
first becomes `completed`. The `plant_id` payload opens that plant's disease
screen when the user taps the push.

The in-app notification screen reads detection history from the same Firebase
Realtime Database and Firestore providers used by the disease screen. It shows
healthy results in green and detections in red.

## Deploy

From the repository root, install the Firebase CLI if needed, then run:

```sh
cd functions
npm install
cd ..
firebase deploy --only functions
```

The function uses the `asia-southeast1` Realtime Database instance configured
for project `pi4-iot-1b7bb`. Deploying it requires Firebase Cloud Functions to
be enabled for that project. The Raspberry Pi must write completed results to
`plants/<plantId>/plant_captures/<captureId>` with `status: "completed"`.

On iOS, configure an APNs authentication key for Firebase Cloud Messaging and
enable Push Notifications for the Runner target. Android notification
permission is requested by the app at runtime.
