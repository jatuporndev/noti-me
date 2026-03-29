import 'package:equatable/equatable.dart';

/// Lightweight channel info stored in users/{uid}/channelMemberships for fast list queries.
class ChannelSummary extends Equatable {
  const ChannelSummary({
    required this.channelId,
    required this.name,
    required this.role,
    this.joinedAt,
    this.notifySlots,
    this.notifyStartDateBangkok,
  });

  final String channelId;
  final String name;
  final String role;
  final DateTime? joinedAt;

  /// Notification time slots (e.g. ['morning', 'evening']). Null for legacy
  /// memberships created before this field was added.
  final List<String>? notifySlots;

  /// yyyy-MM-dd (Bangkok +7) when notifications start. Null for legacy docs.
  final String? notifyStartDateBangkok;

  @override
  List<Object?> get props =>
      [channelId, name, role, joinedAt, notifySlots, notifyStartDateBangkok];
}
