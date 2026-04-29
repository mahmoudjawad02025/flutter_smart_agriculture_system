# Smart Agriculture System 🌾🤖

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev/)
[![State Management](https://img.shields.io/badge/State%20Management-Bloc%2FCubit-red.svg)](https://bloclibrary.dev/)
[![Backend](https://img.shields.io/badge/Backend-Firebase-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-grade, high-performance Flutter application engineered for modern farming. This project strongly emphasizes **AI-first capabilities**, demonstrating **expert-level architecture**, **complex state management**, and **adaptive UI design** tailored for agricultural environments.

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

The **Smart Agriculture System** is a sophisticated, scalable mobile application built to modernize farm monitoring and decision-making. **Artificial Intelligence is the core of this system**, natively powering advanced disease detection, predictive insights, and the Harvest Recommendation System (HRS). Designed to impress with seamless Firebase integration and responsive user interfaces, this project proves readiness for enterprise-level Flutter roles.

<br>
<hr>

## 🚀 Key Features

*   **🤖 AI-Powered Core Workflows**: 
    *   **Disease Detection**: Integration with cutting-edge image models to scan, detect, and diagnose plant ailments instantly.
    *   **Harvest Recommendation System (HRS)**: AI-driven predictive insights informing farmers on optimal harvest times based on real-time data.
*   **🧠 Advanced State Management (Bloc/Cubit)**: 
    *   Clean separation of business logic from the presentation layer.
    *   Predictable state flows handling AI inferences, asynchronous real-time databases, and complex UI states.
*   **☁️ Firebase Realtime Ecosystem**: 
    *   Secure user authentication & role management via Firebase Auth.
    *   Live farm data synchronization utilizing Firebase Realtime Database.
*   **📱 Adaptive Responsive Layouts**: 
    *   Material 3 interfaces optimized for mobile dashboards and field use.
    *   Synchronized UI navigation using a custom-built app shell.

<br>
<hr>

## ✨ Architecture & Design

The project strictly follows **Clean Architecture** principles to guarantee maintainability, testability, and high code quality:

1.  **Core Layer**: Contains global utilities, configurations, access controls, and theme definitions.
2.  **Service/Data Layer**: Encapsulates data sourcing, API interactions, Firebase hooks, and AI model inference gateways.
3.  **State Management Layer**: Cubits orchestrate complicated business rules, transforming raw AI and backend data into ready-to-consume states.
4.  **Presentation (UI) Layer**: Pure Material 3 components consisting of scalable widgets and modular feature screens (Auth, Dashboard, Disease Detection).

<br>
<hr>

## 📦 Technology Stack

| Domain | Package | Purpose |
| :--- | :--- | :--- |
| **Core** | lutter | UI Toolkit & Framework |
| **State** | lutter_bloc, loc | Predictable State Routing |
| **AI/Media** | image_picker, dio | Camera input & AI Model processing |
| **Backend** | irebase_core, irebase_auth | Infrastructure & User Management |
| **Database**| irebase_database | Real-time Synchronization |
| **Storage** | shared_preferences | Local persistence & caching |

<br>
<hr>

## 📸 Screenshots

| Login & Auth | Live Dashboard | AI Disease Detection | HRS & AI Insights | App Settings |
| :---: | :---: | :---: | :---: | :---: |
| <img src="lib/core/media/screenshots/1.png" width="200" alt="Login & Auth" /> | <img src="lib/core/media/screenshots/2.png" width="200" alt="Live Dashboard" /> | <img src="lib/core/media/screenshots/3.png" width="200" alt="AI Disease Detection" /> | <img src="lib/core/media/screenshots/4.png" width="200" alt="HRS Insights" /> | <img src="lib/core/media/screenshots/5.png" width="200" alt="App Settings" /> |

*(Screenshots can be added to the lib/core/media/screenshots/ folder naming them 1.png, 2.png, etc.)*

<br>
<hr>

<a name="-project-structure"></a>
## 🛠️ Project Structure

`ash
lib/
├── core/                  # App-wide boundaries
│   ├── config/            # Access control, constants
│   └── media/             # Local App assets & screenshots
├── features/              # Feature Modules
│   ├── auth/              # Auth wrappers & flows
│   ├── app_shell/         # App navigation container
│   ├── dashboard/         # Core metrics & telemetry
│   ├── disease_detection/ # AI Image analysis & results
│   ├── firebase_data/     # Realtime DB UI handlers
│   └── notifications/     # Event dispatch
└── main.dart              # Application Entry Point
`

<br>
<hr>

## 🏁 Installation & Setup

1.  **Clone the Repository**
    `ash
    git clone <repo-url>
    cd smart_agriculture_system
    `

2.  **Install Dependencies**
    `ash
    flutter pub get
    `

3.  **Configure Integrations**
    *   Ensure the platform-specific Firebase configuration files (google-services.json, etc.) are placed correctly.
    *   Review lib/core/config/ for any AI model endpoint credentials required by the detection flow.

4.  **Run the Application**
    `ash
    flutter run
    `

<br>
<hr>

## 📞 Contact

- 📧 **Email**: [mahmoudjawad02025@gmail.com](mailto:mahmoudjawad02025@gmail.com)
- 💻 **GitHub Profile**: [@mahmoudjawad-2025](https://github.com/mahmoudjawad-2025/)
- 💼 **LinkedIn:** [linkedin.com/in/mahmoud-abu-alsebaa](https://linkedin.com/in/mahmoud-abu-alsebaa)
