// utils/feature_flags.dart
class FeatureFlags {
  static const Map<String, bool> _guestFeatures = {
    'history': true,
    'add_medication': true,
    'ai_chatbot': false, // Still false for guests
    'profile_stats': true,
    'notifications': false,
    'export_data': false,
    'sync': false,
    'reminders': true,
  };

  static const Map<String, bool> _registeredFeatures = {
    'history': true,
    'add_medication': true,
    'ai_chatbot': true, 
    'profile_stats': true,
    'notifications': true,
    'export_data': true,
    'sync': true,
    'reminders': true,
  };

  static bool canUseFeature(String featureName, bool isGuest) {
    if (isGuest) {
      return _guestFeatures[featureName] ?? false;
    } else {
      return _registeredFeatures[featureName] ?? true;
    }
  }
}
