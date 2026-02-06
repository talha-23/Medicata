import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> signUpWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Check if username already exists
      QuerySnapshot usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'username-exists',
          message: 'Username already taken',
        );
      }

      // Check if email already exists
      QuerySnapshot emailCheck = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (emailCheck.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-exists',
          message: 'Email already registered',
        );
      }

      // Create user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'isGuest': false,
        'uid': credential.user!.uid,
      });

      // Update display name
      await credential.user!.updateDisplayName(username);

      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Signup Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Signup Error: $e");
      rethrow;
    }
  }

  Future<User?> signInWithEmail({
    required String username,
    required String password,
  }) async {
    try {
      // First get email from username
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found',
        );
      }

      String email = query.docs.first['email'];

      // Sign in with email
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Login Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Get User Data Error: $e");
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (data != null) {
        await _firestore.collection('users').doc(uid).update(data);
      }
    } catch (e) {
      print("Update Profile Error: $e");
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Reset Password Error: $e");
      rethrow;
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      print("Check Username Error: $e");
      return false;
    }
  }
}
