import 'package:equatable/equatable.dart';

class Friend extends Equatable {
  const Friend({
    required this.uid,
    required this.nickname,
    required this.tagId,
  });

  final String uid;
  final String nickname;
  final String tagId;

  @override
  List<Object?> get props => [uid, nickname, tagId];
}
