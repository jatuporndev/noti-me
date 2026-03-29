import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/core/utils/bangkok_calendar.dart';
import 'package:noti_me/domain/entities/channel.dart';
import 'package:noti_me/domain/entities/reminder.dart';
import 'package:noti_me/domain/entities/session_user.dart';

import '../../../reminders/presentation/screens/create_reminder_screen.dart';
import '../../../invites/presentation/screens/send_invite_screen.dart';
import '../bloc/channel_detail/channel_detail_cubit.dart';
import '../bloc/channel_detail/channel_detail_state.dart';
import '../widgets/channel_notify_schedule_picker.dart';

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
                    icon: const Icon(Icons.people_outline_rounded),
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
                          value: _MenuAction.notificationSchedule,
                          child: const _MenuItem(
                            icon: Icons.schedule_rounded,
                            label: 'Notification schedule',
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
                      if (channel.createdByUid != user.uid)
                        PopupMenuItem(
                          value: _MenuAction.leave,
                          child: _MenuItem(
                            icon: Icons.exit_to_app_rounded,
                            label: 'Leave channel',
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // ── Reminders list ──────────────────────────────────────────
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _NotifyScheduleSummaryCard(
                      channel: channel,
                      canEdit: channel.createdByUid == user.uid,
                      onEdit: channel.createdByUid == user.uid
                          ? () => _openScheduleSheet(context, channel)
                          : null,
                    ),
                  ),
                  if (reminders.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyReminders(
                          onAdd: () =>
                              _openCreateReminder(context, channel)),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      sliver: SliverToBoxAdapter(
                        child: _ReminderGroupCard(
                          reminders: reminders,
                          cubit: context.read<ChannelDetailCubit>(),
                          scaffoldMessenger:
                              ScaffoldMessenger.maybeOf(context),
                          parentContext: context,
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

  // ── Actions ──────────────────────────────────────────────────────────────

  void _handleMenu(
      BuildContext context, _MenuAction action, Channel channel) async {
    switch (action) {
      case _MenuAction.invite:
        _showInviteSheet(context, channel);
      case _MenuAction.notificationSchedule:
        _openScheduleSheet(context, channel);
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
      case _MenuAction.leave:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Leave channel?'),
            content: Text(
                'You will no longer receive reminders from "${channel.name}".'),
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
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await context
              .read<ChannelDetailCubit>()
              .leaveChannel(user.uid);
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

  void _openScheduleSheet(BuildContext context, Channel channel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _NotificationScheduleSheet(
        channel: channel,
        userId: user.uid,
      ),
    );
  }

  void _showInviteSheet(BuildContext context, Channel channel) {
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

  void _openCreateReminder(BuildContext context, Channel channel) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateReminderScreen(
          channelId: channel.id,
          createdByUid: user.uid,
        ),
      ),
    );
  }
}

enum _MenuAction { invite, notificationSchedule, delete, leave }

// ── Notification schedule summary ─────────────────────────────────────────────

class _NotifyScheduleSummaryCard extends StatelessWidget {
  const _NotifyScheduleSummaryCard({
    required this.channel,
    required this.canEdit,
    this.onEdit,
  });

  final Channel channel;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final slots = describeNotifySlots(channel.notifySlots);
    final start =
        describeNotifyStartDateShort(channel.notifyStartDateBangkok);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canEdit ? onEdit : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 22, color: cs.onSurface.withValues(alpha: 0.55)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slots.isEmpty ? 'No time slots' : slots,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'From $start (+7)',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontFamily: kMonoFontFamily,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: channel.repeatDaily
                                  ? kNotiMePrimary.withValues(alpha: 0.18)
                                  : cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              channel.repeatDaily ? 'Daily' : 'Once',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: channel.repeatDaily
                                    ? Colors.black87
                                    : cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  Icon(Icons.edit_outlined,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationScheduleSheet extends StatefulWidget {
  const _NotificationScheduleSheet({
    required this.channel,
    required this.userId,
  });

  final Channel channel;
  final String userId;

  @override
  State<_NotificationScheduleSheet> createState() =>
      _NotificationScheduleSheetState();
}

class _NotificationScheduleSheetState extends State<_NotificationScheduleSheet> {
  final _pickerKey = GlobalKey<ChannelNotifySchedulePickerState>();
  bool _saving = false;

  Future<void> _save() async {
    final st = _pickerKey.currentState;
    if (st == null || st.selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one time slot')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ChannelDetailCubit>().updateNotificationSchedule(
            uid: widget.userId,
            notifySlots: st.selectedSlots.toList(),
            notifyStartDateBangkok: st.notifyStartDateBangkok,
            repeatDaily: st.repeatDaily,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notification schedule',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ChannelNotifySchedulePicker(
              key: _pickerKey,
              initialSlots: widget.channel.notifySlots.toSet(),
              initialNotifyStartDateBangkok:
                  widget.channel.notifyStartDateBangkok,
              initialRepeatDaily: widget.channel.repeatDaily,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

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

// ── Reminder group card (unified container for all reminders) ─────────────────

class _ReminderGroupCard extends StatelessWidget {
  const _ReminderGroupCard({
    required this.reminders,
    required this.cubit,
    required this.scaffoldMessenger,
    required this.parentContext,
  });

  final List<Reminder> reminders;
  final ChannelDetailCubit cubit;
  final ScaffoldMessengerState? scaffoldMessenger;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < reminders.length; i++) ...[
            _buildItem(context, reminders[i]),
            if (i < reminders.length - 1)
              Divider(
                height: 1,
                indent: 62,
                endIndent: 0,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, Reminder r) {
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade50,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: parentContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete reminder?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(dialogContext).colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        cubit.deleteReminder(r.id).catchError((Object e, _) {
          scaffoldMessenger?.showSnackBar(
            SnackBar(content: Text('Could not delete: $e')),
          );
        });
      },
      child: _ReminderRow(title: r.title, body: r.body),
    );
  }
}

// ── Reminder row (inside the unified group card) ──────────────────────────────

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kNotiMePrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alarm_rounded,
                size: 17, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (body != null && body!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    body!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.swipe_left_alt_rounded,
            size: 14,
            color: cs.onSurface.withValues(alpha: 0.18),
          ),
        ],
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
