import 'package:equatable/equatable.dart';

import 'package:noti_me/domain/entities/channel.dart';
import 'package:noti_me/domain/entities/channel_member.dart';
import 'package:noti_me/domain/entities/reminder.dart';

sealed class ChannelDetailState extends Equatable {
  const ChannelDetailState();

  @override
  List<Object?> get props => [];
}

final class ChannelDetailLoading extends ChannelDetailState {
  const ChannelDetailLoading();
}

final class ChannelDetailLoaded extends ChannelDetailState {
  const ChannelDetailLoaded({
    required this.channel,
    required this.members,
    required this.reminders,
  });

  final Channel channel;
  final List<ChannelMember> members;
  final List<Reminder> reminders;

  ChannelDetailLoaded copyWith({
    Channel? channel,
    List<ChannelMember>? members,
    List<Reminder>? reminders,
  }) =>
      ChannelDetailLoaded(
        channel: channel ?? this.channel,
        members: members ?? this.members,
        reminders: reminders ?? this.reminders,
      );

  @override
  List<Object?> get props => [channel, members, reminders];
}

final class ChannelDetailError extends ChannelDetailState {
  const ChannelDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
