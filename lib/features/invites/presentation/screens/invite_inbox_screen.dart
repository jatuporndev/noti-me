import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/channel_invite.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/user_repository.dart';

import '../bloc/invite_inbox_cubit.dart';
import '../bloc/invite_inbox_state.dart';
import 'redeem_code_screen.dart';

// Deterministic color per channel initial.
Color _channelColor(String name) {
  const palette = [
    Color(0xFF3A7BD5),
    Color(0xFF7C5CBF),
    Color(0xFF3AACB0),
    Color(0xFFE07B3A),
    Color(0xFFD94F6D),
    Color(0xFF3A9E78),
  ];
  if (name.isEmpty) return palette[0];
  return palette[name.codeUnitAt(0) % palette.length];
}

class InviteInboxScreen extends StatelessWidget {
  const InviteInboxScreen({super.key, required this.user});

  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InviteInboxCubit, InviteInboxState>(
      builder: (context, state) {
        return switch (state) {
          InviteInboxLoading() => const _InboxLoadingSkeleton(),
          InviteInboxError(:final message) => Scaffold(
              body: CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    title: Text('Inbox'),
                    backgroundColor: Colors.transparent,
                    pinned: true,
                  ),
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error: $message',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          InviteInboxLoaded(:final invites) => Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: const Text('Inbox'),
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_rounded),
                        tooltip: 'Enter invite code',
                        onPressed: () => _openRedeem(context),
                      ),
                    ],
                  ),
                  if (invites.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyInbox(
                        onRedeemTap: () => _openRedeem(context),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                        child: _SectionLabel('Invites · ${invites.length}'),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 100),
                      sliver: SliverList.builder(
                        itemCount: invites.length,
                        itemBuilder: (context, i) => _InviteCard(
                          invite: invites[i],
                          onAccept: () => _accept(
                            context,
                            invites[i].id,
                            invites[i].channelId,
                            invites[i].channelName,
                          ),
                          onDecline: () => context
                              .read<InviteInboxCubit>()
                              .declineInvite(invites[i].id),
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

  Future<void> _accept(
    BuildContext context,
    String inviteId,
    String channelId,
    String channelName,
  ) async {
    try {
      final profile =
          await sl<UserRepository>().watchUserProfile(user.uid).first;
      if (!context.mounted) return;
      await context.read<InviteInboxCubit>().acceptInvite(
            inviteId: inviteId,
            channelId: channelId,
            channelName: channelName,
            uid: user.uid,
            nickname: profile.nickname,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined $channelName')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _openRedeem(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RedeemCodeScreen(user: user),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.42),
          ),
    );
  }
}

// ── Invite card ───────────────────────────────────────────────────────────────

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final ChannelInvite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = invite.channelName.isNotEmpty
        ? invite.channelName[0].toUpperCase()
        : '#';
    final color = _channelColor(invite.channelName);
    final sender = invite.fromNickname ?? 'Someone';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: channel icon + name + sender
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Channel icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.channelName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.40),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Invited by $sender',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.50),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(38),
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: cs.outlineVariant),
                      foregroundColor: cs.onSurface.withValues(alpha: 0.60),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(38),
                      padding: EdgeInsets.zero,
                      backgroundColor: kNotiMePrimary,
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Join'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _InboxLoadingSkeleton extends StatelessWidget {
  const _InboxLoadingSkeleton();

  static const _fakeInvites = [
    ChannelInvite(
      id: '1',
      channelId: 'c1',
      channelName: 'Design Team',
      fromUid: 'u1',
      fromNickname: 'Alex Johnson',
      status: 'pending',
    ),
    ChannelInvite(
      id: '2',
      channelId: 'c2',
      channelName: 'Marketing',
      fromUid: 'u2',
      fromNickname: 'Sara Williams',
      status: 'pending',
    ),
    ChannelInvite(
      id: '3',
      channelId: 'c3',
      channelName: 'Backend Devs',
      fromUid: 'u3',
      fromNickname: 'Tom Smith',
      status: 'pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('Inbox'),
              backgroundColor: Colors.transparent,
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Text(
                  'INVITES · ${_fakeInvites.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList.builder(
                itemCount: _fakeInvites.length,
                itemBuilder: (_, i) => _InviteCard(
                  invite: _fakeInvites[i],
                  onAccept: () {},
                  onDecline: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onRedeemTap});

  final VoidCallback onRedeemTap;

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
                'Inbox is empty',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Channel invites from friends\nwill appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.52),
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: onRedeemTap,
                icon: const Icon(Icons.qr_code_rounded, size: 17),
                label: const Text('Enter invite code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
