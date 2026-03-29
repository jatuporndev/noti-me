import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:noti_me/domain/entities/channel_invite.dart';
import 'package:noti_me/domain/repositories/invite_repository.dart';

class InviteRepositoryImpl implements InviteRepository {
  InviteRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  })  : _firestore = firestore,
        _messaging = messaging;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  @override
  Future<void> sendInvite({
    required String channelId,
    required String channelName,
    required String fromUid,
    required String fromNickname,
    required String toUid,
  }) async {
    await _firestore.collection('channelInvites').add({
      'channelId': channelId,
      'channelName': channelName,
      'fromUid': fromUid,
      'fromNickname': fromNickname,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<ChannelInvite>> watchInbox(String uid) {
    return _firestore
        .collection('channelInvites')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((doc) {
            final d = doc.data();
            return ChannelInvite(
              id: doc.id,
              channelId: d['channelId'] as String? ?? '',
              channelName: d['channelName'] as String? ?? '',
              fromUid: d['fromUid'] as String? ?? '',
              fromNickname: d['fromNickname'] as String?,
              toUid: d['toUid'] as String?,
              status: d['status'] as String? ?? 'pending',
              createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
            );
          }).toList()
            ..sort((a, b) =>
                (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return items;
        });
  }

  @override
  Future<void> acceptInvite({
    required String inviteId,
    required String channelId,
    required String channelName,
    required String uid,
    required String nickname,
  }) async {
    final channelRef = _firestore.collection('channels').doc(channelId);

    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('channelInvites').doc(inviteId),
      {'status': 'accepted'},
    );

    batch.set(channelRef.collection('members').doc(uid), {
      'uid': uid,
      'role': 'member',
      'nickname': nickname,
      'muted': false,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('channelMemberships')
          .doc(channelId),
      {
        'channelId': channelId,
        'name': channelName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    final channelSnap = await channelRef.get();
    final topicName = channelSnap.data()?['fcmTopicName'] as String?;
    if (topicName != null && topicName.isNotEmpty) {
      await _messaging.subscribeToTopic(topicName);
    }
  }

  @override
  Future<void> declineInvite(String inviteId) async {
    await _firestore
        .collection('channelInvites')
        .doc(inviteId)
        .update({'status': 'declined'});
  }
}
