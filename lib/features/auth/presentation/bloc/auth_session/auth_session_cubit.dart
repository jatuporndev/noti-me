import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/usecases/ensure_user_document_use_case.dart';
import 'package:noti_me/domain/usecases/get_current_session_user_use_case.dart';
import 'package:noti_me/domain/usecases/observe_auth_state_use_case.dart';

import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit({
    required ObserveAuthStateUseCase observeAuthState,
    required EnsureUserDocumentUseCase ensureUserDocument,
    required GetCurrentSessionUserUseCase getCurrentSessionUser,
  })  : _observeAuthState = observeAuthState,
        _ensureUserDocument = ensureUserDocument,
        _getCurrentSessionUser = getCurrentSessionUser,
        super(const AuthSessionLoading()) {
    _subscription = _observeAuthState
        .call()
        .asyncMap(_handleAuth)
        .listen(
          (_) {},
          onError: (Object e, StackTrace st) {
            emit(AuthSessionBootstrapFailure(e));
          },
        );
  }

  final ObserveAuthStateUseCase _observeAuthState;
  final EnsureUserDocumentUseCase _ensureUserDocument;
  final GetCurrentSessionUserUseCase _getCurrentSessionUser;

  late final StreamSubscription<void> _subscription;
  String? _lastBootstrappedUid;

  Future<void> _handleAuth(SessionUser? user) async {
    if (user == null) {
      _lastBootstrappedUid = null;
      emit(const AuthSessionSignedOut());
      return;
    }
    if (user.uid == _lastBootstrappedUid && state is AuthSessionReady) {
      return;
    }
    emit(const AuthSessionBootstrapping());
    try {
      await _ensureUserDocument(user);
      _lastBootstrappedUid = user.uid;
      emit(AuthSessionReady(user));
    } catch (e) {
      emit(AuthSessionBootstrapFailure(e));
    }
  }

  void retryBootstrap() {
    final user = _getCurrentSessionUser();
    if (user == null) return;
    _lastBootstrappedUid = null;
    unawaited(_handleAuth(user));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
