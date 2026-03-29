import '../entities/session_user.dart';

/// Authentication port (implemented under `features/*/data/` or shared `data/`).
abstract class AuthRepository {
  Stream<SessionUser?> watchAuthState();

  SessionUser? get currentUser;

  Future<void> signInAnonymously();

  Future<void> signInWithGoogle();

  Future<void> signOut();
}
