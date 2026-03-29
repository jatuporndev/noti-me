import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/domain/repositories/invite_repository.dart';

import 'invite_inbox_state.dart';

class InviteInboxCubit extends Cubit<InviteInboxState> {
  InviteInboxCubit({
    required InviteRepository inviteRepository,
    required String uid,
  })  : _inviteRepository = inviteRepository,
        super(const InviteInboxLoading()) {
    _subscription = _inviteRepository.watchInbox(uid).listen(
          (invites) => emit(InviteInboxLoaded(invites)),
          onError: (Object e) => emit(InviteInboxError('$e')),
        );
  }

  final InviteRepository _inviteRepository;
  late final StreamSubscription<void> _subscription;

  Future<void> acceptInvite({
    required String inviteId,
    required String channelId,
    required String channelName,
    required String uid,
    required String nickname,
  }) =>
      _inviteRepository.acceptInvite(
        inviteId: inviteId,
        channelId: channelId,
        channelName: channelName,
        uid: uid,
        nickname: nickname,
      );

  Future<void> declineInvite(String inviteId) =>
      _inviteRepository.declineInvite(inviteId);

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
