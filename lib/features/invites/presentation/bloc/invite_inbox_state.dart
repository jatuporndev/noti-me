import 'package:equatable/equatable.dart';

import 'package:noti_me/domain/entities/channel_invite.dart';

sealed class InviteInboxState extends Equatable {
  const InviteInboxState();

  @override
  List<Object?> get props => [];
}

final class InviteInboxLoading extends InviteInboxState {
  const InviteInboxLoading();
}

final class InviteInboxLoaded extends InviteInboxState {
  const InviteInboxLoaded(this.invites);

  final List<ChannelInvite> invites;

  @override
  List<Object?> get props => [invites];
}

final class InviteInboxError extends InviteInboxState {
  const InviteInboxError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
