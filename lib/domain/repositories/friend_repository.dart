import '../entities/friend.dart';
import '../entities/friend_request.dart';

abstract class FriendRepository {
  /// Returns {uid, nickname, tagId} or null if not found.
  Future<Map<String, String>?> lookupUserByTag(String tagId);

  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromNickname,
    required String fromTagId,
    required String toUid,
    required String toNickname,
    required String toTagId,
  });

  Stream<List<FriendRequest>> watchIncomingRequests(String uid);

  Stream<List<FriendRequest>> watchOutgoingRequests(String uid);

  Future<void> acceptFriendRequest({
    required String requestId,
    required String fromUid,
    required String fromNickname,
    required String fromTagId,
    required String toUid,
    required String toNickname,
    required String toTagId,
  });

  Future<void> declineFriendRequest(String requestId);

  Stream<List<Friend>> watchFriends(String uid);

  Future<void> removeFriend(String uid, String friendUid);
}
