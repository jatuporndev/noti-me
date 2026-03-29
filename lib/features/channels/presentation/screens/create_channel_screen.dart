import 'package:flutter/material.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/core/utils/bangkok_calendar.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/channel_repository.dart';
import 'package:noti_me/domain/repositories/user_repository.dart';

import '../widgets/channel_notify_schedule_picker.dart';

class CreateChannelScreen extends StatefulWidget {
  const CreateChannelScreen({super.key, required this.user});

  final SessionUser user;

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends State<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _scheduleKey = GlobalKey<ChannelNotifySchedulePickerState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final sched = _scheduleKey.currentState;
    if (sched == null || sched.selectedSlots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick at least one time slot')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final profile =
          await sl<UserRepository>().watchUserProfile(widget.user.uid).first;
      await sl<ChannelRepository>().createChannel(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        uid: widget.user.uid,
        nickname: profile.nickname,
        notifySlots: sched.selectedSlots.toList(),
        notifyStartDateBangkok: sched.notifyStartDateBangkok,
        repeatDaily: sched.repeatDaily,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New channel'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ── Live preview ───────────────────────────────────────────────
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameCtrl,
              builder: (context, value, _) =>
                  _ChannelPreviewTile(name: value.text),
            ),
            const SizedBox(height: 24),

            // ── Section: Channel info ──────────────────────────────────────
            const _SectionLabel(label: 'Channel info'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Channel name',
                prefixIcon: Icon(Icons.campaign_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                final st = _scheduleKey.currentState;
                if (!_saving &&
                    st != null &&
                    st.selectedSlots.isNotEmpty) {
                  _submit();
                }
              },
            ),

            const SizedBox(height: 24),

            // ── Section: Notification times ────────────────────────────────
            const _SectionLabel(label: 'Notification times'),
            const SizedBox(height: 10),
            ChannelNotifySchedulePicker(
              key: _scheduleKey,
              initialSlots: {},
              initialNotifyStartDateBangkok:
                  formatYmd(bangkokTodayCalendar),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: (_saving ||
                      (_scheduleKey.currentState?.selectedSlots.isEmpty ??
                          true))
                  ? null
                  : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black54)),
                    )
                  : const Text('Create channel'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live preview tile ─────────────────────────────────────────────────────────

class _ChannelPreviewTile extends StatelessWidget {
  const _ChannelPreviewTile({required this.name});

  final String name;

  static const _palette = [
    Color(0xFFFFC26C),
    Color(0xFFADD8E6),
    Color(0xFFB5EAD7),
    Color(0xFFCDB4DB),
    Color(0xFFFDCBA3),
    Color(0xFF9ED8DB),
    Color(0xFFF7E999),
  ];

  Color _avatarColor() {
    if (name.isEmpty) return _palette[0];
    return _palette[name.codeUnitAt(0) % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bg = _avatarColor();
    final displayName = name.isNotEmpty ? name : 'Channel name';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: name.isEmpty
                            ? cs.onSurface.withValues(alpha: 0.3)
                            : cs.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: kNotiMePrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 11,
                          color: kNotiMePrimary.withValues(alpha: 0.85)),
                      const SizedBox(width: 3),
                      const Text(
                        'Owner',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Preview',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: kNotiMePrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.7),
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }
}
