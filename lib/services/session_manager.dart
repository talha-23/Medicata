// lib/services/session_manager.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'sqflite_service.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Session types
  static const String SESSION_TYPE_NONE = 'none';
  static const String SESSION_TYPE_GUEST = 'guest';
  static const String SESSION_TYPE_REGISTERED = 'registered';

  Future<Map<String, dynamic>> getCurrentSession() async {
    // Check Firebase first (registered user)
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.emailVerified) {
      return {
        'type': SESSION_TYPE_REGISTERED,
        'user': firebaseUser,
        'userId': firebaseUser.uid,
        'isGuest': false,
      };
    }

    // Check SQLite for guest session
    bool hasGuestSession = await _dbService.hasActiveGuestSession();
    if (hasGuestSession) {
      final guestData = await _dbService.getActiveGuestSession();
      return {
        'type': SESSION_TYPE_GUEST,
        'user': null,
        'userId': guestData?['guestId'],
        'isGuest': true,
        'guestData': guestData,
      };
    }

    // No active session
    return {
      'type': SESSION_TYPE_NONE,
      'user': null,
      'userId': null,
      'isGuest': false,
    };
  }

  Future<bool> isGuestMode() async {
    final session = await getCurrentSession();
    return session['type'] == SESSION_TYPE_GUEST;
  }

  Future<void> startGuestSession({String? name}) async {
    await _dbService.createGuestSession(name: name);
  }

  Future<void> endGuestSession() async {
    await _dbService.clearGuestSession();
  }

  Future<void> updateGuestActivity() async {
    if (await isGuestMode()) {
      await _dbService.updateGuestLastLogin();
    }
  }

  // Convert guest session to registered user (if they decide to sign up later)
  Future<void> convertGuestToRegistered(String firebaseUid) async {
    if (await isGuestMode()) {
      // Get all guest data
      final guestData = await _dbService.getActiveGuestSession();
      if (guestData != null) {
        final guestId = guestData['guestId'];

        // Migrate guest data to registered user
        final userData = await _dbService.getAllUserData(guestId);
        for (var data in userData) {
          await _dbService.saveUserData(
            userId: firebaseUid,
            key: data['dataKey'],
            value: data['dataValue'],
            synced: false,
          );
        }
      }
      // Clear guest session
      await endGuestSession();
    }
  }

  // Add this method to SessionManager class
  Future<Map<String, dynamic>?> getGuestData() async {
    return await _dbService.getActiveGuestSession();
  }
}
