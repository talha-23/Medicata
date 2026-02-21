Medicata - Your Personal Medication Assistant
https://img.shields.io/badge/Flutter-3.x-blue.svg
https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black
https://img.shields.io/badge/SQLite-003B57?logo=sqlite&logoColor=white

Medicata is a comprehensive medication tracking mobile application built with Flutter that helps users manage their medications effectively. The app supports both registered users (with cloud sync) and guest users (with local storage), making it accessible to everyone.

📱 Features
Core Functionality
Dual-User Support: Seamless experience for both registered and guest users

Medication Management: Add, edit, and track medications with ease

Smart Storage:

🔐 Registered users: Cloud sync with Firebase Firestore

👤 Guest users: Local SQLite database

Today's Medications: Quick view of pending medications

Medication Tracking: Mark medications as taken/not taken

Detailed Information: View complete medication details including dosage, frequency, and notes

User Features
Authentication: Email/Password and Google Sign-In

Guest Mode: Try the app without creating an account

Profile Management: View stats and account details

Medication History: Track your medication adherence

🏗️ Architecture
lib/
├── models/           # Data models
│   └── medication.dart
├── services/         # Business logic
│   ├── medication_service.dart
│   ├── auth_service.dart
│   └── session_manager.dart
├── screens/          # UI screens
│   ├── Home.dart
│   ├── AddMedicationScreen.dart
│   ├── HistoryScreen.dart
│   ├── ProfileScreen.dart
│   └── ChatBotScreen.dart
├── widgets/          # Reusable widgets
├── databases/        # Database configuration
└── Colors/          # Theme configuration

Key Components
1. Medication Service
   // Unified service for both user types
- addMedication()    // Stores in Firebase or SQLite automatically
- getMedications()   // Retrieves from appropriate storage
- markAsTaken()      // Updates medication status
- deleteMedication() // Removes from storage

2. Dual Storage Strategy
Guest Users: SQLite local database for offline-first experience

Registered Users: Firebase Firestore for cloud synchronization

Automatic Routing: No manual intervention needed

3. Medication Model
   class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final TimeOfDay time;
  final String notes;
  final DateTime createdAt;
  bool isTaken;
  DateTime? takenAt;
}
Prerequisites
Flutter SDK (3.x or higher)

Firebase account

Android Studio / VS Code
