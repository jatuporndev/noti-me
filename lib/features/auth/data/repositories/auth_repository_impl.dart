import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/auth_repository.dart' as domain;

import '../mappers/session_user_mapper.dart';

class AuthRepositoryImpl implements domain.AuthRepository {
  AuthRepositoryImpl({
    required firebase_auth.FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn;

  final firebase_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<SessionUser?> watchAuthState() {
    return _auth.authStateChanges().map(
          (user) =>
              user == null ? null : SessionUserMapper.fromFirebase(user),
        );
  }

  @override
  SessionUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : SessionUserMapper.fromFirebase(user);
  }

  @override
  Future<void> signInAnonymously() => _auth.signInAnonymously();

  @override
  Future<void> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.authenticate();
      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Google Sign-In returned no id token. In Firebase Console, add a '
          'Web OAuth client and pass its ID as serverClientId in '
          'GoogleSignIn.instance.initialize() (see google_sign_in README).',
        );
      }
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: idToken,
      );
      await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
