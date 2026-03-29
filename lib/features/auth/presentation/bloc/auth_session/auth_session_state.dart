import 'package:equatable/equatable.dart';

import 'package:noti_me/domain/entities/session_user.dart';

sealed class AuthSessionState extends Equatable {
  const AuthSessionState();

  @override
  List<Object?> get props => [];
}

final class AuthSessionLoading extends AuthSessionState {
  const AuthSessionLoading();
}

final class AuthSessionSignedOut extends AuthSessionState {
  const AuthSessionSignedOut();
}

final class AuthSessionBootstrapping extends AuthSessionState {
  const AuthSessionBootstrapping();
}

final class AuthSessionReady extends AuthSessionState {
  const AuthSessionReady(this.user);

  final SessionUser user;

  @override
  List<Object?> get props => [user.uid];
}

final class AuthSessionBootstrapFailure extends AuthSessionState {
  const AuthSessionBootstrapFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
