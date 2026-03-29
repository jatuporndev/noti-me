import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:noti_me/domain/entities/reminder.dart';
import 'package:noti_me/domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _remindersCol(String channelId) =>
      _firestore
          .collection('channels')
          .doc(channelId)
          .collection('reminders');

  @override
  Future<void> createReminder({
    required String channelId,
    required String title,
    String? body,
    required String createdByUid,
  }) async {
    await _remindersCol(channelId).add({
      'title': title.trim(),
      if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
      'createdByUid': createdByUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Reminder>> watchReminders(String channelId) {
    return _remindersCol(channelId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return Reminder(
                id: doc.id,
                channelId: channelId,
                title: d['title'] as String? ?? '',
                body: d['body'] as String?,
                createdByUid: d['createdByUid'] as String? ?? '',
                createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  @override
  Future<void> deleteReminder(String channelId, String reminderId) async {
    await _remindersCol(channelId).doc(reminderId).delete();
  }
}
