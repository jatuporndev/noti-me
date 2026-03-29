import 'package:flutter/material.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/repositories/reminder_repository.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({
    super.key,
    required this.channelId,
    required this.createdByUid,
  });

  final String channelId;
  final String createdByUid;

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _scheduleKind = 'daily';
  String _timeSlot = 'morning';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await sl<ReminderRepository>().createReminder(
        channelId: widget.channelId,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        scheduleKind: _scheduleKind,
        timeSlot: _timeSlot,
        createdByUid: widget.createdByUid,
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
        title: const Text('New reminder'),
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
            // ── Title ──────────────────────────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.alarm_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),

            const SizedBox(height: 28),

            // ── Schedule ───────────────────────────────────────────────────
            _PickerLabel(
              icon: Icons.repeat_rounded,
              label: 'Schedule',
            ),
            const SizedBox(height: 10),
            _ScheduleSegmentedButton(
              value: _scheduleKind,
              onChanged: (v) => setState(() => _scheduleKind = v),
            ),

            const SizedBox(height: 24),

            // ── Time slot ─────────────────────────────────────────────────
            _PickerLabel(
              icon: Icons.schedule_rounded,
              label: 'Time slot',
            ),
            const SizedBox(height: 10),
            _TimeSlotPicker(
              value: _timeSlot,
              onChanged: (v) => setState(() => _timeSlot = v),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black54)),
                    )
                  : const Text('Create reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PickerLabel extends StatelessWidget {
  const _PickerLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}

class _ScheduleSegmentedButton extends StatelessWidget {
  const _ScheduleSegmentedButton({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('daily', 'Every day'),
    ('weekdays', 'Weekdays'),
    ('once', 'Once'),
  ];

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: kNotiMePrimary.withValues(alpha: 0.25),
        selectedForegroundColor: Colors.black87,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      segments: _options
          .map((o) => ButtonSegment<String>(value: o.$1, label: Text(o.$2)))
          .toList(),
    );
  }
}

class _TimeSlotPicker extends StatelessWidget {
  const _TimeSlotPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _slots = [
    _SlotInfo('morning', 'Morning', '08:30', Icons.wb_sunny_outlined),
    _SlotInfo('noon', 'Noon', '12:00', Icons.lunch_dining_outlined),
    _SlotInfo('evening', 'Evening', '17:30', Icons.nights_stay_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _slots.map((slot) {
        final selected = value == slot.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _SlotCard(
              slot: slot,
              selected: selected,
              onTap: () => onChanged(slot.key),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final _SlotInfo slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? kNotiMePrimary.withValues(alpha: 0.25)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? kNotiMePrimary.withValues(alpha: 0.7)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              slot.icon,
              size: 22,
              color: selected
                  ? Colors.black87
                  : cs.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 6),
            Text(
              slot.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: kFontFamily,
                color: selected
                    ? Colors.black87
                    : cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              slot.time,
              style: TextStyle(
                fontSize: 11,
                fontFamily: kMonoFontFamily,
                color: selected
                    ? Colors.black.withValues(alpha: 0.5)
                    : cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotInfo {
  const _SlotInfo(this.key, this.label, this.time, this.icon);

  final String key;
  final String label;
  final String time;
  final IconData icon;
}
