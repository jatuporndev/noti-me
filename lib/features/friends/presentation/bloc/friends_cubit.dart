import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/domain/entities/friend.dart';
import 'package:noti_me/domain/entities/friend_request.dart';
import 'package:noti_me/domain/repositories/friend_repository.dart';

import 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit({
    required FriendRepository friendRepository,
    required String uid,
  })  : _friendRepository = friendRepository,
        super(const FriendsLoading()) {
    _friendsSub = _friendRepository.watchFriends(uid).listen(
      (friends) {
        _latestFriends = friends;
        _emitIfReady();
      },
      onError: (Object e) => emit(FriendsError('$e')),
    );
    _requestsSub = _friendRepository.watchIncomingRequests(uid).listen(
      (requests) {
        _latestRequests = requests;
        _emitIfReady();
      },
      onError: (Object e) => emit(FriendsError('$e')),
    );
  }

  final FriendRepository _friendRepository;

  late final StreamSubscription<List<Friend>> _friendsSub;
  late final StreamSubscription<List<FriendRequest>> _requestsSub;

  List<Friend>? _latestFriends;
  List<FriendRequest>? _latestRequests;

  void _emitIfReady() {
    final f = _latestFriends;
    final r = _latestRequests;
    if (f != null && r != null) {
      emit(FriendsLoaded(friends: f, incomingRequests: r));
    }
  }

  Future<void> acceptRequest(FriendRequest request) =>
      _friendRepository.acceptFriendRequest(
        requestId: request.id,
        fromUid: request.fromUid,
        fromNickname: request.fromNickname,
        fromTagId: request.fromTagId,
        toUid: request.toUid,
        toNickname: request.toNickname,
        toTagId: request.toTagId,
      );

  Future<void> declineRequest(String requestId) =>
      _friendRepository.declineFriendRequest(requestId);

  Future<void> removeFriend(String uid, String friendUid) =>
      _friendRepository.removeFriend(uid, friendUid);

  @override
  Future<void> close() {
    _friendsSub.cancel();
    _requestsSub.cancel();
    return super.close();
  }
}
