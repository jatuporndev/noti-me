import 'package:flutter/material.dart';

import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/core/utils/bangkok_calendar.dart';

enum _NotifyDayChoice { today, tomorrow, custom }

/// Channel-level digest windows (morning/noon/evening) plus first active Bangkok day.
class ChannelNotifySchedulePicker extends StatefulWidget {
  const ChannelNotifySchedulePicker({
    super.key,
    required this.initialSlots,
    required this.initialNotifyStartDateBangkok,
    this.initialRepeatDaily = false,
    this.onChanged,
  });

  final Set<String> initialSlots;
  final String initialNotifyStartDateBangkok;

  /// Whether the channel repeats every day. Defaults to false (one-time).
  final bool initialRepeatDaily;
  final VoidCallback? onChanged;

  @override
  ChannelNotifySchedulePickerState createState() =>
      ChannelNotifySchedulePickerState();
}

class ChannelNotifySchedulePickerState extends State<ChannelNotifySchedulePicker> {
  late Set<String> _slots;
  late _NotifyDayChoice _dayChoice;
  DateTime? _customDate;
  late bool _repeatDaily;

  Set<String> get selectedSlots => Set<String>.unmodifiable(_slots);

  bool get repeatDaily => _repeatDaily;

  /// yyyy-MM-dd (Bangkok calendar).
  String get notifyStartDateBangkok => switch (_dayChoice) {
        _NotifyDayChoice.today => formatYmd(bangkokTodayCalendar),
        _NotifyDayChoice.tomorrow =>
          formatYmd(bangkokTodayCalendar.add(const Duration(days: 1))),
        _NotifyDayChoice.custom =>
          formatYmd(_customDate ?? bangkokTodayCalendar),
      };

  @override
  void initState() {
    super.initState();
    _slots = {...widget.initialSlots};
    _repeatDaily = widget.initialRepeatDaily;
    _restoreDayChoice(widget.initialNotifyStartDateBangkok);
  }

  void _restoreDayChoice(String ymd) {
    final today = bangkokTodayCalendar;
    final tomorrow = today.add(const Duration(days: 1));
    final parsed = parseYmd(ymd);
    if (parsed == null || ymd == kNotifyStartLegacyOpen) {
      _dayChoice = _NotifyDayChoice.today;
      _customDate = today;
      return;
    }
    if (isSameCalendarDay(parsed, today)) {
      _dayChoice = _NotifyDayChoice.today;
      _customDate = today;
    } else if (isSameCalendarDay(parsed, tomorrow)) {
      _dayChoice = _NotifyDayChoice.tomorrow;
      _customDate = tomorrow;
    } else {
      _dayChoice = _NotifyDayChoice.custom;
      _customDate = parsed;
    }
  }

  void _notifyParent() => widget.onChanged?.call();

  void _toggleSlot(String slot) {
    setState(() {
      if (_slots.contains(slot)) {
        _slots.remove(slot);
      } else {
        _slots.add(slot);
      }
    });
    _notifyParent();
  }

  Future<void> _pickCustomDate() async {
    final today = bangkokTodayCalendar;
    final initial = _customDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
      helpText: 'First reminder day (Bangkok)',
    );
    if (picked != null && mounted) {
      setState(() {
        _dayChoice = _NotifyDayChoice.custom;
        _customDate = DateTime(picked.year, picked.month, picked.day);
      });
      _notifyParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = bangkokTodayCalendar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When to send reminders',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 10),
        _ChannelSlotPicker(selected: _slots, onToggle: _toggleSlot),
        const SizedBox(height: 22),
        Text(
          'Starting day',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bangkok date +7 · then repeats every day at the times you pick.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.48),
                height: 1.35,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Today'),
              selected: _dayChoice == _NotifyDayChoice.today,
              onSelected: (_) {
                setState(() {
                  _dayChoice = _NotifyDayChoice.today;
                  _customDate = today;
                });
                _notifyParent();
              },
            ),
            ChoiceChip(
              label: const Text('Tomorrow'),
              selected: _dayChoice == _NotifyDayChoice.tomorrow,
              onSelected: (_) {
                setState(() {
                  _dayChoice = _NotifyDayChoice.tomorrow;
                  _customDate = today.add(const Duration(days: 1));
                });
                _notifyParent();
              },
            ),
            ChoiceChip(
              label: const Text('Custom'),
              selected: _dayChoice == _NotifyDayChoice.custom,
              onSelected: (_) {
                setState(() {
                  _dayChoice = _NotifyDayChoice.custom;
                  _customDate ??= today;
                });
                _notifyParent();
              },
            ),
          ],
        ),
        if (_dayChoice == _NotifyDayChoice.custom) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickCustomDate,
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            label: Text(
              _customDate != null
                  ? formatYmd(_customDate!)
                  : 'Pick a date',
              style: const TextStyle(fontFamily: kMonoFontFamily),
            ),
          ),
        ],

        const SizedBox(height: 22),
        Text(
          'Repeat',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 8),
        Material(
          color: _repeatDaily
              ? kNotiMePrimary.withValues(alpha: 0.12)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _repeatDaily = !_repeatDaily);
              _notifyParent();
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _repeatDaily
                          ? Icons.repeat_rounded
                          : Icons.looks_one_rounded,
                      key: ValueKey(_repeatDaily),
                      size: 22,
                      color: _repeatDaily
                          ? Colors.black87
                          : cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _repeatDaily ? 'Repeat every day' : 'One-time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: kFontFamily,
                            color: _repeatDaily
                                ? Colors.black87
                                : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _repeatDaily
                              ? 'Fires at selected times daily'
                              : 'Fires once on the start date only',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: kFontFamily,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _repeatDaily,
                    onChanged: (v) {
                      setState(() => _repeatDaily = v);
                      _notifyParent();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelSlotPicker extends StatelessWidget {
  const _ChannelSlotPicker({
    required this.selected,
    required this.onToggle,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  static const _slots = [
    _ChannelSlotInfo('morning', 'Morning', '08:30', Icons.wb_sunny_outlined),
    _ChannelSlotInfo('noon', 'Noon', '12:00', Icons.lunch_dining_outlined),
    _ChannelSlotInfo('evening', 'Evening', '17:30', Icons.nights_stay_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _slots.map((slot) {
        final isSelected = selected.contains(slot.key);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ChannelSlotCard(
              slot: slot,
              selected: isSelected,
              onTap: () => onToggle(slot.key),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChannelSlotCard extends StatelessWidget {
  const _ChannelSlotCard({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final _ChannelSlotInfo slot;
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
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _ChannelSlotInfo {
  const _ChannelSlotInfo(this.key, this.label, this.time, this.icon);

  final String key;
  final String label;
  final String time;
  final IconData icon;
}
