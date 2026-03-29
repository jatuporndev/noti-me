import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.tagId,
    required this.nickname,
  });

  final String tagId;
  final String nickname;

  @override
  List<Object?> get props => [tagId, nickname];
}
