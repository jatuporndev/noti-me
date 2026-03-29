import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/entities/user_profile.dart';
import 'package:noti_me/domain/repositories/user_repository.dart' as domain;

const _tagAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

class UserRepositoryImpl implements domain.UserRepository {
  UserRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
    required firebase_auth.FirebaseAuth auth,
  })  : _firestore = firestore,
        _messaging = messaging,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final firebase_auth.FirebaseAuth _auth;

  @override
  Future<void> ensureUserDocument(SessionUser user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) {
      await _syncFcmToken(user.uid);
      return;
    }

    final tagId = await _allocateTagId(user.uid);
    final nickname = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : 'Friend';

    final data = <String, dynamic>{
      'nickname': nickname,
      'tagId': tagId,
      'fcmTokens': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (user.email != null) {
      data['email'] = user.email;
    }
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      data['googleDisplayName'] = user.displayName!.trim();
    }

    await ref.set(data);
    await _syncFcmToken(user.uid);
  }

  Future<String> _allocateTagId(String uid) async {
    final random = Random.secure();
    for (var attempt = 0; attempt < 48; attempt++) {
      final tag = List.generate(
        8,
        (_) => _tagAlphabet[random.nextInt(_tagAlphabet.length)],
      ).join();
      try {
        await _firestore.runTransaction((tx) async {
          final indexRef = _firestore.collection('tagIndex').doc(tag);
          final indexSnap = await tx.get(indexRef);
          if (indexSnap.exists) {
            throw StateError('tag collision');
          }
          tx.set(indexRef, {'uid': uid});
        });
        return tag;
      } catch (_) {
        continue;
      }
    }
    throw StateError('Could not allocate tagId');
  }

  Future<void> _syncFcmToken(String uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _firestore.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateNickname(String uid, String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) return;
    await _firestore.collection('users').doc(uid).update({'nickname': trimmed});
  }

  @override
  void listenForFcmTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      final user = _auth.currentUser;
      if (user == null || token.isEmpty) return;
      _firestore.collection('users').doc(user.uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Stream<UserProfile> watchUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return UserProfile(
        tagId: data?['tagId'] as String? ?? '…',
        nickname: data?['nickname'] as String? ?? '',
      );
    });
  }
}
