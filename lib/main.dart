import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app/noti_me_app.dart';
import 'core/di/service_locator.dart';
import 'core/services/notification_service.dart';
import 'domain/repositories/user_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  final navigatorKey = GlobalKey<NavigatorState>();
  await NotificationService.instance.initialize(navigatorKey);

  sl<UserRepository>().listenForFcmTokenRefresh();
  runApp(NotiMeApp(authSessionCubit: sl(), navigatorKey: navigatorKey));
}
