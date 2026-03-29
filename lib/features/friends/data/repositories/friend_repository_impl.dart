import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:noti_me/domain/entities/friend.dart';
import 'package:noti_me/domain/entities/friend_request.dart';
import 'package:noti_me/domain/repositories/friend_repository.dart';

class FriendRepositoryImpl implements FriendRepository {
  FriendRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, String>?> lookupUserByTag(String tagId) async {
    final normalised = tagId.toUpperCase().trim();
    final indexSnap =
        await _firestore.collection('tagIndex').doc(normalised).get();
    if (!indexSnap.exists) return null;
    final uid = indexSnap.data()?['uid'] as String?;
    if (uid == null) return null;

    final userSnap = await _firestore.collection('users').doc(uid).get();
    if (!userSnap.exists) return null;
    final data = userSnap.data()!;
    return {
      'uid': uid,
      'nickname': data['nickname'] as String? ?? '',
      'tagId': data['tagId'] as String? ?? normalised,
    };
  }

  @override
  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromNickname,
    required String fromTagId,
    required String toUid,
    required String toNickname,
    required String toTagId,
  }) async {
    await _firestore.collection('friendRequests').add({
      'fromUid': fromUid,
      'fromNickname': fromNickname,
      'fromTagId': fromTagId,
      'toUid': toUid,
      'toNickname': toNickname,
      'toTagId': toTagId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String uid) {
    return _firestore
        .collection('friendRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final items = snap.docs.map(_mapRequest).toList()
            ..sort((a, b) =>
                (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return items;
        });
  }

  @override
  Stream<List<FriendRequest>> watchOutgoingRequests(String uid) {
    return _firestore
        .collection('friendRequests')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final items = snap.docs.map(_mapRequest).toList()
            ..sort((a, b) =>
                (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return items;
        });
  }

  FriendRequest _mapRequest(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return FriendRequest(
      id: doc.id,
      fromUid: d['fromUid'] as String? ?? '',
      fromNickname: d['fromNickname'] as String? ?? '',
      fromTagId: d['fromTagId'] as String? ?? '',
      toUid: d['toUid'] as String? ?? '',
      toNickname: d['toNickname'] as String? ?? '',
      toTagId: d['toTagId'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String fromUid,
    required String fromNickname,
    required String fromTagId,
    required String toUid,
    required String toNickname,
    required String toTagId,
  }) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('friendRequests').doc(requestId),
      {'status': 'accepted'},
    );

    batch.set(
      _firestore.collection('users').doc(fromUid).collection('friends').doc(toUid),
      {'uid': toUid, 'nickname': toNickname, 'tagId': toTagId},
    );
    batch.set(
      _firestore.collection('users').doc(toUid).collection('friends').doc(fromUid),
      {'uid': fromUid, 'nickname': fromNickname, 'tagId': fromTagId},
    );

    await batch.commit();
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': 'declined'});
  }

  @override
  Stream<List<Friend>> watchFriends(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return Friend(
                uid: doc.id,
                nickname: d['nickname'] as String? ?? '',
                tagId: d['tagId'] as String? ?? '',
              );
            }).toList());
  }

  @override
  Future<void> removeFriend(String uid, String friendUid) async {
    final batch = _firestore.batch();
    batch.delete(
      _firestore.collection('users').doc(uid).collection('friends').doc(friendUid),
    );
    batch.delete(
      _firestore.collection('users').doc(friendUid).collection('friends').doc(uid),
    );
    await batch.commit();
  }
}
