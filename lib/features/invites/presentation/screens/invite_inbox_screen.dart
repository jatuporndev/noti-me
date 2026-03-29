import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/channel_invite.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/user_repository.dart';

import '../bloc/invite_inbox_cubit.dart';
import '../bloc/invite_inbox_state.dart';
import 'redeem_code_screen.dart';

class InviteInboxScreen extends StatelessWidget {
  const InviteInboxScreen({super.key, required this.user});

  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InviteInboxCubit, InviteInboxState>(
      builder: (context, state) {
        return switch (state) {
          InviteInboxLoading() => Scaffold(
              body: CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    title: Text('Inbox'),
                    backgroundColor: Colors.transparent,
                    pinned: true,
                  ),
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
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
                        child: Text('Error: $message',
                            textAlign: TextAlign.center),
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
                          onRedeemTap: () => _openRedeem(context)),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.only(top: 4, bottom: 100),
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
              ),
            ),
        };
      },
    );
  }

  Future<void> _accept(BuildContext context, String inviteId,
      String channelId, String channelName) async {
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kNotiMePrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 19,
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
                    invite.channelName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'From ${invite.fromNickname ?? 'someone'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionChip(
                  label: 'Accept',
                  icon: Icons.check_rounded,
                  color: Colors.green.shade600,
                  onTap: onAccept,
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: kFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                'No invites',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'When someone invites you to a channel\nit will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: onRedeemTap,
                icon: const Icon(Icons.qr_code_rounded, size: 18),
                label: const Text('Enter invite code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

