# 🌿 Smart Agriculture System

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-blue.svg?style=for-the-badge&logo=dart)](https://dart.dev/)
[![State Management](https://img.shields.io/badge/State_Management-Bloc%2FCubit-red.svg?style=for-the-badge&logo=dart)](https://bloclibrary.dev/)
[![Backend](https://img.shields.io/badge/Backend-Firebase-orange.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

A modern, high-performance Flutter application designed to automate and monitor agricultural environments. Utilizing a microcontroller, this system intelligently manages irrigation and fertilization through real-time soil data and AI-driven image analysis. Integrated seamlessly with Firebase for live synchronization, robust state management, and a premium user experience.

---

## 📑 Table of Contents
- [✨ Overview](#-overview)
- [💡 Business Value & Impact](#-business-value--impact)
- [🎯 Core Functionality](#-core-functionality)
- [📱 App Features](#-app-features)
- [🏗️ Architecture & Project Structure](#-architecture--project-structure)
- [🛡️ Security & Performance](#-security--performance)
- [🚀 Getting Started](#-getting-started)
- [📞 Contact](#-contact)

---

## ✨ Overview

The **Smart Agriculture System** provides an automated, end-to-end solution for farm management. By combining hardware sensors with advanced AI computer vision, the app ensures crops receive precisely what they need, when they need it. The system is engineered to handle complex state management, real-time database updates, and responsive UI design, ensuring a seamless and reliable experience.

---

## 💡 Business Value & Impact

Modern agriculture faces massive challenges with resource waste, sudden crop diseases, and high manual labor costs. This application acts as a direct solution by:
1. **Reducing Resource Waste**: By relying on real-time sensor data rather than scheduled timers, the system uses water and fertilizer only when absolutely necessary.
2. **Minimizing Crop Loss**: AI-driven disease detection identifies health issues on leaves instantly, triggering immediate automated treatment to save yields.
3. **Maximizing Operational Efficiency**: Enables farm managers to monitor, control, and audit vast agricultural setups remotely through a centralized, high-performance mobile dashboard.

---

## 🎯 Core Functionality

Our system leverages a microcontroller-based architecture to provide autonomous farming controls:

💧 **Smart Irrigation**  
Monitors soil moisture levels continuously. When the moisture drops below optimal levels, the system automatically triggers the irrigation process, ensuring plants are watered precisely without manual intervention.

🌱 **Automated Fertilization (Soil-Based)**  
Analyzes soil mineral content in real-time. If the soil lacks essential nutrients, the system automatically dispenses the required fertilization to maintain a healthy growing environment.

📸 **AI-Driven Fertilization (Vision-Based)**  
Integrates computer vision to analyze plant leaf images. If the AI detects signs of illness or disease, it automatically initiates a specialized fertilization process to treat and protect the plant.

*(Note: The system is designed to be highly adaptable to various crops, soil types, and environmental conditions without being hardcoded to specific parameters.)*

---

## 📱 App Features

A premium user interface built for comprehensive farm management:

- 🔐 **Secure Access & User Management**: Robust login and logout via Firebase Authentication. Features strict role-based access control where **Admin accounts** can approve, reject, or block normal user sign-ups. The entire auth flow and user management lifecycle is strictly handled via **BLoC** state management for predictability and security.
- 📊 **Real-Time Dashboard**: A live overview of sensor readings, complete with historical logs of irrigation and fertilization activities.
- 🖼️ **AI Image Upload**: A dedicated page for uploading plant images, triggering the AI analysis and automated care.
- 🎛️ **System Controls**: Comprehensive control panel to adjust sensor thresholds (min/max), and toggle between manual or automatic modes for irrigation and fertilization.
- ⚙️ **General Settings**: Customizable app preferences and system configurations.
- 🔔 **Notifications**: Real-time alerts and updates regarding system actions, sensor warnings, and AI detections.

---

## 🏗️ Architecture & Project Structure

The project strictly adheres to **Clean Architecture** principles to guarantee maintainability, testability, and high code quality. By decoupling the presentation layer from business logic and data access, the app is built to scale at an enterprise level.

### 📂 Clean Folder Structure

```text
lib/
├── core/                    # App-wide utilities, theme, and DI
├── features/                # Feature-first domain modules
│   ├── auth/                # Secure access & authentication
│   ├── dashboard/           # Live monitoring & hardware controls
│   ├── diagnosis/           # AI leaf health analysis
│   ├── management/          # Admin & user management
│   ├── inventory/           # Crop & asset tracking
│   ├── notifications/       # Real-time system alerts
│   └── shared/              # Common UI components & widgets
└── main.dart                # Application entry point
```

### 📦 Technology Stack

| Layer / Domain | Technology / Package | Description |
| :--- | :--- | :--- |
| **Framework** | Flutter | Cross-platform UI toolkit |
| **State Mgt.** | `flutter_bloc`, `bloc` | Predictable, event-driven state routing |
| **Backend** | Firebase | Auth, Realtime Database for live sync |
| **AI / Media** | `image_picker`, `dio` | Image capture & processing pipelines |
| **Storage** | `shared_preferences` | Local caching for fast load times |

---

## 🛡️ Security & Performance

To meet production-grade standards, the application implements robust security and optimization measures:
- **Role-Based Access Control (RBAC)**: Distinct permissions for Admins vs. Normal Users, ensuring sensitive hardware controls and user approvals are strictly protected.
- **State-Driven Security**: Authentication and admin workflows are tightly coupled with BLoC, preventing UI bypassing and unauthorized state mutations.
- **Optimized UI Rebuilds**: Strategic use of `BlocBuilder`, `BlocSelector`, and `const` constructors guarantees a flawless 60fps experience, even when the dashboard receives rapid, continuous real-time IoT data streams.

---

## 🚀 Getting Started

1. **Clone the Repository**
   ```bash
   git clone <repo-url>
   cd smart_agriculture_system
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Integrations**
   - Create a `.env` file in the root directory (you can copy `.env.example`).
   - Fill in your Roboflow API keys and Model IDs:
     ```env
     ROBOFLOW_API_KEY=your_key
     ROBOFLOW_MODEL_ID=your_model_id
     ```
   - Ensure the platform-specific Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`) are placed correctly.


4. **Run the Application**
   ```bash
   flutter run
   ```

---

## 📞 Contact

- 📧 **Email**: [mahmoudjawad02025@gmail.com](mailto:mahmoudjawad02025@gmail.com)
- 💻 **GitHub**: [@mahmoudjawad-2025](https://github.com/mahmoudjawad-2025/)
- 💼 **LinkedIn**: [mahmoud-abu-alsebaa](https://linkedin.com/in/mahmoud-abu-alsebaa)
