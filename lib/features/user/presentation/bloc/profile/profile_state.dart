import 'package:equatable/equatable.dart';

import 'package:noti_me/domain/entities/user_profile.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);

  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

final class ProfileStreamError extends ProfileState {
  const ProfileStreamError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
