import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:noti_me/core/utils/bangkok_calendar.dart';
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
    required List<String> notifySlots,
    required String notifyStartDateBangkok,
    required bool repeatDaily,
  }) async {
    final channelRef = _firestore.collection('channels').doc();
    final channelId = channelRef.id;
    final topicName = 'channel_$channelId';
    final inviteCode = _generateCode(6);

    final slotsOrdered = orderedNotifySlots(notifySlots);
    final channelData = <String, dynamic>{
      'name': name,
      'fcmTopicName': topicName,
      'createdByUid': uid,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'notifySlots': slotsOrdered,
      'notifyStartDateBangkok': notifyStartDateBangkok,
      'repeatDaily': repeatDaily,
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
        'notifySlots': slotsOrdered,
        'notifyStartDateBangkok': notifyStartDateBangkok,
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
      notifySlots: slotsOrdered,
      notifyStartDateBangkok: notifyStartDateBangkok,
      repeatDaily: repeatDaily,
    );
  }

  String _readNotifyStartDateBangkok(Map<String, dynamic> d) {
    final v = d['notifyStartDateBangkok'] as String?;
    if (v == null || v.trim().isEmpty) {
      return Channel.legacyNotifyStartDateBangkok;
    }
    return v.trim();
  }

  @override
  Future<void> updateChannelNotificationSchedule({
    required String channelId,
    required String uid,
    required List<String> notifySlots,
    required String notifyStartDateBangkok,
    required bool repeatDaily,
  }) async {
    final ref = _firestore.collection('channels').doc(channelId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Channel not found');
    }
    final owner = snap.data()?['createdByUid'] as String?;
    if (owner != uid) {
      throw StateError('Only the owner can update the schedule');
    }
    final ordered = orderedNotifySlots(notifySlots);
    final batch = _firestore.batch();
    batch.update(ref, {
      'notifySlots': ordered,
      'notifyStartDateBangkok': notifyStartDateBangkok,
      'repeatDaily': repeatDaily,
    });
    // Keep the owner's membership summary in sync so the list card stays current.
    batch.update(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('channelMemberships')
          .doc(channelId),
      {
        'notifySlots': ordered,
        'notifyStartDateBangkok': notifyStartDateBangkok,
      },
    );
    await batch.commit();
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
                notifySlots: (d['notifySlots'] as List<dynamic>?)
                    ?.whereType<String>()
                    .toList(),
                notifyStartDateBangkok:
                    d['notifyStartDateBangkok'] as String?,
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
        notifySlots: (d['notifySlots'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const ['morning', 'noon', 'evening'],
        notifyStartDateBangkok: _readNotifyStartDateBangkok(d),
        repeatDaily: d['repeatDaily'] as bool? ?? true,
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
      notifySlots: (d['notifySlots'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const ['morning', 'noon', 'evening'],
      notifyStartDateBangkok: _readNotifyStartDateBangkok(d),
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

    // Fetch first so we can copy notifySlots and topicName into the membership.
    final channelSnap = await channelRef.get();
    final channelData = channelSnap.data() ?? {};
    final topicName = channelData['fcmTopicName'] as String?;
    final notifySlots = (channelData['notifySlots'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const [];

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
        'notifySlots': notifySlots,
        'notifyStartDateBangkok':
            channelData['notifyStartDateBangkok'] as String? ?? '',
      },
    );

    await batch.commit();

    if (topicName != null && topicName.isNotEmpty) {
      await _messaging.subscribeToTopic(topicName);
    }
  }

  @override
  Future<void> leaveChannel({
    required String channelId,
    required String uid,
  }) async {
    final channelRef = _firestore.collection('channels').doc(channelId);

    // Grab the topic name before deleting anything.
    final snap = await channelRef.get();
    final topicName = snap.data()?['fcmTopicName'] as String?;

    final batch = _firestore.batch();

    // Remove member doc from the channel.
    batch.delete(channelRef.collection('members').doc(uid));

    // Remove membership summary from the user's sub-collection.
    batch.delete(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('channelMemberships')
          .doc(channelId),
    );

    await batch.commit();

    if (topicName != null && topicName.isNotEmpty) {
      await _messaging.unsubscribeFromTopic(topicName);
    }
  }

  String _generateCode(int length) {
    final rng = Random.secure();
    return List.generate(
        length, (_) => _codeAlphabet[rng.nextInt(_codeAlphabet.length)]).join();
  }
}
