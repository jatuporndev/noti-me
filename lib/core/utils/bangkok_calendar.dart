/// Wall-clock calendar in Asia/Bangkok (UTC+7, no DST) for digest scheduling.
library;

DateTime bangkokCalendarFromUtc(DateTime utc) {
  final shifted = utc.toUtc().add(const Duration(hours: 7));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

DateTime get bangkokTodayCalendar =>
    bangkokCalendarFromUtc(DateTime.now().toUtc());

String formatYmd(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime? parseYmd(String raw) {
  final parts = raw.trim().split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Firestore channels without this field — digest always allowed by date gate.
const kNotifyStartLegacyOpen = '1970-01-01';

List<String> orderedNotifySlots(Iterable<String> slots) {
  const order = ['morning', 'noon', 'evening'];
  return order.where(slots.contains).toList();
}

String describeNotifySlots(List<String> slots) {
  const labels = {
    'morning': 'Morning',
    'noon': 'Noon',
    'evening': 'Evening',
  };
  return orderedNotifySlots(slots).map((k) => labels[k] ?? k).join(', ');
}

String describeNotifyStartDateShort(String ymd) {
  if (ymd == kNotifyStartLegacyOpen) return 'Any day';
  final p = parseYmd(ymd);
  if (p == null) return ymd;
  return formatYmd(p);
}
