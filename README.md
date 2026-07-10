# Smart Agriculture System

A Flutter application for monitoring and controlling a smart greenhouse / farm setup, with real-time Firebase sync and on-device AI leaf-disease classification.

The mobile app is the control layer for an ESP32-based hardware system. It reads live sensor data, shows pump and tank status, lets the user configure automation rules, and runs local TensorFlow Lite inference on leaf images. The UI is Arabic-first.

> **Scope:** This repository contains the **Flutter client** and the Firebase schema the app uses. The ESP32 firmware is maintained separately. This is a real project I built and continue to improve — not a commercial product in production.

---

## What problem it solves

Farm operators need one place to see environmental readings, react to crop-health issues, and control irrigation/fertilization without reprogramming hardware every time.

This app provides:

- A live dashboard for temperature, humidity, soil moisture, and NPK values
- Manual and automatic pump control (water, fertilizer 1, fertilizer 2)
- Tank capacity monitoring and operation logs
- On-device disease detection from leaf photos (`Healthy`, `BacterialSpot`, `LateBlight`)
- In-app notifications (disease events, re-upload reminders, and hardware-written alerts)
- Remote Wi-Fi configuration for the controller (current + backup network)
- Email/password sign-in with an admin approval workflow

---

## Why this repo is useful for hiring review

This is a working IoT mobile client, not a UI mockup. You can verify the claims below directly in the code.

| Area | What to look at |
|------|-----------------|
| **Mobile engineering** | Flutter, Material 3, Arabic localization, navigation shell |
| **State management** | Cubit pattern via `flutter_bloc` (auth, notifications, disease detection, Firebase data) |
| **Backend integration** | Firebase Auth + Realtime Database with a shared stream layer |
| **IoT bridge** | App reads/writes the same RTDB paths used by ESP32 firmware |
| **On-device ML** | TensorFlow Lite inference with `tflite_flutter` |
| **Product safety** | Danger confirmations for Wi-Fi changes + recovery-network guidance |
| **Code organization** | Feature-based folders with a reusable `core/` layer |

---

## Key features (actually implemented)

### Farm monitoring
- Real-time sensor cards and pump status on the dashboard
- Tank capacity visualization for water and fertilizer tanks
- Pump activity logs with sensor snapshots at operation time

### Automation configuration
- Auto-water thresholds (soil moisture min/max)
- Auto-fertilizer thresholds for N, P, K
- Disease-linked fertilizer 2 dosing rules
- Pump mode switching (auto vs manual)
- Controller loop refresh time configuration

### AI disease detection
- Pick a leaf image from the gallery
- Run **on-device** TFLite inference (active path in `plant_classifier_service.dart`)
- Supported classes: `Healthy`, `BacterialSpot`, `LateBlight`
- Optional auto-analyze after upload
- Leaf status synced to Firebase for hardware-side automation logic
- Roboflow/cloud API code exists only as commented-out history in `disease_detection_service.dart`

### Notifications
- Unread count and notification list synced from Firebase
- **App-generated:** disease alerts and scheduled re-upload reminders
- **Hardware-generated (displayed by app):** sensor and tank alerts written to RTDB by the controller firmware
- Mark-as-read and clear flows in the notifications UI

### Settings & hardware support
- Change current and backup Wi-Fi credentials at `config/wifi` (`old_ssid`, `old_pass`, `new_ssid`, `new_pass`)
- Recovery network documented in-app: `hardware_wifi` / `hardware_wifi_123`
- Developer toggles for which configuration sections appear in the UI

### Authentication
- Email/password sign-in and sign-up
- New non-admin users start as `pending` until an admin approves them
- Admin user management screen (approve / reject / block)
- Optional developer bypass to skip the login screen (`AppAccessControl.skipLogin`)

---

## Architecture

```text
Presentation (UI)
    ↓
Cubit (state via flutter_bloc)
    ↓
Services (Firebase, AI, notifications)
    ↓
Firebase Realtime Database  ↔  ESP32 controller
```

### Design choices
- **Shared Firebase streams** in `core/services/firebase_streams.dart` to avoid duplicate listeners and stale UI
- **Canonical farm schema** in `FarmPayload` with default seed data and legacy field migration
- **Separation of concerns:** UI widgets generally do not talk to Firebase directly
- **Startup resilience:** Firebase initialization failures are logged without crashing the app shell

---

## Tech stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart `^3.11.4`) |
| State management | `flutter_bloc` (Cubit), `equatable` |
| Auth | Firebase Authentication (email/password) |
| Realtime data | Firebase Realtime Database |
| On-device ML | TensorFlow Lite (`tflite_flutter`) |
| Image handling | `image_picker`, `image` |
| Local preferences | `shared_preferences` |
| Hardware integration | ESP32 + sensors/actuators via Firebase RTDB |
| Platforms in repo | Android, iOS, Windows, Web, Linux, macOS project files |

