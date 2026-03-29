import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/friend_repository.dart';
import 'package:noti_me/domain/repositories/invite_repository.dart';
import 'package:noti_me/domain/repositories/user_repository.dart';
import 'package:noti_me/features/friends/presentation/bloc/friends_cubit.dart';
import 'package:noti_me/features/friends/presentation/bloc/friends_state.dart';

class SendInviteScreen extends StatefulWidget {
  const SendInviteScreen({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.user,
  });

  final String channelId;
  final String channelName;
  final SessionUser user;

  @override
  State<SendInviteScreen> createState() => _SendInviteScreenState();
}

class _SendInviteScreenState extends State<SendInviteScreen> {
  final _tagCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _inviteByTag() async {
    final tag = _tagCtrl.text.trim();
    if (tag.isEmpty) return;
    setState(() => _sending = true);
    try {
      final friendRepo = sl<FriendRepository>();
      final info = await friendRepo.lookupUserByTag(tag);
      if (info == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found')));
        }
        return;
      }
      await _sendInvite(info['uid']!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendInvite(String toUid) async {
    final profile =
        await sl<UserRepository>().watchUserProfile(widget.user.uid).first;
    await sl<InviteRepository>().sendInvite(
      channelId: widget.channelId,
      channelName: widget.channelName,
      fromUid: widget.user.uid,
      fromNickname: profile.nickname,
      toUid: toUid,
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invite sent!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Invite to ${widget.channelName}'),
      ),
      body: BlocProvider(
        create: (_) => FriendsCubit(
          friendRepository: sl<FriendRepository>(),
          uid: widget.user.uid,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // ── By tag ────────────────────────────────────────────────────
            Text(
              'By tag',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      hintText: "Friend's tag",
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                        fontFamily: kMonoFontFamily, letterSpacing: 1.5),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _inviteByTag(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _sending ? null : _inviteByTag,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Send'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── From friends ──────────────────────────────────────────────
            Text(
              'From friends',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 10),
            BlocBuilder<FriendsCubit, FriendsState>(
              builder: (context, state) {
                if (state is! FriendsLoaded || state.friends.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No friends yet. Add friends first.',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 13),
                    ),
                  );
                }
                return Column(
                  children: state.friends.map((f) {
                    final initial = f.nickname.isNotEmpty
                        ? f.nickname[0].toUpperCase()
                        : '?';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              kNotiMePrimary.withValues(alpha: 0.2),
                          child: Text(
                            initial,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                        ),
                        title: Text(f.nickname),
                        subtitle: Text(
                          f.tagId,
                          style: TextStyle(
                              fontFamily: kMonoFontFamily,
                              fontSize: 11,
                              letterSpacing: 1),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.send_rounded, size: 20),
                          onPressed: () => _sendInvite(f.uid),
                          tooltip: 'Invite',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
