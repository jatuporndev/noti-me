import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<void> createReminder({
    required String channelId,
    required String title,
    String? body,
    required String scheduleKind,
    required String timeSlot,
    required String createdByUid,
  });

  Stream<List<Reminder>> watchReminders(String channelId);

  Future<void> updateReminder(
    String channelId,
    String reminderId, {
    String? title,
    String? body,
    String? scheduleKind,
    String? timeSlot,
    bool? enabled,
  });

  Future<void> deleteReminder(String channelId, String reminderId);
}
