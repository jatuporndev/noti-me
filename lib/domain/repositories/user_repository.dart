import '../entities/session_user.dart';
import '../entities/user_profile.dart';

/// User profile + device sync port (implemented under `features/*/data/`).
abstract class UserRepository {
  Future<void> ensureUserDocument(SessionUser user);

  Future<void> updateNickname(String uid, String nickname);

  /// Subscribes to FCM token refresh for the lifetime of the app.
  void listenForFcmTokenRefresh();

  Stream<UserProfile> watchUserProfile(String uid);
}
