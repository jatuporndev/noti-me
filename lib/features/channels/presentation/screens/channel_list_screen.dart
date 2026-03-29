import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/core/utils/bangkok_calendar.dart';
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
                    pinned: true,
                    floating: false,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    toolbarHeight: 52,
                    title: Builder(
                      builder: (context) {
                        // Compute the exact header background colour so
                        // BlendMode.multiply makes the jpg white background
                        // perfectly invisible against the gradient.
                        final headerBg = Color.alphaBlend(
                          kNotiMePrimary.withValues(alpha: 0.22),
                          Theme.of(context).colorScheme.surface,
                        );
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'notiMe',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/catcos.jpg',
                              height: 32,
                              fit: BoxFit.contain,
                              // white × headerBg = headerBg → invisible bg
                              // black × headerBg ≈ black → lines stay visible
                              color: headerBg,
                              colorBlendMode: BlendMode.multiply,
                            ),
                          ],
                        );
                      },
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 20, bottom: 10),
                          child: Text(
                            "don't forget anything",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.38),
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'New channel',
                        onPressed: () => _openCreate(context),
                      ),
                    ],
                    flexibleSpace: const _DashboardHeader(),
                  ),
                  if (channels.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyChannels(
                          onCreateTap: () => _openCreate(context)),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          'Channels',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.45),
                                letterSpacing: 0.6,
                              ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 2, bottom: 24),
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

  static const _palette = [
    Color(0xFFFFC26C),
    Color(0xFFADD8E6),
    Color(0xFFB5EAD7),
    Color(0xFFCDB4DB),
    Color(0xFFFDCBA3),
    Color(0xFF9ED8DB),
    Color(0xFFF7E999),
  ];

  Color _avatarColor() {
    if (channel.name.isEmpty) return _palette[0];
    return _palette[channel.name.codeUnitAt(0) % _palette.length];
  }

  /// Returns the notify-start date label: Today / Tomorrow / yyyy-MM-dd.
  /// Falls back to a relative joined-at label for legacy channels.
  ({String label, bool isStartDate}) _dateInfo() {
    final ymd = channel.notifyStartDateBangkok;
    if (ymd != null && ymd.isNotEmpty && ymd != '1970-01-01') {
      final parsed = parseYmd(ymd);
      if (parsed != null) {
        final today = bangkokTodayCalendar;
        final tomorrow = today.add(const Duration(days: 1));
        if (isSameCalendarDay(parsed, today)) {
          return (label: 'Today', isStartDate: true);
        } else if (isSameCalendarDay(parsed, tomorrow)) {
          return (label: 'Tomorrow', isStartDate: true);
        }
      }
      return (label: ymd, isStartDate: true);
    }
    final dt = channel.joinedAt;
    if (dt == null) return (label: '', isStartDate: false);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return (label: 'Today', isStartDate: false);
    if (diff.inDays < 7) return (label: '${diff.inDays}d ago', isStartDate: false);
    if (diff.inDays < 31) return (label: '${(diff.inDays / 7).floor()}w ago', isStartDate: false);
    if (diff.inDays < 366) return (label: '${(diff.inDays / 30).floor()}mo ago', isStartDate: false);
    return (label: '${(diff.inDays / 365).floor()}y ago', isStartDate: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOwner = channel.role == 'owner';
    final initial =
        channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '#';
    final bg = _avatarColor();
    final dateInfo = _dateInfo();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 21,
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
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? kNotiMePrimary.withValues(alpha: 0.2)
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOwner
                                    ? Icons.star_rounded
                                    : Icons.person_outline_rounded,
                                size: 11,
                                color: isOwner
                                    ? kNotiMePrimary.withValues(alpha: 0.85)
                                    : cs.onSurface.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isOwner ? 'Owner' : 'Member',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isOwner
                                      ? Colors.black87
                                      : cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (dateInfo.label.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Icon(
                            dateInfo.isStartDate
                                ? Icons.play_arrow_rounded
                                : Icons.access_time_rounded,
                            size: 11,
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            dateInfo.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: dateInfo.isStartDate
                                  ? kMonoFontFamily
                                  : null,
                              color: cs.onSurface.withValues(alpha: 0.38),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (channel.notifySlots != null &&
                        channel.notifySlots!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            size: 11,
                            color: cs.onSurface.withValues(alpha: 0.38),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            describeNotifySlots(channel.notifySlots!),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.38),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.25),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kNotiMePrimary.withValues(alpha: 0.22),
            kNotiMePrimary.withValues(alpha: 0.04),
          ],
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

