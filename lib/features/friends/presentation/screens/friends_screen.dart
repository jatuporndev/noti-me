import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/friend.dart';
import 'package:noti_me/domain/entities/friend_request.dart';
import 'package:noti_me/domain/entities/session_user.dart';

import '../bloc/friends_cubit.dart';
import '../bloc/friends_state.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key, required this.user});

  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      builder: (context, state) {
        return switch (state) {
          FriendsLoading() => const _FriendsLoadingSkeleton(),
          FriendsError(:final message) => Scaffold(
              body: CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    title: Text('Friends'),
                    backgroundColor: Colors.transparent,
                    pinned: true,
                  ),
                  SliverFillRemaining(child: Center(child: Text(message))),
                ],
              ),
            ),
          FriendsLoaded(:final friends, :final incomingRequests) => Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: const Text('Friends'),
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.person_add_rounded),
                        tooltip: 'Add friend',
                        onPressed: () => _openAdd(context),
                      ),
                    ],
                  ),

                  if (friends.isEmpty && incomingRequests.isEmpty)
                    SliverFillRemaining(
                      child:
                          _EmptyFriends(onAddTap: () => _openAdd(context)),
                    )
                  else ...[
                    // Incoming requests section
                    if (incomingRequests.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: _SectionLabel(
                            'Requests (${incomingRequests.length})',
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: incomingRequests.length,
                        itemBuilder: (context, i) =>
                            _FriendRequestCard(
                          request: incomingRequests[i],
                          onAccept: () => context
                              .read<FriendsCubit>()
                              .acceptRequest(incomingRequests[i]),
                          onDecline: () => context
                              .read<FriendsCubit>()
                              .declineRequest(incomingRequests[i].id),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ],

                    // Friends section
                    if (friends.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child:
                              _SectionLabel('Friends (${friends.length})'),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, i) => _FriendCard(
                          friend: friends[i],
                          onRemove: () =>
                              _confirmRemove(context, friends[i]),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              ),
            ),
        };
      },
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddFriendScreen(user: user),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text('Remove ${friend.nickname} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<FriendsCubit>().removeFriend(user.uid, friend.uid);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  const _FriendRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = request.fromNickname.isNotEmpty
        ? request.fromNickname[0].toUpperCase()
        : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kNotiMePrimary.withValues(alpha: 0.25),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fromNickname,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    request.fromTagId,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: kMonoFontFamily,
                      color: cs.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade600),
                  onPressed: onAccept,
                  tooltip: 'Accept',
                ),
                IconButton(
                  icon: Icon(Icons.cancel_rounded,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                  onPressed: onDecline,
                  tooltip: 'Decline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.onRemove});

  final Friend friend;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial =
        friend.nickname.isNotEmpty ? friend.nickname[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.surfaceContainerHigh,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.nickname,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    friend.tagId,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: kMonoFontFamily,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.person_remove_rounded,
                  size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
              onPressed: onRemove,
              tooltip: 'Remove friend',
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsLoadingSkeleton extends StatelessWidget {
  const _FriendsLoadingSkeleton();

  static final _fakeFriends = [
    const Friend(uid: '1', nickname: 'Alex Johnson', tagId: '#AB12'),
    const Friend(uid: '2', nickname: 'Maria Garcia', tagId: '#CD34'),
    const Friend(uid: '3', nickname: 'Sam Wilson', tagId: '#EF56'),
    const Friend(uid: '4', nickname: 'Taylor Lee', tagId: '#GH78'),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('Friends'),
              backgroundColor: Colors.transparent,
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Friends (${_fakeFriends.length})',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            SliverList.builder(
              itemCount: _fakeFriends.length,
              itemBuilder: (_, i) => _FriendCard(
                friend: _fakeFriends[i],
                onRemove: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomOffset = MediaQuery.of(context).padding.bottom + 64;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomOffset),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/catcos.jpg',
                width: 160,
                height: 160,
                color: kNotiMePrimary,
                colorBlendMode: BlendMode.modulate,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                'No friends yet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Add friends by their tag\nso you can invite them to channels.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add friend'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

