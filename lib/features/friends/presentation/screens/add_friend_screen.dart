import 'package:flutter/material.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/friend_repository.dart';
import 'package:noti_me/domain/repositories/user_repository.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key, required this.user});

  final SessionUser user;

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _tagCtrl = TextEditingController();
  bool _loading = false;
  Map<String, String>? _foundUser;

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final tag = _tagCtrl.text.trim();
    if (tag.isEmpty) return;
    setState(() {
      _loading = true;
      _foundUser = null;
    });
    try {
      final info = await sl<FriendRepository>().lookupUserByTag(tag);
      if (mounted) {
        if (info == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found')));
        }
        setState(() => _foundUser = info);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest() async {
    if (_foundUser == null) return;
    setState(() => _loading = true);
    try {
      final profile =
          await sl<UserRepository>().watchUserProfile(widget.user.uid).first;
      await sl<FriendRepository>().sendFriendRequest(
        fromUid: widget.user.uid,
        fromNickname: profile.nickname,
        fromTagId: profile.tagId,
        toUid: _foundUser!['uid']!,
        toNickname: _foundUser!['nickname']!,
        toTagId: _foundUser!['tagId']!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request sent!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add friend')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Enter your friend's tag ID to find them.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Tag ID',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                    style: TextStyle(
                        fontFamily: kMonoFontFamily, letterSpacing: 1.5),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _loading ? null : _lookup,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Search'),
                ),
              ],
            ),

            if (_foundUser != null) ...[
              const SizedBox(height: 24),
              _FoundUserCard(
                nickname: _foundUser!['nickname'] ?? '',
                tagId: _foundUser!['tagId'] ?? '',
                onSend: _loading ? null : _sendRequest,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FoundUserCard extends StatelessWidget {
  const _FoundUserCard({
    required this.nickname,
    required this.tagId,
    required this.onSend,
  });

  final String nickname;
  final String tagId;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: kNotiMePrimary.withValues(alpha: 0.2),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nickname,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              tagId,
              style: TextStyle(
                fontFamily: kMonoFontFamily,
                fontSize: 12,
                letterSpacing: 1.5,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Send friend request'),
            ),
          ],
        ),
      ),
    );
  }
}
