import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
  
  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }
  
  // Sign up with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? address,
    String? shopName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _db.createUser(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
        phone: phone,
        address: address,
        shopName: shopName,
      );
      
      await userCredential.user!.updateDisplayName(name);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign up';
    } catch (e) {
      return e.toString();
    }
  }
  
  // Sign in with email and password
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign in';
    } catch (e) {
      return e.toString();
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
  
  // Reset password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    } catch (e) {
      return e.toString();
    }
  }
  
  // Update user profile
  Future<String?> updateProfile({String? name, String? photoURL}) async {
    try {
      if (name != null) {
        await currentUser?.updateDisplayName(name);
      }
      if (photoURL != null) {
        await currentUser?.updatePhotoURL(photoURL);
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}