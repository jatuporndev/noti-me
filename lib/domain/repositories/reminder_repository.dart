import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<void> createReminder({
    required String channelId,
    required String title,
    String? body,
    required String createdByUid,
  });

  Stream<List<Reminder>> watchReminders(String channelId);

  Future<void> deleteReminder(String channelId, String reminderId);
}
