import 'package:flutter/material.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/channel_repository.dart';
import 'package:noti_me/domain/repositories/user_repository.dart';

class RedeemCodeScreen extends StatefulWidget {
  const RedeemCodeScreen({super.key, required this.user});

  final SessionUser user;

  @override
  State<RedeemCodeScreen> createState() => _RedeemCodeScreenState();
}

class _RedeemCodeScreenState extends State<RedeemCodeScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      final channel =
          await sl<ChannelRepository>().findChannelByInviteCode(code);
      if (channel == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid invite code')));
        }
        return;
      }
      final profile =
          await sl<UserRepository>().watchUserProfile(widget.user.uid).first;
      await sl<ChannelRepository>().joinChannel(
        channelId: channel.id,
        channelName: channel.name,
        uid: widget.user.uid,
        nickname: profile.nickname,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined ${channel.name}')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Join with code')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Illustration
            Center(
              child: Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: kNotiMePrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_rounded,
                    size: 36, color: kNotiMePrimary.withValues(alpha: 0.85)),
              ),
            ),
            Text(
              'Enter the invite code shared by a channel owner.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Invite code',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
              style: TextStyle(
                fontFamily: kMonoFontFamily,
                letterSpacing: 2,
                fontSize: 16,
              ),
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _redeem(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _redeem,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black54)),
                    )
                  : const Text('Join channel'),
            ),
          ],
        ),
      ),
    );
  }
}
