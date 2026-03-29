import 'package:equatable/equatable.dart';

class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.name,
    this.description,
    required this.fcmTopicName,
    required this.createdByUid,
    this.inviteCode,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String fcmTopicName;
  final String createdByUid;
  final String? inviteCode;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, name, description, fcmTopicName, createdByUid, inviteCode, createdAt];
}
