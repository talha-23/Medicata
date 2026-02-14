import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;

  // ==================== EMAIL/PASSWORD SIGNUP ====================
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

      // Check if email already exists in Firestore
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

      // Send email verification
      await credential.user!.sendEmailVerification();

      // Create TEMPORARY user record (account inactive until verified)
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'isGuest': false,
        'uid': credential.user!.uid,
        'emailVerified': false,
        'accountActive': false, // Account inactive until email verified
        'verificationSentAt': FieldValue.serverTimestamp(),
        'signInMethod': 'email',
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

  // ==================== CHECK EMAIL VERIFICATION ====================
  Future<bool> checkEmailVerification() async {
    try {
      await _auth.currentUser?.reload();
      User? user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        // Update Firestore to mark account as active
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
          'accountActive': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print("Check Email Verification Error: $e");
      return false;
    }
  }

  // ==================== SEND EMAIL VERIFICATION ====================
  Future<void> sendEmailVerification() async {
    try {
      if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
        await _auth.currentUser!.sendEmailVerification();

        // Update last verification attempt
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(
          {'lastVerificationAttempt': FieldValue.serverTimestamp()},
        );
      }
    } catch (e) {
      print("Send Email Verification Error: $e");
      rethrow;
    }
  }

  // ==================== EMAIL/PASSWORD LOGIN ====================
  Future<User?> signInWithEmail({
    required String username,
    required String password,
  }) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Username not found.',
        );
      }

      String email = query.docs.first['email'];

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!credential.user!.emailVerified) {
        // Sign out the user
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in.',
        );
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed.";

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Username not found.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'email-not-verified':
          errorMessage = e.message ?? 'Please verify your email.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed.';
      }

      throw FirebaseAuthException(code: e.code, message: errorMessage);
    }
  }

  // ==================== GOOGLE SIGN-IN ====================
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();

      if (googleUser == null) {
        return null; // User canceled
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user profile
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': googleUser.displayName ?? 'User',
          'email': googleUser.email,
          'createdAt': FieldValue.serverTimestamp(),
          'isGuest': false,
          'uid': userCredential.user!.uid,
          'emailVerified': true,
          'accountActive': true,
          'signInMethod': 'google',
          'photoUrl': googleUser.photoUrl,
        });
      }

      return userCredential.user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // ==================== FACEBOOK SIGN-IN ====================
  Future<User?> signInWithFacebook() async {
    try {
      // Trigger Facebook login
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed: ${result.status}');
      }

      // Create credential
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Get Facebook user data
      final userData = await FacebookAuth.instance.getUserData();

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user profile
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': userData['name'] ?? 'User',
          'email': userData['email'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'isGuest': false,
          'uid': userCredential.user!.uid,
          'emailVerified': true,
          'accountActive': true,
          'signInMethod': 'facebook',
          'photoUrl': userData['picture']?['data']?['url'] ?? '',
        });
      }

      return userCredential.user;
    } catch (e) {
      print("Facebook Sign-In Error: $e");
      rethrow;
    }
  }

  // ==================== SIGN OUT ====================
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ==================== CHECK IF LOGGED IN ====================
  bool isLoggedIn() {
    return _auth.currentUser != null && _auth.currentUser!.emailVerified;
  }

  // ==================== GET USER DATA ====================
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

  // ==================== PASSWORD RESET WITH USERNAME ====================
  Future<String> resetPassword(String email) async {
    try {
      // Get username from Firestore
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String username = 'User';
      if (query.docs.isNotEmpty) {
        username = query.docs.first['username'] ?? 'User';
      }

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);

      return username;
    } catch (e) {
      print("Reset Password Error: $e");
      rethrow;
    }
  }

  // ==================== CHECK USERNAME AVAILABILITY ====================
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

  // ==================== CHECK EMAIL EXISTS ====================
  Future<bool> checkEmailExists(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print("Check Email Error: $e");
      return false;
    }
  }

  // ==================== IS EMAIL VERIFIED ====================
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }
}
