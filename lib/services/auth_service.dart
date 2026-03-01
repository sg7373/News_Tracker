import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        await _createUserInFirestore(result.user!);
      }
      
      return result.user;
    } catch (e) {
      debugPrint("Register Error: $e");
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserInFirestore(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? 'New User',
        'isPremium': false,
      });
    } catch (e) {
      debugPrint("Store User Error: $e");
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        await _createUserInFirestore(result.user!);
      }
      return result.user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      return await _auth.signOut();
    } catch (e) {
      debugPrint("SignOut Error: $e");
      rethrow;
    }
  }
}
