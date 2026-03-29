import 'package:equatable/equatable.dart';

import 'package:noti_me/domain/entities/friend.dart';
import 'package:noti_me/domain/entities/friend_request.dart';

sealed class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object?> get props => [];
}

final class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

final class FriendsLoaded extends FriendsState {
  const FriendsLoaded({
    required this.friends,
    required this.incomingRequests,
  });

  final List<Friend> friends;
  final List<FriendRequest> incomingRequests;

  @override
  List<Object?> get props => [friends, incomingRequests];
}

final class FriendsError extends FriendsState {
  const FriendsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
