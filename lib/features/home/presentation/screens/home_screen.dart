import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/channel_repository.dart';
import 'package:noti_me/domain/repositories/friend_repository.dart';
import 'package:noti_me/domain/repositories/invite_repository.dart';
import 'package:noti_me/features/channels/presentation/bloc/channel_list/channel_list_cubit.dart';
import 'package:noti_me/features/channels/presentation/screens/channel_list_screen.dart';
import 'package:noti_me/features/friends/presentation/bloc/friends_cubit.dart';
import 'package:noti_me/features/friends/presentation/screens/friends_screen.dart';
import 'package:noti_me/features/invites/presentation/bloc/invite_inbox_cubit.dart';
import 'package:noti_me/features/invites/presentation/screens/invite_inbox_screen.dart';
import 'package:noti_me/features/user/presentation/bloc/profile/profile_cubit.dart';
import 'package:noti_me/features/user/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final SessionUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _labels = ['Channels', 'Inbox', 'Friends', 'Profile'];
  static const _icons = [
    Icons.campaign_outlined,
    Icons.inbox_outlined,
    Icons.people_outline,
    Icons.person_outline,
  ];
  static const _activeIcons = [
    Icons.campaign_rounded,
    Icons.inbox_rounded,
    Icons.people_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChannelListCubit(
            channelRepository: sl<ChannelRepository>(),
            uid: widget.user.uid,
          ),
        ),
        BlocProvider(
          create: (_) => InviteInboxCubit(
            inviteRepository: sl<InviteRepository>(),
            uid: widget.user.uid,
          ),
        ),
        BlocProvider(
          create: (_) => FriendsCubit(
            friendRepository: sl<FriendRepository>(),
            uid: widget.user.uid,
          ),
        ),
        BlocProvider(
          create: (_) => ProfileCubit(
            uid: widget.user.uid,
            watchUserProfile: sl(),
            updateNickname: sl(),
            signOut: sl(),
          ),
        ),
      ],
      child: Scaffold(
        // No AppBar here — each tab screen owns its SliverAppBar.
        extendBody: true,
        body: IndexedStack(
          index: _tabIndex,
          children: [
            ChannelListScreen(user: widget.user),
            InviteInboxScreen(user: widget.user),
            FriendsScreen(user: widget.user),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          destinations: List.generate(
            _labels.length,
            (i) => NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_activeIcons[i]),
              label: _labels[i],
            ),
          ),
        ),
      ),
    );
  }
}
