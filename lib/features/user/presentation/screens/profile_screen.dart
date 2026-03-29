import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:noti_me/core/theme/app_theme.dart';

import '../bloc/profile/profile_cubit.dart';
import '../bloc/profile/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  bool _savingNickname = false;
  bool _showQr = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    setState(() => _savingNickname = true);
    try {
      await context.read<ProfileCubit>().saveNickname(_nicknameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname updated')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNickname = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) {
        if (current is! ProfileLoaded) return false;
        if (previous is! ProfileLoaded) return true;
        return previous.profile.nickname != current.profile.nickname;
      },
      listener: (context, state) {
        if (state is ProfileLoaded &&
            _nicknameController.text.isEmpty &&
            state.profile.nickname.isNotEmpty) {
          _nicknameController.text = state.profile.nickname;
        }
      },
      builder: (context, state) {
        return switch (state) {
          ProfileLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ProfileStreamError(:final message) => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load profile.\n$message',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ProfileLoaded(:final profile) => Scaffold(
              body: CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    title: Text('Profile'),
                    backgroundColor: Colors.transparent,
                    pinned: true,
                  ),
                  SliverToBoxAdapter(
                    child: _ProfileBody(
                      nickname: profile.nickname,
                      tagId: profile.tagId,
                      nicknameController: _nicknameController,
                      savingNickname: _savingNickname,
                      showQr: _showQr,
                      onToggleQr: () => setState(() => _showQr = !_showQr),
                      onSaveNickname: _saveNickname,
                      onSignOut: () async {
                        final nav = Navigator.of(context);
                        await context.read<ProfileCubit>().signOut();
                        nav.popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
        };
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.nickname,
    required this.tagId,
    required this.nicknameController,
    required this.savingNickname,
    required this.showQr,
    required this.onToggleQr,
    required this.onSaveNickname,
    required this.onSignOut,
  });

  final String nickname;
  final String tagId;
  final TextEditingController nicknameController;
  final bool savingNickname;
  final bool showQr;
  final VoidCallback onToggleQr;
  final VoidCallback onSaveNickname;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + name header card ───────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: kNotiMePrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/catcos.jpg',
                      color: kNotiMePrimary,
                      colorBlendMode: BlendMode.modulate,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname.isEmpty ? 'Set a nickname' : nickname,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: nickname.isEmpty
                                    ? cs.onSurface.withValues(alpha: 0.4)
                                    : cs.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        _TagChip(tagId: tagId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── QR code toggle card ─────────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.qr_code_rounded,
                      color: cs.onSurface.withValues(alpha: 0.6)),
                  title: const Text('My QR code'),
                  subtitle: const Text('Others can scan to find you'),
                  trailing: Icon(
                    showQr
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                  onTap: onToggleQr,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: showQr
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 20),
                              Container(
                                width: 180,
                                height: 180,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: tagId,
                                  version: QrVersions.auto,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Nickname section ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Nickname',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.3,
                  ),
            ),
          ),
          TextField(
            controller: nicknameController,
            decoration: const InputDecoration(
              hintText: 'Shown to friends in the app',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: savingNickname ? null : onSaveNickname,
            child: savingNickname
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Save nickname'),
          ),

          const SizedBox(height: 32),

          // ── Sign out ────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: tagId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tag copied')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tagId,
              style: TextStyle(
                fontFamily: kMonoFontFamily,
                fontSize: 11,
                letterSpacing: 1.2,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy_rounded,
                size: 11, color: cs.onSurface.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

