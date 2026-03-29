import 'package:equatable/equatable.dart';

class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.channelId,
    required this.title,
    this.body,
    required this.scheduleKind,
    required this.timeSlot,
    this.nextRunAt,
    this.lastSentAt,
    required this.createdByUid,
    this.createdAt,
    this.enabled = true,
  });

  final String id;
  final String channelId;
  final String title;
  final String? body;

  /// daily | weekdays | once | custom
  final String scheduleKind;

  /// morning (08:30) | noon (12:00) | evening (17:30)
  final String timeSlot;

  final DateTime? nextRunAt;
  final DateTime? lastSentAt;
  final String createdByUid;
  final DateTime? createdAt;
  final bool enabled;

  @override
  List<Object?> get props => [
        id, channelId, title, body, scheduleKind, timeSlot,
        nextRunAt, lastSentAt, createdByUid, createdAt, enabled,
      ];
}
