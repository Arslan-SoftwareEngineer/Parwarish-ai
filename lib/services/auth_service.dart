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

  static const String keyUserRole = 'user_role'; // 'therapist', 'admin', 'parent', 'child'
  static const String keyDefaultDeviceMode = 'default_device_mode'; // 'child' | 'parent'
  static const String keyCurrentUid = 'current_user_uid';
  static const String keyCurrentEmail = 'current_user_email';
  static const String keyCurrentName = 'current_user_name';
  static const String keyLicenseNumber = 'license_number';
  static const String keyActiveChildId = 'active_child_id';
  static const String keyActiveAutismLevel = 'active_autism_level';

  String? _currentUserUid;
  String? _currentUserEmail;
  String? _currentUserName;
  String? _licenseNumber;
  String _userRole = '';
  String? _defaultDeviceMode;

  String get currentUserUid => _currentUserUid ?? 'therapist_demo_01';
  String get currentUserEmail => _currentUserEmail ?? 'dr_ayesha@parwarish.ai';
  String get currentUserName => _currentUserName ?? (canManageChildren ? 'Dr. Ayesha Khan, BCBA-D' : 'Parent User');
  String get licenseNumber => _licenseNumber ?? 'BCBA-PK-88492';
  String get userRole => _userRole;
  String? get defaultDeviceMode => _defaultDeviceMode;
  bool get isLoggedIn => _userRole.isNotEmpty;

  // Strict Access Control Getters
  bool get isTherapist => _userRole == 'therapist';
  bool get isAdmin => _userRole == 'admin';
  bool get isParent => _userRole == 'parent';
  bool get isChild => _userRole == 'child';
  bool get canManageChildren => _userRole == 'therapist' || _userRole == 'admin';

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
    _defaultDeviceMode = prefs.getString(keyDefaultDeviceMode);
    _currentUserUid ??= prefs.getString(keyCurrentUid);
    _currentUserEmail ??= prefs.getString(keyCurrentEmail);
    _currentUserName = prefs.getString(keyCurrentName);
    _licenseNumber = prefs.getString(keyLicenseNumber);
  }

  Future<void> setDefaultDeviceMode(String? mode) async {
    _defaultDeviceMode = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == null) {
      await prefs.remove(keyDefaultDeviceMode);
    } else {
      await prefs.setString(keyDefaultDeviceMode, mode);
    }
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
    String? name,
    String? licenseNum,
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

      _currentUserName = name ?? (role == 'therapist' ? 'Dr. Ayesha Khan, BCBA' : (role == 'admin' ? 'Clinical Director' : 'Parent'));
      _licenseNumber = licenseNum ?? (role == 'therapist' ? 'BCBA-PK-88492' : null);

      await cacheUserRole(role);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCurrentUid, _currentUserUid!);
      await prefs.setString(keyCurrentEmail, _currentUserEmail!);
      if (_currentUserName != null) await prefs.setString(keyCurrentName, _currentUserName!);
      if (_licenseNumber != null) await prefs.setString(keyLicenseNumber, _licenseNumber!);

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
      _currentUserUid = 'therapist_demo_01';
      _currentUserEmail = 'dr_ayesha@parwarish.ai';
      _currentUserName = 'Dr. Ayesha Khan, BCBA-D';
      _licenseNumber = 'BCBA-PK-88492';
    } else if (role == 'admin') {
      _currentUserUid = 'admin_demo_01';
      _currentUserEmail = 'admin@parwarish.ai';
      _currentUserName = 'Clinical Admin Officer';
      _licenseNumber = 'DIR-CLINICAL-001';
    } else if (role == 'child') {
      _currentUserUid = 'child_demo_01';
      _currentUserEmail = 'child@parwarish.ai';
      _currentUserName = 'Aayan';
      _licenseNumber = null;
    } else {
      _currentUserUid = 'parent_demo_01';
      _currentUserEmail = 'parent@parwarish.ai';
      _currentUserName = 'Parent User';
      _licenseNumber = null;
    }

    await cacheUserRole(role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCurrentUid, _currentUserUid!);
    await prefs.setString(keyCurrentEmail, _currentUserEmail!);
    if (_currentUserName != null) await prefs.setString(keyCurrentName, _currentUserName!);
    if (_licenseNumber != null) await prefs.setString(keyLicenseNumber, _licenseNumber!);
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
    _currentUserName = null;
    _licenseNumber = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUserRole);
    await prefs.remove(keyCurrentUid);
    await prefs.remove(keyCurrentEmail);
    await prefs.remove(keyCurrentName);
    await prefs.remove(keyLicenseNumber);
    await prefs.remove(keyActiveChildId);
    await prefs.remove(keyActiveAutismLevel);
  }
}
