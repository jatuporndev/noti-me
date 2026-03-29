import 'package:equatable/equatable.dart';

class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.channelId,
    required this.title,
    this.body,
    required this.createdByUid,
    this.createdAt,
  });

  final String id;
  final String channelId;
  final String title;
  final String? body;
  final String createdByUid;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        channelId,
        title,
        body,
        createdByUid,
        createdAt,
      ];
}
