import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken(forceRefresh);
  }
}

String firebaseAuthErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return '이미 사용 중인 이메일입니다.';
    case 'invalid-email':
      return '올바른 이메일 형식이 아닙니다.';
    case 'weak-password':
      return '비밀번호는 6자 이상이어야 합니다.';
    case 'user-not-found':
    case 'invalid-credential':
    case 'wrong-password':
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    case 'too-many-requests':
      return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
    default:
      return '인증에 실패했습니다. 다시 시도해주세요.';
  }
}
