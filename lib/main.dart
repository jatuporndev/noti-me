import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/app/noti_me_app.dart';
import 'core/di/service_locator.dart';
import 'domain/repositories/user_repository.dart';
import 'firebase_options.dart';

/// Set when Google Sign-In returns no id token on Android:
/// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com`
/// (Firebase Console → Project settings → Your apps → Web client ID.)
const String _kGoogleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize(
    serverClientId: _kGoogleWebClientId.isEmpty ? null : _kGoogleWebClientId,
  );
  await configureDependencies();
  sl<UserRepository>().listenForFcmTokenRefresh();
  runApp(NotiMeApp(authSessionCubit: sl()));
}
