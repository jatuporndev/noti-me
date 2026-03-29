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
          const SnackBar(content: Text('Nickname saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNickname = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
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
            ProfileLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ProfileStreamError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load profile.\n$message',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ProfileLoaded(:final profile) => _ProfileBody(
                tagId: profile.tagId,
                nicknameController: _nicknameController,
                savingNickname: _savingNickname,
                onSaveNickname: _saveNickname,
              ),
          };
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.tagId,
    required this.nicknameController,
    required this.savingNickname,
    required this.onSaveNickname,
  });

  final String tagId;
  final TextEditingController nicknameController;
  final bool savingNickname;
  final VoidCallback onSaveNickname;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your tag',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SelectableText(
          tagId,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: tagId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tag copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 20),
              label: const Text('Copy tag'),
              style: FilledButton.styleFrom(
                backgroundColor: kNotiMePrimary,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: QrImageView(
            data: tagId,
            version: QrVersions.auto,
            size: 160,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Nickname',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nicknameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Shown to friends in the app',
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save nickname'),
        ),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: () async {
            final nav = Navigator.of(context);
            await context.read<ProfileCubit>().signOut();
            nav.popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
