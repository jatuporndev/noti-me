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
    final account = await _googleSignIn.signIn();
    if (account == null) return; // user canceled the picker

    final googleAuth = await account.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
