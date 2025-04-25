import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _fetchUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  // Login with email and password
  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _isLoading = false;
      notifyListeners();
      return null; // No error
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _handleAuthError(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Register a new user
  Future<String?> register(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Create new Firebase Auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'notifications': true,
        'language': 'English',
      });
      
      _isLoading = false;
      notifyListeners();
      return null; // No error
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _handleAuthError(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userData = doc.data() as Map<String, dynamic>;
        }
        notifyListeners();
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  // Update user profile data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).update(data);
        await _fetchUserData();
      } catch (e) {
        print('Error updating user data: $e');
      }
    }
  }

  // Handle Firebase Auth errors and return user-friendly messages
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}