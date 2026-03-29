import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/session_user.dart';

import '../../../reminders/presentation/screens/create_reminder_screen.dart';
import '../../../invites/presentation/screens/send_invite_screen.dart';
import '../bloc/channel_detail/channel_detail_cubit.dart';
import '../bloc/channel_detail/channel_detail_state.dart';

class ChannelDetailScreen extends StatelessWidget {
  const ChannelDetailScreen({super.key, required this.user});

  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelDetailCubit, ChannelDetailState>(
      builder: (context, state) {
        return switch (state) {
          ChannelDetailLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ChannelDetailError(:final message) => Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(message)),
            ),
          ChannelDetailLoaded(:final channel, :final members, :final reminders) =>
            Scaffold(
              appBar: AppBar(
                title: Text(
                  channel.name,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  // Add reminder
                  IconButton(
                    icon: const Icon(Icons.add_alarm_rounded),
                    tooltip: 'Add reminder',
                    onPressed: () => _openCreateReminder(context, channel),
                  ),

                  // Members sheet button
                  IconButton(
                    icon: Badge(
                      label: Text('${members.length}'),
                      child: const Icon(Icons.people_outline_rounded),
                    ),
                    tooltip: 'Members',
                    onPressed: () => _showMembersSheet(context, members),
                  ),

                  // Overflow menu
                  PopupMenuButton<_MenuAction>(
                    icon: const Icon(Icons.more_vert_rounded),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (action) =>
                        _handleMenu(context, action, channel),
                    itemBuilder: (_) => [
                      if (channel.inviteCode != null)
                        PopupMenuItem(
                          value: _MenuAction.invite,
                          child: _MenuItem(
                            icon: Icons.person_add_alt_1_rounded,
                            label: 'Invite / Share code',
                          ),
                        ),
                      if (channel.createdByUid == user.uid)
                        PopupMenuItem(
                          value: _MenuAction.delete,
                          child: _MenuItem(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete channel',
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // ── Reminders list ──────────────────────────────────────────
              body: reminders.isEmpty
                  ? _EmptyReminders(
                      onAdd: () => _openCreateReminder(context, channel))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: reminders.length,
                      itemBuilder: (context, i) {
                        final r = reminders[i];
                        return Dismissible(
                          key: ValueKey(r.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.red),
                          ),
                          confirmDismiss: (_) => showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete reminder?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .error),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) => context
                              .read<ChannelDetailCubit>()
                              .deleteReminder(r.id),
                          child: _ReminderCard(
                            title: r.title,
                            slotLabel: _slotLabel(r.timeSlot),
                            scheduleKind: r.scheduleKind,
                            enabled: r.enabled,
                            onToggle: (v) => context
                                .read<ChannelDetailCubit>()
                                .toggleReminderEnabled(r.id, v),
                          ),
                        );
                      },
                    ),

            ),
        };
      },
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _handleMenu(
      BuildContext context, _MenuAction action, dynamic channel) async {
    switch (action) {
      case _MenuAction.invite:
        _showInviteSheet(context, channel);
      case _MenuAction.delete:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete channel?'),
            content:
                const Text('This will remove all reminders and members.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await context
              .read<ChannelDetailCubit>()
              .deleteChannel(user.uid);
          if (context.mounted) Navigator.of(context).pop();
        }
    }
  }

  void _showMembersSheet(BuildContext context, List<dynamic> members) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MembersSheet(members: members),
    );
  }

  void _showInviteSheet(BuildContext context, dynamic channel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _InviteSheet(
        inviteCode: channel.inviteCode ?? '',
        onInviteFriend: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SendInviteScreen(
                channelId: channel.id,
                channelName: channel.name,
                user: user,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCreateReminder(BuildContext context, dynamic channel) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateReminderScreen(
          channelId: channel.id,
          createdByUid: user.uid,
        ),
      ),
    );
  }

  String _slotLabel(String slot) => switch (slot) {
        'morning' => '08:30',
        'noon' => '12:00',
        'evening' => '17:30',
        _ => slot,
      };
}

enum _MenuAction { invite, delete }

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: c)),
      ],
    );
  }
}

// ── Members bottom sheet ──────────────────────────────────────────────────────

class _MembersSheet extends StatelessWidget {
  const _MembersSheet({required this.members});

  final List<dynamic> members;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Text(
                  'Members',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kNotiMePrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${members.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: members.length,
              itemBuilder: (_, i) {
                final m = members[i];
                final name = m.nickname ?? m.uid;
                final initial =
                    name.isNotEmpty ? name[0].toUpperCase() : '?';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kNotiMePrimary.withValues(alpha: 0.2),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  title: Text(name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    m.role == 'owner' ? 'Owner' : 'Member',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                  trailing: m.muted
                      ? Icon(Icons.notifications_off_outlined,
                          size: 16,
                          color: cs.onSurface.withValues(alpha: 0.35))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invite bottom sheet ───────────────────────────────────────────────────────

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({
    required this.inviteCode,
    required this.onInviteFriend,
  });

  final String inviteCode;
  final VoidCallback onInviteFriend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Invite to channel',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Invite code row
          Text(
            'Invite code',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inviteCode,
                    style: TextStyle(
                      fontFamily: kMonoFontFamily,
                      fontSize: 18,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                _CopyButton(text: inviteCode),
              ],
            ),
          ),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onInviteFriend,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Invite a friend by tag'),
          ),
        ],
      ),
    );
  }
}

// ── Reminder card ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.slotLabel,
    required this.scheduleKind,
    required this.enabled,
    required this.onToggle,
  });

  final String title;
  final String slotLabel;
  final String scheduleKind;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: enabled
                    ? kNotiMePrimary.withValues(alpha: 0.2)
                    : cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.alarm_rounded,
                size: 20,
                color: enabled
                    ? Colors.black87
                    : cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.4),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$slotLabel · $scheduleKind',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}

// ── Copy button ───────────────────────────────────────────────────────────────

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _copied
          ? Icon(Icons.check_rounded,
              key: const ValueKey('check'),
              color: Colors.green.shade600,
              size: 22)
          : IconButton(
              key: const ValueKey('copy'),
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: _copy,
            ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/catcos.jpg',
              width: 150,
              height: 150,
              color: kNotiMePrimary,
              colorBlendMode: BlendMode.modulate,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              'No reminders yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap ⏰ above to add the first reminder\nfor this channel.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
