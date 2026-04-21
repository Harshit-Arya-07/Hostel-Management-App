
# Hostel Management App

A comprehensive Hostel Management App built with Flutter and Firebase.

## Table of Contents
- [Project Overview](#project-overview)
- [Project Structure](#project-structure)
- [Backend & Services](#backend--services)
- [Frontend](#frontend)
- [Models](#models)
- [Widgets](#widgets)
- [Firebase Setup](#firebase-setup)
- [How to Run](#how-to-run)
- [Requirements](#requirements)

---

## Project Overview
This app provides a complete hostel management solution, including:
- Student and admin dashboards
- Room management
- Fee management
- Complaint tracking
- Leave requests
- User authentication
- Firebase integration for backend services

---

## Project Structure

```
hostel_management_app/
├── android/                # Android native code
├── assets/                 # Images and other assets
├── build/                  # Build outputs (ignored)
├── lib/
│   ├── firebase_options.dart   # Firebase config (auto-generated)
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   ├── screens/               # UI screens (admin, student, auth, etc.)
│   ├── services/              # Backend logic (auth, firestore, etc.)
│   └── widgets/               # Reusable UI components
├── test/                  # Unit/widget tests
├── pubspec.yaml           # Dart/Flutter dependencies
└── README.md              # Project documentation
```

---

## Backend & Services
All backend logic is handled via Firebase and custom service classes in `lib/services/`:
- **auth_service.dart**: User authentication (login, signup, logout)
- **firestore_service.dart**: Firestore database operations
- **storage_service.dart**: Firebase Storage for file uploads
- **room_service.dart**: Room management logic
- **fee_service.dart**: Fee management logic
- **complaint_service.dart**: Complaint tracking logic
- **leave_service.dart**: Leave request logic

---

## Frontend
UI is organized in `lib/screens/`:
- **auth/**: Login and signup screens
- **admin/**: Admin dashboard and management screens
- **student/**: Student dashboard
- **profile/**: Profile and profile editing
- **rooms/**: Room listing and management
- **complaints/**: Complaint submission and tracking
- **home/**: Home screen
- **splash_screen.dart**: App splash/loading screen

---

## Models
Data models are in `lib/models/`:
- **user_model.dart**: User data structure
- **room_model.dart**: Room data structure
- **fee_model.dart**: Fee data structure
- **complaint_model.dart**: Complaint data structure
- **leave_model.dart**: Leave request data structure

---

## Widgets
Reusable UI components in `lib/widgets/`:
- **custom_text_field.dart**: Custom styled text fields
- **dashboard_card.dart**: Dashboard summary cards
- **loading_overlay.dart**: Loading spinner overlay

---

## Firebase Setup
This project uses Firebase for authentication, Firestore, and storage.

### 1. Create a Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Create a new project (e.g., `hostel-management-system`)

### 2. Register Your App
- Add an Android app (use your app's package name)
- Download `google-services.json` and place it in `android/app/`

### 3. Configure Firebase in Flutter
- Run `flutterfire configure` to generate `lib/firebase_options.dart` (or edit it manually)
- Ensure `firebase_core`, `firebase_auth`, `cloud_firestore`, and `firebase_storage` are in `pubspec.yaml`

### 4. Update `firebase_options.dart`
- Replace placeholder values with your Firebase project values (see comments in the file)

### 5. Enable Required Firebase Services
- Authentication (Email/Password)
- Firestore Database
- Storage

---

## How to Run

1. **Install Flutter SDK** ([instructions](https://docs.flutter.dev/get-started/install))
2. **Install dependencies:**
	```sh
	flutter pub get
	```
3. **Connect Firebase:**
	- Ensure `google-services.json` is in `android/app/`
	- Ensure `lib/firebase_options.dart` is configured
4. **Run the app:**
	```sh
	flutter run
	```

---

## Requirements
- Flutter 3.6.0 or higher
- Dart SDK 3.6.0 or higher
- Firebase project (with Authentication, Firestore, Storage enabled)

---

## Notes
- The `flutter-sdk/` folder is included as a submodule or reference. If you clone this repo, you may need to initialize submodules or install Flutter separately.
- For any issues, check the comments in `lib/firebase_options.dart` and follow the Firebase setup steps above.

---

## License
See [LICENSE](../LICENSE).
