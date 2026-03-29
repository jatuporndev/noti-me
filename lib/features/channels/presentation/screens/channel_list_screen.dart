import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/channel_summary.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/channel_repository.dart';
import 'package:noti_me/domain/repositories/reminder_repository.dart';

import '../bloc/channel_detail/channel_detail_cubit.dart';
import '../bloc/channel_list/channel_list_cubit.dart';
import '../bloc/channel_list/channel_list_state.dart';
import 'channel_detail_screen.dart';
import 'create_channel_screen.dart';

class ChannelListScreen extends StatelessWidget {
  const ChannelListScreen({super.key, required this.user});

  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelListCubit, ChannelListState>(
      builder: (context, state) {
        return switch (state) {
          ChannelListLoading() => const _LoadingScaffold(),
          ChannelListError(:final message) => _ErrorScaffold(message: message),
          ChannelListLoaded(:final channels) => Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: const Text('Channels'),
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    floating: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'New channel',
                        onPressed: () => _openCreate(context),
                      ),
                    ],
                  ),
                  if (channels.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyChannels(
                          onCreateTap: () => _openCreate(context)),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      sliver: SliverList.builder(
                        itemCount: channels.length,
                        itemBuilder: (context, i) => _ChannelCard(
                          channel: channels[i],
                          onTap: () =>
                              _openDetail(context, channels[i].channelId),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        };
      },
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateChannelScreen(user: user),
      ),
    );
  }

  void _openDetail(BuildContext context, String channelId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => ChannelDetailCubit(
            channelRepository: sl<ChannelRepository>(),
            reminderRepository: sl<ReminderRepository>(),
            channelId: channelId,
          ),
          child: ChannelDetailScreen(user: user),
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  static const _fakeChannels = [
    ('My Reminders', 'owner'),
    ('Work Team', 'member'),
    ('Family Group', 'owner'),
    ('Project Alpha', 'member'),
    ('Daily Standups', 'member'),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('Channels'),
              backgroundColor: Colors.transparent,
              pinned: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              sliver: SliverList.builder(
                itemCount: _fakeChannels.length,
                itemBuilder: (_, i) => _ChannelCard(
                  channel: ChannelSummary(
                    channelId: 'fake_$i',
                    name: _fakeChannels[i].$1,
                    role: _fakeChannels[i].$2,
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Channels'),
            backgroundColor: Colors.transparent,
            pinned: true,
          ),
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading channels\n$message',
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.channel, required this.onTap});

  final ChannelSummary channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOwner = channel.role == 'owner';
    final initial =
        channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '#';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kNotiMePrimary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isOwner) ...[
                          Icon(Icons.star_rounded,
                              size: 13,
                              color: kNotiMePrimary.withValues(alpha: 0.9)),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          isOwner ? 'Owner' : 'Member',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChannels extends StatelessWidget {
  const _EmptyChannels({required this.onCreateTap});

  final VoidCallback onCreateTap;

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
                'No channels yet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a channel to start sending\nreminders to yourself or your group.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create channel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

