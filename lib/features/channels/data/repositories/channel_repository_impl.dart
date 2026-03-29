import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:noti_me/domain/entities/channel.dart';
import 'package:noti_me/domain/entities/channel_member.dart';
import 'package:noti_me/domain/entities/channel_summary.dart';
import 'package:noti_me/domain/repositories/channel_repository.dart';

const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

class ChannelRepositoryImpl implements ChannelRepository {
  ChannelRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  })  : _firestore = firestore,
        _messaging = messaging;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  @override
  Future<Channel> createChannel({
    required String name,
    String? description,
    required String uid,
    required String nickname,
  }) async {
    final channelRef = _firestore.collection('channels').doc();
    final channelId = channelRef.id;
    final topicName = 'channel_$channelId';
    final inviteCode = _generateCode(6);

    final channelData = <String, dynamic>{
      'name': name,
      'fcmTopicName': topicName,
      'createdByUid': uid,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (description != null && description.trim().isNotEmpty) {
      channelData['description'] = description.trim();
    }

    final batch = _firestore.batch();

    batch.set(channelRef, channelData);

    batch.set(channelRef.collection('members').doc(uid), {
      'uid': uid,
      'role': 'owner',
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
        'name': name,
        'role': 'owner',
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    await _messaging.subscribeToTopic(topicName);

    return Channel(
      id: channelId,
      name: name,
      description: description,
      fcmTopicName: topicName,
      createdByUid: uid,
      inviteCode: inviteCode,
    );
  }

  @override
  Stream<List<ChannelSummary>> watchMyChannels(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('channelMemberships')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return ChannelSummary(
                channelId: doc.id,
                name: d['name'] as String? ?? '',
                role: d['role'] as String? ?? 'member',
                joinedAt: (d['joinedAt'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  @override
  Stream<Channel> watchChannel(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) {
      final d = snap.data()!;
      return Channel(
        id: snap.id,
        name: d['name'] as String? ?? '',
        description: d['description'] as String?,
        fcmTopicName: d['fcmTopicName'] as String? ?? '',
        createdByUid: d['createdByUid'] as String? ?? '',
        inviteCode: d['inviteCode'] as String?,
        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      );
    });
  }

  @override
  Stream<List<ChannelMember>> watchMembers(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .collection('members')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return ChannelMember(
                uid: doc.id,
                role: d['role'] as String? ?? 'member',
                nickname: d['nickname'] as String?,
                muted: d['muted'] as bool? ?? false,
                joinedAt: (d['joinedAt'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  @override
  Future<void> subscribeToChannelTopic(String topicName) =>
      _messaging.subscribeToTopic(topicName);

  @override
  Future<void> unsubscribeFromChannelTopic(String topicName) =>
      _messaging.unsubscribeFromTopic(topicName);

  @override
  Future<void> updateMemberMute(
      String channelId, String uid, bool muted) async {
    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('members')
        .doc(uid)
        .update({'muted': muted});
  }

  @override
  Future<void> deleteChannel(String channelId, String uid) async {
    final channelRef = _firestore.collection('channels').doc(channelId);
    final membersSnap = await channelRef.collection('members').get();
    final remindersSnap = await channelRef.collection('reminders').get();

    final batch = _firestore.batch();

    for (final doc in remindersSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in membersSnap.docs) {
      batch.delete(
        _firestore
            .collection('users')
            .doc(doc.id)
            .collection('channelMemberships')
            .doc(channelId),
      );
      batch.delete(doc.reference);
    }
    batch.delete(channelRef);

    await batch.commit();
  }

  @override
  Future<Channel?> findChannelByInviteCode(String code) async {
    final snap = await _firestore
        .collection('channels')
        .where('inviteCode', isEqualTo: code.toUpperCase().trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final d = doc.data();
    return Channel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String?,
      fcmTopicName: d['fcmTopicName'] as String? ?? '',
      createdByUid: d['createdByUid'] as String? ?? '',
      inviteCode: d['inviteCode'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<void> joinChannel({
    required String channelId,
    required String channelName,
    required String uid,
    required String nickname,
  }) async {
    final channelRef = _firestore.collection('channels').doc(channelId);
    final batch = _firestore.batch();

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

  String _generateCode(int length) {
    final rng = Random.secure();
    return List.generate(
        length, (_) => _codeAlphabet[rng.nextInt(_codeAlphabet.length)]).join();
  }
}
