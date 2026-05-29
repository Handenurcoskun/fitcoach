import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    }
  }

  Future<String?> signInWithGoogle({UserRole? role, String? inviteCode}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;
      final existingDoc = await _db.collection('users').doc(uid).get();
      if (!existingDoc.exists) {
        if (role == null) {
          await _auth.signOut();
          return 'Bu Google hesabıyla kayıt bulunamadı. Kayıt Ol sayfasını kullanın.';
        }
        String? trainerId;
        if (role == UserRole.member && inviteCode != null) {
          trainerId = await _getTrainerIdByInviteCode(inviteCode);
          if (trainerId == null) {
            await _auth.signOut();
            return 'Geçersiz davet kodu.';
          }
        }
        final newUser = UserModel(
          id: uid,
          name: userCredential.user!.displayName ?? googleUser.email,
          email: googleUser.email,
          role: role,
          trainerId: trainerId,
          inviteCode: role == UserRole.trainer ? _generateInviteCode() : null,
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(uid).set(newUser.toMap());
        _currentUser = newUser;
        notifyListeners();
      } else {
        _currentUser = UserModel.fromMap(existingDoc.data()!, uid);
        notifyListeners();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return 'Bir hata oluştu.';
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? inviteCode,
  }) async {
    try {
      if (role == UserRole.member && (inviteCode == null || inviteCode.isEmpty)) {
        return 'Davet kodu gerekli.';
      }

      // Önce Auth hesabı oluştur — Firestore okuma için kimlik doğrulaması gerekiyor
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? trainerId;
      if (role == UserRole.member) {
        trainerId = await _getTrainerIdByInviteCode(inviteCode!);
        if (trainerId == null) {
          await credential.user!.delete();
          await _auth.signOut();
          return 'Geçersiz davet kodu. Eğitmeninden tekrar iste.';
        }
      }

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: role,
        trainerId: trainerId,
        inviteCode: role == UserRole.trainer ? _generateInviteCode() : null,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.id).set(user.toMap());
      _currentUser = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      debugPrint('Register error: $e');
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  // Davet koduna göre trainer ID bul
  Future<String?> _getTrainerIdByInviteCode(String code) async {
    final snap = await _db
        .collection('users')
        .where('inviteCode', isEqualTo: code.trim().toUpperCase())
        .where('role', isEqualTo: 'trainer')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  // Eğitmen için benzersiz davet kodu üret
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final code = List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'FIT-$code';
  }

  Future<String?> regenerateInviteCode() async {
    if (_currentUser == null || !_currentUser!.isTrainer) return 'Yetkisiz işlem.';
    final newCode = _generateInviteCode();
    await _db.collection('users').doc(_currentUser!.id).update({'inviteCode': newCode});
    _currentUser = _currentUser!.copyWith(inviteCode: newCode);
    notifyListeners();
    return null;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
    debugPrint('Firebase Auth error code: $code');
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalıdır.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen bekleyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'E-posta veya şifre hatalı.';
    }
  }
}
