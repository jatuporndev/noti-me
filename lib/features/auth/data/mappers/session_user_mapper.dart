import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:noti_me/domain/entities/session_user.dart';

class SessionUserMapper {
  static SessionUser fromFirebase(firebase_auth.User user) {
    return SessionUser(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      email: user.email,
      displayName: user.displayName,
    );
  }
}
