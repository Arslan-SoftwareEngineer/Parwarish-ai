import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import '../models/parent_model.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String keyUserRole = 'user_role'; // 'parent', 'child', 'therapist'
  static const String keyCurrentUid = 'current_user_uid';
  static const String keyCurrentEmail = 'current_user_email';
  static const String keyActiveChildId = 'active_child_id';
  static const String keyActiveAutismLevel = 'active_autism_level';

  String? _currentUserUid;
  String? _currentUserEmail;
  String _userRole = '';

  String get currentUserUid => _currentUserUid ?? 'parent_demo_01';
  String get currentUserEmail => _currentUserEmail ?? 'parent@parwarish.ai';
  String get userRole => _userRole;
  bool get isLoggedIn => _userRole.isNotEmpty;

  Future<void> init() async {
    try {
      if (FirebaseService.instance.isFirebaseReady) {
        _auth = FirebaseAuth.instance;
        final user = _auth!.currentUser;
        if (user != null) {
          _currentUserUid = user.uid;
          _currentUserEmail = user.email;
        }
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString(keyUserRole) ?? '';
    _currentUserUid ??= prefs.getString(keyCurrentUid);
    _currentUserEmail ??= prefs.getString(keyCurrentEmail);
  }

  Future<void> cacheUserRole(String role) async {
    _userRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserRole, role);
  }

  Future<void> cacheActiveChild({required String childId, required String autismLevel}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyActiveChildId, childId);
    await prefs.setString(keyActiveAutismLevel, autismLevel);
  }

  Future<String?> getActiveChildId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyActiveChildId);
  }

  Future<String> getActiveAutismLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyActiveAutismLevel) ?? 'Mild';
  }

  // --- SIGN IN WITH EMAIL & PASSWORD ---
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      if (_auth != null) {
        UserCredential credential;
        try {
          credential = await _auth!.signInWithEmailAndPassword(email: email.trim(), password: password);
        } catch (authErr) {
          credential = await _auth!.createUserWithEmailAndPassword(email: email.trim(), password: password);
        }
        _currentUserUid = credential.user?.uid;
        _currentUserEmail = credential.user?.email;
      } else {
        _currentUserUid = '${role}_${email.hashCode.abs()}';
        _currentUserEmail = email.trim();
      }

      await cacheUserRole(role);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCurrentUid, _currentUserUid!);
      await prefs.setString(keyCurrentEmail, _currentUserEmail!);

      if (role == 'parent') {
        await FirebaseService.instance.saveParent(
          ParentModel(uid: _currentUserUid!, email: _currentUserEmail!, createdAt: DateTime.now()),
        );
      }
      return true;
    } catch (e) {
      debugPrint('Sign in error: $e');
      _currentUserUid = '${role}_${email.hashCode.abs()}';
      _currentUserEmail = email.trim();
      await cacheUserRole(role);
      return true;
    }
  }

  // --- GOOGLE SIGN IN ---
  Future<bool> signInWithGoogle({required String role}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (_auth != null) {
        final userCred = await _auth!.signInWithCredential(credential);
        _currentUserUid = userCred.user?.uid;
        _currentUserEmail = userCred.user?.email;
      } else {
        _currentUserUid = 'google_${googleUser.id}';
        _currentUserEmail = googleUser.email;
      }

      await cacheUserRole(role);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCurrentUid, _currentUserUid!);
      await prefs.setString(keyCurrentEmail, _currentUserEmail ?? googleUser.email);
      return true;
    } catch (e) {
      debugPrint('Google Sign In fallback: $e');
      _currentUserUid = '${role}_google_demo';
      _currentUserEmail = 'demo@parwarish.ai';
      await cacheUserRole(role);
      return true;
    }
  }

  // --- APPLE SIGN IN ---
  Future<bool> signInWithApple({required String role}) async {
    _currentUserUid = '${role}_apple_demo';
    _currentUserEmail = 'apple@parwarish.ai';
    await cacheUserRole(role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCurrentUid, _currentUserUid!);
    await prefs.setString(keyCurrentEmail, _currentUserEmail!);
    return true;
  }

  // --- DEMO QUICK ACCESS SIGN IN ---
  Future<bool> signInDemo({required String role}) async {
    if (role == 'therapist') {
      _currentUserUid = 'therapist_dr_ayesha';
      _currentUserEmail = 'dr.ayesha@parwarish.ai';
    } else {
      _currentUserUid = 'parent_demo_01';
      _currentUserEmail = 'parent@parwarish.ai';
    }
    await cacheUserRole(role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCurrentUid, _currentUserUid!);
    await prefs.setString(keyCurrentEmail, _currentUserEmail!);
    return true;
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}
    _userRole = '';
    _currentUserUid = null;
    _currentUserEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUserRole);
    await prefs.remove(keyCurrentUid);
    await prefs.remove(keyCurrentEmail);
    await prefs.remove(keyActiveChildId);
    await prefs.remove(keyActiveAutismLevel);
  }
}
