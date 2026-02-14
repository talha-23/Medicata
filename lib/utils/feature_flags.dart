// utils/feature_flags.dart
class FeatureFlags {
  static const Map<String, bool> _guestFeatures = {
    'history': true,           // Basic history view
    'add_medication': false,   // Cannot add medications
    'ai_chatbot': false,       // No AI chatbot
    'profile_stats': true,     // Limited profile stats
    'notifications': false,    // No notifications
    'export_data': false,      // Cannot export data
    'sync': false,             // No cloud sync
    'reminders': true,         // Basic reminders (local only)
  };

  static const Map<String, bool> _registeredFeatures = {
    'history': true,           // Full history with analytics
    'add_medication': true,    // Can add medications
    'ai_chatbot': true,        // Full AI chatbot access
    'profile_stats': true,     // Complete profile stats
    'notifications': true,     // Push notifications
    'export_data': true,       // Can export data
    'sync': true,              // Cloud sync across devices
    'reminders': true,         // Advanced reminders with custom schedules
  };

  static bool canUseFeature(String featureName, bool isGuest) {
    if (isGuest) {
      return _guestFeatures[featureName] ?? false;
    } else {
      return _registeredFeatures[featureName] ?? true;
    }
  }
}