import 'package:equatable/equatable.dart';

import 'package:noti_me/domain/entities/channel_summary.dart';

sealed class ChannelListState extends Equatable {
  const ChannelListState();

  @override
  List<Object?> get props => [];
}

final class ChannelListLoading extends ChannelListState {
  const ChannelListLoading();
}

final class ChannelListLoaded extends ChannelListState {
  const ChannelListLoaded(this.channels);

  final List<ChannelSummary> channels;

  @override
  List<Object?> get props => [channels];
}

final class ChannelListError extends ChannelListState {
  const ChannelListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
