import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:noti_me/domain/entities/reminder.dart';
import 'package:noti_me/domain/repositories/reminder_repository.dart';

const _slotHours = <String, List<int>>{
  'morning': [8, 30],
  'noon': [12, 0],
  'evening': [17, 30],
};

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
    required String scheduleKind,
    required String timeSlot,
    required String createdByUid,
  }) async {
    final nextRun = _computeNextRun(scheduleKind, timeSlot);
    await _remindersCol(channelId).add({
      'title': title.trim(),
      if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
      'scheduleKind': scheduleKind,
      'timeSlot': timeSlot,
      'nextRunAt': nextRun != null ? Timestamp.fromDate(nextRun) : null,
      'lastSentAt': null,
      'createdByUid': createdByUid,
      'enabled': true,
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
                scheduleKind: d['scheduleKind'] as String? ?? 'daily',
                timeSlot: d['timeSlot'] as String? ?? 'morning',
                nextRunAt: (d['nextRunAt'] as Timestamp?)?.toDate(),
                lastSentAt: (d['lastSentAt'] as Timestamp?)?.toDate(),
                createdByUid: d['createdByUid'] as String? ?? '',
                createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
                enabled: d['enabled'] as bool? ?? true,
              );
            }).toList());
  }

  @override
  Future<void> updateReminder(
    String channelId,
    String reminderId, {
    String? title,
    String? body,
    String? scheduleKind,
    String? timeSlot,
    bool? enabled,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title.trim();
    if (body != null) updates['body'] = body.trim();
    if (scheduleKind != null) updates['scheduleKind'] = scheduleKind;
    if (timeSlot != null) updates['timeSlot'] = timeSlot;
    if (enabled != null) updates['enabled'] = enabled;

    if ((scheduleKind != null || timeSlot != null) &&
        (enabled == null || enabled)) {
      final kind = scheduleKind ?? 'daily';
      final slot = timeSlot ?? 'morning';
      final nextRun = _computeNextRun(kind, slot);
      updates['nextRunAt'] =
          nextRun != null ? Timestamp.fromDate(nextRun) : null;
    }

    if (updates.isNotEmpty) {
      await _remindersCol(channelId).doc(reminderId).update(updates);
    }
  }

  @override
  Future<void> deleteReminder(String channelId, String reminderId) async {
    await _remindersCol(channelId).doc(reminderId).delete();
  }

  /// Best-effort next-run in UTC+7 (Asia/Bangkok). Dart lacks timezone
  /// support without third-party packages, so we approximate with a +7 offset.
  DateTime? _computeNextRun(String kind, String slot) {
    final hours = _slotHours[slot];
    if (hours == null) return null;

    final nowUtc = DateTime.now().toUtc();
    final nowBkk = nowUtc.add(const Duration(hours: 7));
    var candidate = DateTime.utc(
      nowBkk.year,
      nowBkk.month,
      nowBkk.day,
      hours[0],
      hours[1],
    ).subtract(const Duration(hours: 7));

    if (candidate.isBefore(nowUtc)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    if (kind == 'weekdays') {
      while (candidate.weekday == DateTime.saturday ||
          candidate.weekday == DateTime.sunday) {
        candidate = candidate.add(const Duration(days: 1));
      }
    }

    return candidate;
  }
}
