import '../entities/channel.dart';
import '../entities/channel_member.dart';
import '../entities/channel_summary.dart';

abstract class ChannelRepository {
  Future<Channel> createChannel({
    required String name,
    String? description,
    required String uid,
    required String nickname,
    required List<String> notifySlots,
    required String notifyStartDateBangkok,
    required bool repeatDaily,
  });

  Future<void> updateChannelNotificationSchedule({
    required String channelId,
    required String uid,
    required List<String> notifySlots,
    required String notifyStartDateBangkok,
    required bool repeatDaily,
  });

  Stream<List<ChannelSummary>> watchMyChannels(String uid);

  Stream<Channel> watchChannel(String channelId);

  Stream<List<ChannelMember>> watchMembers(String channelId);

  Future<void> subscribeToChannelTopic(String topicName);

  Future<void> unsubscribeFromChannelTopic(String topicName);

  Future<void> updateMemberMute(String channelId, String uid, bool muted);

  Future<void> deleteChannel(String channelId, String uid);

  Future<Channel?> findChannelByInviteCode(String code);

  /// Join a channel directly (e.g. via invite code) — creates member docs and subscribes.
  Future<void> joinChannel({
    required String channelId,
    required String channelName,
    required String uid,
    required String nickname,
  });

  /// Leave a channel as a member — removes member docs and unsubscribes from FCM topic.
  Future<void> leaveChannel({
    required String channelId,
    required String uid,
  });

  /// Grant or revoke the "can edit" permission for [targetUid].
  /// [callerUid] must be the channel owner.
  Future<void> setMemberCanEdit({
    required String channelId,
    required String callerUid,
    required String targetUid,
    required bool canEdit,
  });
}
