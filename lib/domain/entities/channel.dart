import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  /// yyyy-MM-dd Asia/Bangkok when digests first apply; repeats daily after.
  static const legacyNotifyStartDateBangkok = '1970-01-01';

  const Channel({
    required this.id,
    required this.name,
    this.description,
    required this.fcmTopicName,
    required this.createdByUid,
    this.inviteCode,
    this.createdAt,
    this.notifySlots = const ['morning', 'noon', 'evening'],
    this.notifyStartDateBangkok = legacyNotifyStartDateBangkok,
    this.repeatDaily = true,
  });

  final String id;
  final String name;
  final String? description;
  final String fcmTopicName;
  final String createdByUid;
  final String? inviteCode;
  final DateTime? createdAt;
  final List<String> notifySlots;
  final String notifyStartDateBangkok;

  /// Whether the channel fires notifications every day after [notifyStartDateBangkok].
  /// false = one-time only (fires on the start date then stops).
  /// Defaults to true for legacy channels that pre-date this field.
  final bool repeatDaily;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        fcmTopicName,
        createdByUid,
        inviteCode,
        createdAt,
        notifySlots,
        notifyStartDateBangkok,
        repeatDaily,
      ];
}
