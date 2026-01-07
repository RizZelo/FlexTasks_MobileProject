# FlexTasks 📱

A Flutter-based mobile application that connects JobSeekers seeking flexible work opportunities with clients who need help with various tasks. Think of it as a gig economy platform tailored especially for students.

##  Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the App](#running-the-app)
- [Firebase Configuration](#firebase-configuration)
- [Screenshots](#screenshots)
- [Contributing](#contributing)

##  Overview

FlexTasks is a mobile platform designed to bridge the gap between students looking for flexible, part-time work and clients who need assistance with everyday tasks. Students can browse available tasks, apply for opportunities, and communicate with clients, while clients can post tasks, review applications, and manage their workforce.

##  Features

### For Students
- **Browse Tasks** - Search and filter tasks by category (Tutoring, Gardening, Petcare, Cleaning, Babysitting, Moving)
- **Apply for Tasks** - Submit applications for tasks that match your skills
- **Track Applications** - View status of all submitted applications
- **Real-time Chat** - Communicate directly with clients
- **Profile Management** - Manage your student profile

### For Clients
- **Post Tasks** - Create new task listings with detailed descriptions
- **Dashboard** - Manage all posted tasks from a centralized dashboard
- **Review Applications** - View and manage student applications
- **Real-time Chat** - Communicate with students
- **Review System** - Rate and review students after task completion
- 📍 **Meeting Place Setup** - Set task locations with address autocomplete

### General Features
-  **Authentication** - Secure login with Firebase Auth & Google Sign-In
-  **Real-time Updates** - Powered by Cloud Firestore
-  **Modern UI** - Clean Material Design 3 interface
-  **Cross-platform** - Runs on both Android and iOS

## 🛠 Tech Stack

### Frontend (Mobile App)
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | SDK ^3.10.0 | Cross-platform UI framework |
| Dart | Latest | Programming language |
| Firebase Core | ^3.6.0 | Firebase initialization |
| Cloud Firestore | ^5.4.4 | Real-time database |
| Firebase Auth | ^5.3.1 | User authentication |
| Google Sign-In | ^6.2.1 | OAuth authentication |
| HTTP | ^1.2.0 | REST API calls |
| Intl | ^0.19.0 | Internationalization |

### Backend (Firebase BaaS + Express.js)
| Service | Purpose |
|---------|----------|
| Firebase Authentication | User registration, login, Google Sign-In |
| Cloud Firestore | Real-time NoSQL database |
| Firebase Hosting | App hosting (optional) |
| Express.js Server | Location/Places API for meeting place setup |
| OpenStreetMap Nominatim | Free geocoding & address autocomplete |

> **Note:** This app primarily uses Firebase as a Backend-as-a-Service (BaaS). The `backend/` folder contains an Express.js server that provides **location autocomplete** functionality for setting up meeting places using the free OpenStreetMap Nominatim API.

##  Project Structure

```
ProjetMobile/
├── backend/                    # Express.js server for location services
│   ├── index.js               # Places API endpoints (autocomplete & details)
│   └── package.json           # Backend dependencies (express, axios, cors)
│
├── my_app/                    # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart          # App entry point & theme configuration
│   │   ├── api_service.dart   # HTTP API service
│   │   ├── firebase_options.dart
│   │   │
│   │   ├── pages/             # UI screens
│   │   │   ├── login_page.dart
│   │   │   ├── register_page.dart
│   │   │   ├── student_home_page.dart
│   │   │   ├── client_dashboard_page.dart
│   │   │   ├── task_list_screen.dart
│   │   │   ├── task_detail_page.dart
│   │   │   ├── post_task_screen.dart
│   │   │   ├── application_form_page.dart
│   │   │   ├── my_applications_page.dart
│   │   │   ├── task_applications_page.dart
│   │   │   ├── chat_page.dart
│   │   │   ├── client_profile_page.dart
│   │   │   ├── review_page.dart
│   │   │   └── users_list_page.dart
│   │   │
│   │   ├── services/          # Business logic services
│   │   │   ├── auth_service.dart
│   │   │   ├── task_service.dart
│   │   │   ├── application_service.dart
│   │   │   ├── chat_service.dart
│   │   │   ├── connection_service.dart
│   │   │   └── user_service.dart
│   │   │
│   │   └── utils/             # Utility functions
│   │
│   ├── android/               # Android-specific configuration
│   ├── ios/                   # iOS-specific configuration
│   ├── test/                  # Unit & widget tests
│   ├── pubspec.yaml           # Flutter dependencies
│   └── firebase.json          # Firebase configuration
│
└── passport.js                # Authentication configuration
```

##  Prerequisites

Before running this project, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.10.0)
- [Dart SDK](https://dart.dev/get-dart)
- [Node.js](https://nodejs.org/) (v16 or higher) - for location services backend
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Firebase CLI](https://firebase.google.com/docs/cli) (optional, for deployment)
- A Firebase project with Firestore and Authentication enabled

##  Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ProjetMobile
```

### 2. Setup Flutter App

```bash
cd my_app
flutter pub get
```

### 3. Setup Backend (Location Services)

```bash
cd backend
npm install
```

### 4. Configure Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable **Authentication** (Email/Password and Google Sign-In)
3. Enable **Cloud Firestore**
4. Download `google-services.json` (Android) and place it in `my_app/android/app/`
5. Download `GoogleService-Info.plist` (iOS) and place it in `my_app/ios/Runner/`

## ▶️ Running the App

### 1. Start the Backend Server (for location services)

```bash
cd backend
node index.js
```

The server will start on `http://localhost:3000` and provides:
- `GET /api/places/autocomplete?input=<query>` - Address autocomplete
- `GET /api/places/details?place_id=<id>` - Get place details

### 2. Run the Flutter App

```bash
cd my_app
flutter run
```

### Run on Specific Device

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run on Android emulator
flutter run -d android

# Run on iOS simulator
flutter run -d ios
```

## 🔥 Firebase Configuration

The app uses Firebase for:

1. **Authentication** - User registration and login
2. **Cloud Firestore** - Real-time database for tasks, applications, chats, and user data
3. **Google Sign-In** - OAuth-based authentication

### Firestore Collections Structure

```
├── users/                 # User profiles
├── tasks/                 # Task listings
├── applications/          # Task applications
├── chats/                 # Chat conversations
└── reviews/               # User reviews
```

## 📸 Screenshots

*Screenshots coming soon*

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is part of an academic project at SUP'COM (INDP2B).

---

