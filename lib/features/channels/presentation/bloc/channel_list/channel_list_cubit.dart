import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/domain/repositories/channel_repository.dart';

import 'channel_list_state.dart';

class ChannelListCubit extends Cubit<ChannelListState> {
  ChannelListCubit({
    required ChannelRepository channelRepository,
    required String uid,
  })  : _channelRepository = channelRepository,
        super(const ChannelListLoading()) {
    _subscription = _channelRepository.watchMyChannels(uid).listen(
          (channels) => emit(ChannelListLoaded(channels)),
          onError: (Object e) => emit(ChannelListError('$e')),
        );
  }

  final ChannelRepository _channelRepository;
  late final StreamSubscription<void> _subscription;

  Future<void> createChannel({
    required String name,
    String? description,
    required String uid,
    required String nickname,
  }) async {
    await _channelRepository.createChannel(
      name: name,
      description: description,
      uid: uid,
      nickname: nickname,
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
