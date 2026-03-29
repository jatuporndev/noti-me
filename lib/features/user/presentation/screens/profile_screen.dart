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
  bool _editingNickname = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    setState(() => _savingNickname = true);
    try {
      await context
          .read<ProfileCubit>()
          .saveNickname(_nicknameController.text.trim());
      if (mounted) {
        setState(() => _editingNickname = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nickname updated')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNickname = false);
    }
  }

  void _showQrSheet(String tagId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrBottomSheet(tagId: tagId),
    );
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
                      editingNickname: _editingNickname,
                      onEditNickname: () =>
                          setState(() => _editingNickname = true),
                      onCancelEdit: () => setState(() {
                        _editingNickname = false;
                        _nicknameController.text = profile.nickname;
                      }),
                      onSaveNickname: _saveNickname,
                      onShowQr: () => _showQrSheet(profile.tagId),
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

// ── Body ──────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.nickname,
    required this.tagId,
    required this.nicknameController,
    required this.savingNickname,
    required this.editingNickname,
    required this.onEditNickname,
    required this.onCancelEdit,
    required this.onSaveNickname,
    required this.onShowQr,
    required this.onSignOut,
  });

  final String nickname;
  final String tagId;
  final TextEditingController nicknameController;
  final bool savingNickname;
  final bool editingNickname;
  final VoidCallback onEditNickname;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveNickname;
  final VoidCallback onShowQr;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero header ──────────────────────────────────────────────────────
        _ProfileHeroCard(nickname: nickname, tagId: tagId),

        const SizedBox(height: 20),

        // ── Connect ──────────────────────────────────────────────────────────
        _SectionLabel(label: 'Connect'),
        Card(
          child: ListTile(
            leading: const _IconBox(
              color: kNotiMePrimary,
              icon: Icons.qr_code_2_rounded,
            ),
            title: const Text(
              'My QR Code',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Show QR for others to scan'),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            onTap: onShowQr,
          ),
        ),

        const SizedBox(height: 16),

        // ── Identity ─────────────────────────────────────────────────────────
        _SectionLabel(label: 'Identity'),
        Card(
          child: Column(
            children: [
              // Nickname row — static or edit mode
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: editingNickname
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: ListTile(
                  leading: const _IconBox(
                    color: kNotiMePrimary,
                    icon: Icons.badge_rounded,
                  ),
                  title: const Text(
                    'Nickname',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    nickname.isEmpty ? 'Tap to set a nickname' : nickname,
                    style: TextStyle(
                      color: nickname.isEmpty
                          ? cs.onSurface.withValues(alpha: 0.35)
                          : cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  trailing: Icon(
                    Icons.edit_rounded,
                    size: 17,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                  onTap: onEditNickname,
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nickname',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nicknameController,
                        autofocus: editingNickname,
                        decoration: const InputDecoration(
                          hintText: 'Shown to friends in the app',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: savingNickname ? null : onCancelEdit,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed:
                                  savingNickname ? null : onSaveNickname,
                              child: savingNickname
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, indent: 16, endIndent: 16),

              // Tag ID row
              ListTile(
                leading: const _IconBox(
                  color: kNotiMePrimary,
                  icon: Icons.tag_rounded,
                ),
                title: const Text(
                  'Tag ID',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tagId,
                  style: const TextStyle(
                    fontFamily: kMonoFontFamily,
                    letterSpacing: 1.1,
                  ),
                ),
                trailing: _CopyButton(value: tagId),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Account ──────────────────────────────────────────────────────────
        _SectionLabel(label: 'Account'),
        Card(
          child: ListTile(
            leading: const _IconBox(
              color: kNotiMePrimary,
              icon: Icons.logout_rounded,
            ),
            title: const Text(
              'Sign out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            onTap: onSignOut,
          ),
        ),
      ],
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.nickname, required this.tagId});

  final String nickname;
  final String tagId;

  @override
  Widget build(BuildContext context) {
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    const deepBrown = Color(0xFF3D2400);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: kNotiMePrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.30),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: deepBrown,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname.isEmpty ? 'Set a nickname →' : nickname,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: nickname.isEmpty
                          ? deepBrown.withValues(alpha: 0.40)
                          : deepBrown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 12,
                        color: deepBrown.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        tagId,
                        style: TextStyle(
                          fontFamily: kMonoFontFamily,
                          fontSize: 11,
                          letterSpacing: 1.3,
                          color: deepBrown.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 16, bottom: 5),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.42),
            ),
      ),
    );
  }
}

// ── Icon box ──────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  const _IconBox({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: Colors.black87),
    );
  }
}

// ── Copy button ───────────────────────────────────────────────────────────────

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tag ID copied')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy_rounded,
              size: 13,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Copy',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── QR bottom sheet ───────────────────────────────────────────────────────────

class _QrBottomSheet extends StatelessWidget {
  const _QrBottomSheet({required this.tagId});
  final String tagId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Heading
          const Text(
            'My QR Code',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Let others scan to add you as a friend',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 24),

          // QR card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: kNotiMePrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kNotiMePrimary.withValues(alpha: 0.15),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top accent banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: const BoxDecoration(
                    color: kNotiMePrimary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'NotiMe · Scan to add me',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D2400),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                // QR image
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 22, 32, 14),
                  child: QrImageView(
                    data: tagId,
                    version: QrVersions.auto,
                    size: 210,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFFB87028),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),

                // Tag chip
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kNotiMePrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 13,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tagId,
                        style: const TextStyle(
                          fontFamily: kMonoFontFamily,
                          fontSize: 13,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D2400),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Close button
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: kNotiMePrimary,
              foregroundColor: const Color(0xFF3D2400),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
