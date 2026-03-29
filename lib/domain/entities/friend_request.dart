import 'package:equatable/equatable.dart';

class FriendRequest extends Equatable {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromNickname,
    required this.fromTagId,
    required this.toUid,
    required this.toNickname,
    required this.toTagId,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String fromUid;
  final String fromNickname;
  final String fromTagId;
  final String toUid;
  final String toNickname;
  final String toTagId;
  final String status;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id, fromUid, fromNickname, fromTagId,
        toUid, toNickname, toTagId, status, createdAt,
      ];
}
