import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      _currentUser = credential.user;
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

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    await _auth.signOut();
    _currentUser = null;
    _loading = false;
    notifyListeners();
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
      case 'email-already-in-use':
        return 'Email nay da duoc dang ky.';
      case 'weak-password':
        return 'Mat khau qua yeu. Vui long dung it nhat 6 ky tu.';
      case 'network-request-failed':
        return 'Khong ket noi duoc mang. Kiem tra internet roi thu lai.';
      case 'too-many-requests':
        return 'Ban thu qua nhieu lan. Vui long doi mot luc.';
      case 'operation-not-allowed':
        return 'Email/Password login chua duoc bat trong Firebase Authentication.';
      default:
        return error.message ?? 'Xac thuc Firebase that bai.';
    }
  }
}
