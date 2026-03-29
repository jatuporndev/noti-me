import 'package:equatable/equatable.dart';

class ChannelMember extends Equatable {
  const ChannelMember({
    required this.uid,
    required this.role,
    this.nickname,
    this.muted = false,
    this.joinedAt,
  });

  final String uid;
  final String role;
  final String? nickname;
  final bool muted;
  final DateTime? joinedAt;

  @override
  List<Object?> get props => [uid, role, nickname, muted, joinedAt];
}
