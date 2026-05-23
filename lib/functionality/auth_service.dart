// Service class that manages Firebase Authentication tasks.
// Includes methods for signing in, registering with a username, and signing out.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kenoverse/functionality/firestore_service.dart';

/// AuthService acts as a high-level wrapper for Firebase Auth.
/// It encapsulates logic for user session management and initial profile creation.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  /// A stream that emits the current user whenever the auth state changes
  /// (e.g., login, logout, token refresh).
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  /// Attempts to authenticate a user with an email and password.
  /// Returns [UserCredential] on success, or null on failure.
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('AuthService Error (SignIn): $e');
      return null;
    }
  }

  /// Creates a new Firebase Auth account and initializes a Firestore user profile.
  /// The [username] is stored in Firestore, while credentials remain in Auth.
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      
      // If Auth account creation succeeds, create the corresponding Firestore document.
      if (user != null) {
        await _firestore.updateUsername(user.uid, username);
      }
      
      return result;
    } catch (e) {
      print('AuthService Error (Register): $e');
      return null;
    }
  }

  /// Ends the current user session across all Firebase services.
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('AuthService Error (SignOut): $e');
    }
  }
}
