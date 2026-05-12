import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get userRole => _currentUser?.role == UserRole.trainer ? 'trainer' : 'member';

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    await _loadUserData(firebaseUser.uid);
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _authErrorMessage(e.code);
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? trainerId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: role,
        trainerId: trainerId,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.id).set(user.toMap());
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _authErrorMessage(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (_auth.currentUser != null) {
      await _loadUserData(_auth.currentUser!.uid);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre yanlış.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalıdır.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
