import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '385757213775-24rrjbareavs116oq6v2opgfd4i90869.apps.googleusercontent.com',
  );

  // Use a getter that safely checks for an initialized app
  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw Exception("Firebase not initialized. Cannot access Auth.");
    }
    return FirebaseAuth.instance;
  }

  // Get current user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      return const Stream.empty();
    }
  }

  // Sign in with email or username
  Future<User?> signIn(String identifier, String password) async {
    try {
      String email = identifier;
      
      // If it doesn't look like an email, try to find the email by username
      if (!identifier.contains('@')) {
        final query = await _firestore
            .collection('users')
            .where('username', isEqualTo: identifier.toLowerCase().trim())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw Exception("Username not found");
        }
        email = query.docs.first.get('email');
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    }
  }

  // Register with detailed information
  Future<User?> register({
    required String email,
    required String password,
    required String name,
    required String username,
    required String phone,
  }) async {
    try {
      // 1. Check if username is already taken
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(1)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        throw Exception("Username is already taken");
      }

      // 2. Create the user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      final user = result.user;
      if (user != null) {
        // 3. Store additional data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': name,
          'username': username.toLowerCase().trim(),
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'isPremium': false,
        });

        // 4. Update the Auth profile displayName
        await user.updateDisplayName(name);
      }
      
      return user;
    } catch (e) {
      debugPrint("Register Error: $e");
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<DocumentSnapshot?> getUserData() async {
    final user = currentUser;
    if (user != null) {
      return await _firestore.collection('users').doc(user.uid).get();
    }
    return null;
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final UserCredential result;

      if (kIsWeb) {
        // Bypassing google_sign_in package for web to avoid People API errors
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        result = await _auth.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // User cancelled

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        result = await _auth.signInWithCredential(credential);
      }

      final user = result.user;
      if (user != null) {
        // 🔹 For Google users, create a default username based on their UID if it doesn't exist
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'displayName': user.displayName ?? 'New User',
            'username': 'user_${user.uid.substring(0, 5)}', // Temporary unique username
            'isPremium': false,
          });
        }
      }
      return user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.disconnect();
          await _googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint("Google SignOut Error (Ignored): $e");
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint("SignOut Error: $e");
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        final bookmarks = await _firestore.collection('users').doc(user.uid).collection('bookmarks').get();
        for (var doc in bookmarks.docs) {
          await doc.reference.delete();
        }
        await user.delete();
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      }
    } catch (e) {
      debugPrint("Delete Account Error: $e");
      rethrow;
    }
  }
}
