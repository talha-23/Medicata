# 💊 Medicata - Your Personal Medication Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen.svg)](https://flutter.dev)

<div align="center">
  <h3>Never Miss a Dose Again</h3>
  <p>A beautiful, elderly-friendly medication reminder app with AI-powered assistance</p>
</div>

---

## 🌟 Features

### 🏥 Medication Management
- Add, edit, and delete medications
- Track dosage, frequency, and course duration
- Upload photos of medications
- Mark medications as taken with one tap
- Active/inactive status management
- Search medications

### 🤖 AI Health Assistant
- Powered by Groq's Llama 3 model
- Get answers to medication questions
- Health tips and wellness advice
- 24/7 availability
- Medical disclaimers for safety

### ⏰ Smart Reminders
- Customizable notification times
- Multiple daily reminders
- Snooze options
- Sound and vibration controls
- Missed dose alerts
- Daily summaries

### 📊 Health Analytics
- Adherence tracking with charts
- Today/Week/Month filtering
- Taken vs missed statistics
- Progress tracking

### 👤 User Profiles
- **Registered Users:** Profile photos, personal info, medical conditions, emergency contacts, cloud backup
- **Guest Users:** Instant access, local storage, premium features preview

### 🔒 Security
- Email verification
- Google Sign-In
- Secure sessions
- Data encryption
- Clear data option

### 🎨 UI/UX
- Soft medical colors (light blue, white, green)
- Gradient backgrounds
- Rounded cards
- Large, readable text
- Elderly-friendly design

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Cross-platform framework |
| Firebase Auth | Authentication |
| Cloud Firestore | Cloud database |
| SQLite | Local storage |
| SharedPreferences | User preferences |
| Groq API | AI chatbot (Llama 3) |
| flutter_local_notifications | Reminders |
| image_picker | Photos |
| fl_chart | Analytics charts |

---

## 📦 Installation

### Prerequisites
- Flutter SDK (3.x)
- Dart SDK (3.x)
- Firebase project
- Groq API key

### Setup

```bash
# Clone repository
git clone https://github.com/yourusername/medicata.git
cd medicata

# Install dependencies
flutter pub get

# Configure Firebase
flutterfire configure

# Create .env file with your Groq API key
echo "GROQ_API_KEY=your_key_here" > .env

# Run app
flutter run
```

---

## 🚀 Quick Start

### Guest Mode
1. Launch app
2. Tap "Continue Without Account"
3. Start adding medications

### Registered User
1. Sign up with email or Google
2. Verify email
3. Complete profile
4. Enjoy full features

### Add Medication
1. Tap "+" button
2. Enter details (name, dosage, tablets)
3. Set duration
4. Configure reminders
5. Add photo (optional)
6. Save

### Use AI Assistant
1. Go to Chat tab
2. Type your question
3. Get instant answers

---

## 📁 Project Structure

```
lib/
├── Screens/
│   ├── Home.dart
│   ├── Signup.dart
│   ├── login.dart
│   ├── ProfileScreen.dart
│   ├── AddMedicationScreen.dart
│   ├── EditMedicationScreen.dart
│   ├── HistoryScreen.dart
│   ├── ChatBotScreen.dart
│   ├── SettingsScreen.dart
│   └── HelpSupportScreen.dart
├── models/
│   ├── medication.dart
│   └── chat_message.dart
├── services/
│   ├── auth_service.dart
│   ├── medication_service.dart
│   ├── notification_service.dart
│   ├── session_manager.dart
│   ├── sqflite_service.dart
│   └── chat_service.dart
├── widgets/
│   ├── LoadingIndicator.dart
│   ├── FeatureGate.dart
│   └── UpgradePrompt.dart
├── Colors/
│   └── theme.dart
├── utils/
│   └── feature_flags.dart
└── main.dart
```

---

## 🔐 Environment Variables

Create `.env` file:
```
GROQ_API_KEY=gsk_your_key_here
```

---

## 📱 Supported Platforms

- ✅ Android (5.0+)
- ✅ iOS (11.0+)
- ⬜ Web (partial)

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file

---

## 🙏 Acknowledgments

- Flutter team
- Firebase
- Groq AI
- All open-source packages

---

## 📞 Contact

- **Email**: muhammadtalha8150.com

---

<div align="center">
  <h3>⭐ Star this repo if you find it useful! ⭐</h3>
  <p>Made with ❤️ for better health</p>
</div>
```
