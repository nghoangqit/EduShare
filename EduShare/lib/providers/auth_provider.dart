import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/firebase_data_service.dart';

class AuthProvider extends ChangeNotifier {
  static Future<void>? _googleSignInInit;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? _currentUser;
  bool _loading = true;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get loading => _loading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      final profile = await _dataService.ensureUserProfile(_currentUser!);
      if (profile.isBanned) {
        await _auth.signOut();
        _currentUser = null;
        _errorMessage =
            'Tai khoan cua ban da bi khoa boi admin. Vui long lien he ho tro.';
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 15));
      _currentUser = credential.user;
      if (_currentUser != null) {
        await _dataService.ensureUserProfile(_currentUser!);
      }
      final profile = await _dataService.getCurrentUserProfile();
      if (profile?.isBanned == true) {
        await _auth.signOut();
        _currentUser = null;
        _errorMessage =
            'Tai khoan cua ban da bi khoa boi admin. Vui long lien he ho tro.';
        return false;
      }
      return _currentUser != null;
    } on FirebaseAuthException catch (error) {
      _currentUser = null;
      _errorMessage = _mapAuthError(error);
      return false;
    } on TimeoutException {
      _currentUser = null;
      _errorMessage = 'Firebase phan hoi qua lau. Kiem tra mang va thu lai.';
      return false;
    } catch (_) {
      _currentUser = null;
      _errorMessage = 'Dang nhap that bai do loi ket noi Firebase.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ensureGoogleSignInInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        _errorMessage = 'Thiet bi nay chua ho tro dang nhap Google.';
        return false;
      }

      final googleUser = await _googleSignIn.authenticate().timeout(
        const Duration(seconds: 30),
      );
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 20));
      _currentUser = userCredential.user;
      if (_currentUser != null) {
        await _dataService.ensureUserProfile(_currentUser!);
      }

      final profile = await _dataService.getCurrentUserProfile();
      if (profile?.isBanned == true) {
        await _googleSignIn.signOut();
        await _auth.signOut();
        _currentUser = null;
        _errorMessage =
            'Tai khoan cua ban da bi khoa boi admin. Vui long lien he ho tro.';
        return false;
      }

      return _currentUser != null;
    } on GoogleSignInException catch (error) {
      _currentUser = null;
      _errorMessage = _mapGoogleSignInError(error);
      return false;
    } on FirebaseAuthException catch (error) {
      _currentUser = null;
      _errorMessage = _mapAuthError(error);
      return false;
    } on TimeoutException {
      _currentUser = null;
      _errorMessage = 'Google phan hoi qua lau. Kiem tra mang va thu lai.';
      return false;
    } catch (_) {
      _currentUser = null;
      _errorMessage = 'Dang nhap Google that bai. Vui long thu lai.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      _currentUser = credential.user;
      if (_currentUser != null) {
        await _dataService.ensureUserProfile(_currentUser!);
      }
      return _currentUser != null;
    } on FirebaseAuthException catch (error) {
      _currentUser = null;
      _errorMessage = _mapAuthError(error);
      return false;
    } on TimeoutException {
      _currentUser = null;
      _errorMessage = 'Firebase phan hoi qua lau. Kiem tra mang va thu lai.';
      return false;
    } catch (_) {
      _currentUser = null;
      _errorMessage = 'Dang ky that bai do loi ket noi Firebase.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null || email.trim().isEmpty) {
      _errorMessage = 'Khong tim thay tai khoan dang dang nhap.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user
          .reauthenticateWithCredential(credential)
          .timeout(const Duration(seconds: 15));
      await user
          .updatePassword(newPassword)
          .timeout(const Duration(seconds: 15));
      _currentUser = _auth.currentUser;
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapAuthError(error);
      return false;
    } on TimeoutException {
      _errorMessage = 'Firebase phan hoi qua lau. Kiem tra mang va thu lai.';
      return false;
    } catch (_) {
      _errorMessage = 'Doi mat khau that bai do loi ket noi Firebase.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    await _ensureGoogleSignInInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
    _currentUser = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInit ??= _googleSignIn.initialize();
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Email khong dung dinh dang.';
      case 'user-not-found':
        return 'Khong tim thay tai khoan voi email nay.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoac mat khau khong dung.';
      case 'requires-recent-login':
        return 'Vui long dang nhap lai truoc khi doi mat khau.';
      case 'email-already-in-use':
        return 'Email nay da duoc dang ky.';
      case 'weak-password':
        return 'Mat khau qua yeu. Vui long dung it nhat 6 ky tu.';
      case 'network-request-failed':
        return 'Khong ket noi duoc mang. Kiem tra internet roi thu lai.';
      case 'too-many-requests':
        return 'Ban thu qua nhieu lan. Vui long doi mot luc.';
      case 'operation-not-allowed':
        return 'Phuong thuc dang nhap nay chua duoc bat trong Firebase Authentication.';
      default:
        return error.message ?? 'Xac thuc Firebase that bai.';
    }
  }

  String _mapGoogleSignInError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Ban da huy dang nhap Google.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Dang nhap Google bi gian doan. Vui long thu lai.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Khong mo duoc man hinh dang nhap Google tren thiet bi nay.';
      default:
        return error.description ?? 'Dang nhap Google that bai.';
    }
  }
}
