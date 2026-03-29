import 'package:equatable/equatable.dart';

class ChannelInvite extends Equatable {
  const ChannelInvite({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.fromUid,
    this.fromNickname,
    this.toUid,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String channelId;
  final String channelName;
  final String fromUid;
  final String? fromNickname;
  final String? toUid;
  final String status;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, channelId, channelName, fromUid, fromNickname, toUid, status, createdAt];
}
