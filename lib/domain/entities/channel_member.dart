import 'package:equatable/equatable.dart';

class ChannelMember extends Equatable {
  const ChannelMember({
    required this.uid,
    required this.role,
    this.nickname,
    this.muted = false,
    this.canEdit = false,
    this.joinedAt,
  });

  final String uid;
  final String role;
  final String? nickname;
  final bool muted;

  /// Whether this member can edit channel options (schedule, reminders).
  /// Only the owner can grant/revoke this. Owners are always considered editors.
  final bool canEdit;
  final DateTime? joinedAt;

  bool get isOwner => role == 'owner';

  /// True if this member may modify channel options.
  bool get hasEditAccess => isOwner || canEdit;

  @override
  List<Object?> get props => [uid, role, nickname, muted, canEdit, joinedAt];
}
