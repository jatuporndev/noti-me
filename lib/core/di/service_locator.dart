import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:noti_me/domain/repositories/auth_repository.dart' as auth_domain;
import 'package:noti_me/domain/repositories/channel_repository.dart' as channel_domain;
import 'package:noti_me/domain/repositories/friend_repository.dart' as friend_domain;
import 'package:noti_me/domain/repositories/invite_repository.dart' as invite_domain;
import 'package:noti_me/domain/repositories/reminder_repository.dart' as reminder_domain;
import 'package:noti_me/domain/repositories/user_repository.dart' as user_domain;
import 'package:noti_me/domain/usecases/ensure_user_document_use_case.dart';
import 'package:noti_me/domain/usecases/get_current_session_user_use_case.dart';
import 'package:noti_me/domain/usecases/observe_auth_state_use_case.dart';
import 'package:noti_me/domain/usecases/sign_in_anonymously_use_case.dart';
import 'package:noti_me/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:noti_me/domain/usecases/sign_out_use_case.dart';
import 'package:noti_me/domain/usecases/update_nickname_use_case.dart';
import 'package:noti_me/domain/usecases/watch_user_profile_use_case.dart';
import 'package:noti_me/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:noti_me/features/auth/presentation/bloc/auth_session/auth_session_cubit.dart';
import 'package:noti_me/features/auth/presentation/bloc/sign_in/sign_in_cubit.dart';
import 'package:noti_me/features/channels/data/repositories/channel_repository_impl.dart';
import 'package:noti_me/features/friends/data/repositories/friend_repository_impl.dart';
import 'package:noti_me/features/invites/data/repositories/invite_repository_impl.dart';
import 'package:noti_me/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:noti_me/features/user/data/repositories/user_repository_impl.dart';

final GetIt sl = GetIt.instance;

/// Web OAuth client ID (same as `oauth_client` client_type 3 in `google-services.json`).
/// Required so `GoogleSignIn` returns an `idToken` for Firebase Auth on Android.
const _googleWebClientId =
    '438821325874-n977tvjjuq5co195va8uj2kcuu2htajo.apps.googleusercontent.com';

Future<void> configureDependencies() async {
  // ── Firebase / platform singletons ──
  sl
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance)
    ..registerLazySingleton<GoogleSignIn>(
      () => GoogleSignIn(serverClientId: _googleWebClientId),
    );

  // ── Repositories ──
  sl
    ..registerLazySingleton<auth_domain.AuthRepository>(
      () => AuthRepositoryImpl(auth: sl(), googleSignIn: sl()),
    )
    ..registerLazySingleton<user_domain.UserRepository>(
      () => UserRepositoryImpl(firestore: sl(), messaging: sl(), auth: sl()),
    )
    ..registerLazySingleton<channel_domain.ChannelRepository>(
      () => ChannelRepositoryImpl(firestore: sl(), messaging: sl()),
    )
    ..registerLazySingleton<invite_domain.InviteRepository>(
      () => InviteRepositoryImpl(firestore: sl(), messaging: sl()),
    )
    ..registerLazySingleton<friend_domain.FriendRepository>(
      () => FriendRepositoryImpl(firestore: sl()),
    )
    ..registerLazySingleton<reminder_domain.ReminderRepository>(
      () => ReminderRepositoryImpl(firestore: sl()),
    );

  // ── Use cases (auth / user) ──
  sl
    ..registerLazySingleton(() => ObserveAuthStateUseCase(sl()))
    ..registerLazySingleton(() => GetCurrentSessionUserUseCase(sl()))
    ..registerLazySingleton(() => EnsureUserDocumentUseCase(sl()))
    ..registerLazySingleton(() => SignInWithGoogleUseCase(sl()))
    ..registerLazySingleton(() => SignInAnonymouslyUseCase(sl()))
    ..registerLazySingleton(() => SignOutUseCase(sl()))
    ..registerLazySingleton(() => UpdateNicknameUseCase(sl()))
    ..registerLazySingleton(() => WatchUserProfileUseCase(sl()));

  // ── BLoC / Cubits ──
  sl
    ..registerLazySingleton<AuthSessionCubit>(
      () => AuthSessionCubit(
        observeAuthState: sl(),
        ensureUserDocument: sl(),
        getCurrentSessionUser: sl(),
      ),
    )
    ..registerFactory<SignInCubit>(
      () => SignInCubit(
        signInWithGoogle: sl(),
        signInAnonymously: sl(),
      ),
    );
}
