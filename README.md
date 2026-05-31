# Smart Agriculture System

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev/)
[![State Management](https://img.shields.io/badge/State%20Management-Bloc%2FCubit-red.svg)](https://bloclibrary.dev/)
[![Backend](https://img.shields.io/badge/Backend-Firebase-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-grade Flutter and AI-driven agritech platform featuring real-time crop disease detection and automated irrigation/fertilization logic. The app combines responsive UI engineering, BLoC/Cubit state management, and Firebase-backed secure auth and real-time sync to demonstrate a practical product ready for recruiters and hiring managers.

<br>
<hr>

## 📑 Table of Contents

- [🔭 Overview](#-overview)
- [🚀 Key Features](#-key-features)
- [✨ Architecture & Design](#-architecture--design)
- [📦 Technology Stack](#-technology-stack)
- [📸 Screenshots](#-screenshots)
- [🛠️ Project Structure](#-project-structure)
- [🏁 Installation & Setup](#-installation--setup)
- [📞 Contact](#-contact)

<br>
<hr>

## 🔭 Overview

The **Smart Agriculture System** is a modern Flutter application focused on real farm monitoring and intelligent automation. It combines sensor data, image analysis, and AI disease detection to help farmers make faster decisions about irrigation, fertilization, and crop health.

The system is designed for both automatic and manual control flows, so the user can monitor the farm in real time and trigger actions when needed. View project details and UI demos on GitHub.

<br>
<hr>

## 🚀 Key Features

- **AI Disease Detection**: Image-based analysis for detecting plant diseases and crop issues.
- **Real Farm Monitoring**: Live tracking of sensor data for temperature, humidity, soil status, and other environmental readings.
- **Automatic and Manual Control**: Supports both automated and user-triggered irrigation and fertilization actions.
- **Smart Decision Support**: Combines sensor data and image analysis to guide irrigation and fertilization decisions.
- **Flutter UI Excellence**: Responsive interfaces, clean navigation, and a polished Material 3 experience.
- **Firebase Integration**: Authentication, live database sync, and scalable backend support.
- **BLoC/Cubit State Management**: Clear separation of UI and business logic for maintainability.

<br>
<hr>

## ✨ Architecture & Design

The project follows a clean Flutter structure to keep the app maintainable and recruiter-friendly:

1. **Core Layer**: Shared configuration, constants, themes, and reusable utilities.
2. **Data and Service Layer**: Firebase access, AI communication, and device or sensor data handling.
3. **State Management Layer**: Cubits manage farm states, AI responses, and UI updates.
4. **Presentation Layer**: Screens and widgets for monitoring, alerts, AI results, and control actions.

<br>
<hr>

## 📦 Technology Stack

| Domain | Package / Tool | Purpose |
| :--- | :--- | :--- |
| UI | Flutter, Material 3 | Cross-platform interface |
| State Management | flutter_bloc, bloc | Predictable app state |
| Backend | Firebase Core, Auth | Authentication and backend services |
| Database | Firebase Realtime Database | Live sensor and farm data |
| AI / Media | image_picker, dio | Image capture and AI processing |
| Storage | shared_preferences | Local persistence |
| Hardware | ESP32 / sensor nodes / actuators | Farm monitoring and control integration |

<br>
<hr>

## 📸 Screenshots

Add screenshots in [lib/core/media/screenshots/](lib/core/media/screenshots/). Use clear names such as `1.png`, `2.png`, `3.png`, and so on.

| Login & Auth | Live Dashboard | AI Disease Detection | Sensor Monitoring | Irrigation & Fertilization |
| :---: | :---: | :---: | :---: | :---: |
| <img src="lib/core/media/screenshots/1.png" width="200" alt="Login & Auth" /> | <img src="lib/core/media/screenshots/2.png" width="200" alt="Live Dashboard" /> | <img src="lib/core/media/screenshots/3.png" width="200" alt="AI Disease Detection" /> | <img src="lib/core/media/screenshots/4.png" width="200" alt="Sensor Monitoring" /> | <img src="lib/core/media/screenshots/5.png" width="200" alt="Irrigation and Fertilization" /> |

Suggested capture set:

- Login or sign-up screen
- Main dashboard
- AI disease detection result
- Sensor data monitoring screen
- Manual irrigation and fertilization screen
- Auto-control or settings screen

<br>
<hr>

<a name="-project-structure"></a>
## 🛠️ Project Structure

```bash
lib/
├── core/
│   ├── config/            # Access control, constants, and runtime config
│   └── media/             # App assets and screenshots
├── features/
│   ├── auth/              # Authentication screens and logic
│   ├── app_shell/         # Main navigation shell
│   ├── dashboard/         # Farm overview and live data
│   ├── disease_detection/ # AI image analysis and results
│   ├── firebase_data/     # Firebase data handling
│   ├── notifications/     # Alerts and event updates
│   └── settings/          # App configuration screens
└── main.dart              # Application entry point
```

<br>
<hr>

## 🏁 Installation & Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd smart_agriculture_system
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure integrations**
   - Make sure Firebase files such as `google-services.json` are in place.
   - Add any required AI model or API configuration in the app settings or config layer.
   - If your project uses ESP32 or other hardware controllers, connect them with the same data flow documented in your project notes.

4. **Run the app**
   ```bash
   flutter run
   ```

<br>
<hr>

## 📞 Contact

- **Email**: [mahmoudjawad02025@gmail.com](mailto:mahmoudjawad02025@gmail.com)
- **GitHub**: [@mahmoudjawad-2025](https://github.com/mahmoudjawad-2025/)
- **LinkedIn**: [linkedin.com/in/mahmoud-abu-alsebaa](https://linkedin.com/in/mahmoud-abu-alsebaa)
