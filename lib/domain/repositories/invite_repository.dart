import '../entities/channel_invite.dart';

abstract class InviteRepository {
  Future<void> sendInvite({
    required String channelId,
    required String channelName,
    required String fromUid,
    required String fromNickname,
    required String toUid,
  });

  Stream<List<ChannelInvite>> watchInbox(String uid);

  Future<void> acceptInvite({
    required String inviteId,
    required String channelId,
    required String channelName,
    required String uid,
    required String nickname,
  });

  Future<void> declineInvite(String inviteId);
}