**Note:** `google_sign_in`, `cloud_functions`, and `dio` are listed in `pubspec.yaml` but are not part of the active runtime path today (Google Sign-In and Cloud Functions are unused; `dio` is only referenced in commented Roboflow code).

---

## Firebase data model (summary)

```text
/sensors              → temp, hum, moist, n, p, k
/leaf                 → status, needs_fix, last_updated, reupload_at
/config               → pumps, tanks, auto_water, auto_fert, refresh_time, wifi
/config/wifi          → old_ssid, old_pass, new_ssid, new_pass
/extra/logs           → manual/auto pump logs
/extra/notifications  → alert items + unread_count
/users                → app user records / approval state
```

Default schema sample: `lib/core/assets/data/firebase_struct.json`

---

## Project structure

```text
lib/
├── core/
│   ├── assets/          # icons, TFLite model, seed JSON
│   ├── config/          # runtime + access control
│   ├── constants/
│   ├── localization/    # Arabic strings
│   ├── services/        # Firebase streams, pump logger
│   ├── uploads/         # placeholder in repo; runtime saves picked images to device temp storage
│   ├── utils/
│   └── widgets/
├── features/
│   ├── app_shell/       # main navigation
│   ├── auth/
│   ├── configurations/
│   ├── dashboard/
│   ├── disease_detection/
│   ├── firebase_data/
│   ├── notifications/
│   └── settings/
└── main.dart
```

---

## Getting started

### Prerequisites
- Flutter SDK (compatible with Dart `^3.11.4`)
- A Firebase project with Realtime Database and Authentication enabled
- Platform Firebase config files for the target you want to run

### Setup

1. Clone the repository
   ```bash
   git clone https://github.com/mahmoudjawad-2025/smart_agriculture_system.git
   cd smart_agriculture_system
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase
   - Add your platform Firebase config (for example `google-services.json` on Android)
   - Ensure `lib/firebase_options.dart` matches your Firebase project
   - Review and tighten `database.rules.json` before any real deployment (the checked-in rules are fully open for development)

4. Run the app
   ```bash
   flutter run
   ```

### Assets included in repo
- App icons: `lib/core/assets/icons/app/`
- TFLite model: `lib/core/assets/models/best_float32.tflite`
- Seed RTDB JSON: `lib/core/assets/data/firebase_struct.json`

---

## Hardware integration

The ESP32 firmware listens to `/config` streams and publishes `/sensors`, `/leaf`, logs, and many notification entries. This repo contains the Flutter client that reads and writes those same paths.

**In this repo:** RTDB read/write logic, Wi-Fi credential management, automation config editors, disease detection, and notification UI.

**Not in this repo:** microcontroller firmware source, PCB design, or sensor wiring.

---

## Current limitations (transparent)

- Disease model is limited to the three classes in the bundled TFLite file; accuracy depends on training data and image quality
- UI is Arabic-first; English localization is not implemented
- Some settings toggles are developer-facing rather than end-user simplified
- `database.rules.json` is open read/write — suitable for development, not production as-is
- Automated test coverage is minimal (`test/widget_test.dart` is a compile smoke check, not integration tests)
- `flutter analyze` reports minor infos/warnings (deprecated APIs, debug prints) in parts of the codebase
- Primary development and testing have been on Android; other platform folders exist but are not equally exercised
- Leaf images are saved to the device temp directory at runtime, not to `lib/core/uploads/` (that folder is a repo placeholder)
- This demonstrates real full-stack IoT mobile work; it is not positioned as a finished commercial SaaS

---

## What I am looking for

I built this project to grow as a **Flutter / mobile + Firebase / IoT** engineer and to show that I can ship working software across UI, backend sync, and real hardware constraints.

If you are hiring for roles in:
- Flutter development
- Firebase real-time systems
- IoT dashboards and device configuration apps
- On-device ML integration

this repository is a practical sample of my work. I am happy to walk through the architecture, demo the app live, or discuss how it maps to your team's needs.

---

## Contact

- **Email:** [mahmoudjawad02025@gmail.com](mailto:mahmoudjawad02025@gmail.com)
- **GitHub:** [@mahmoudjawad-2025](https://github.com/mahmoudjawad-2025/)
- **LinkedIn:** [linkedin.com/in/mahmoud-abu-alsebaa](https://linkedin.com/in/mahmoud-abu-alsebaa)
