import 'package:equatable/equatable.dart';

/// Lightweight channel info stored in users/{uid}/channelMemberships for fast list queries.
class ChannelSummary extends Equatable {
  const ChannelSummary({
    required this.channelId,
    required this.name,
    required this.role,
    this.joinedAt,
  });

  final String channelId;
  final String name;
  final String role;
  final DateTime? joinedAt;

  @override
  List<Object?> get props => [channelId, name, role, joinedAt];
}
