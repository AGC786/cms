/// Shared helpers for formatting the raw period-time strings returned by
/// the AIT SmartCampuses timetable endpoints.
///
/// The backend's `time1` (admin timetable) / `time` (faculty timetable)
/// field is a string like `"14:15 PM - 15:00 PM"` — the hour is emitted in
/// 24-hour notation but always has an `AM`/`PM` suffix appended, so
/// afternoon/evening periods show an hour greater than 12 next to `PM`
/// (e.g. "14:15 PM" instead of "2:15 PM"). [formatTimeRange] converts each
/// side of the range to a normal 12-hour clock display, trusting the
/// AM/PM suffix already present and only reformatting the hour/minute.
///
/// Parsing is defensive: any input that doesn't match the expected shape
/// is returned unchanged rather than throwing, so a stray backend format
/// change just shows the raw string instead of crashing the screen.
String formatTimeRange(String? raw) {
  if (raw == null) return '';
  final input = raw.trim();
  if (input.isEmpty) return input;

  final parts = input.split('-');
  if (parts.length != 2) return input;

  final start = _formatSingleTime(parts[0].trim());
  final end = _formatSingleTime(parts[1].trim());
  if (start == null || end == null) return input;

  return '$start - $end';
}

/// Formats a clock string into a 12-hour `"H:MM AM/PM"` display string.
///
/// Handles both shapes this backend actually sends:
///   * plain 24-hour `"HH:MM"` / `"HH:MM:SS"` (older attendance rows), and
///   * 12-hour `"HH:MM:SS AM/PM"` (the employee attendance report's
///     `sign_in`/`sign_out`) — the seconds are dropped and the given
///     AM/PM is trusted rather than re-derived from the hour.
///
/// Falls back to the raw string unchanged if it doesn't match either.
String formatClockTime(String? raw) {
  if (raw == null) return '';
  final input = raw.trim();
  if (input.isEmpty) return input;

  final match = _clockRe.firstMatch(input);
  if (match == null) return input;

  var hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return input;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return input;

  final explicit = match.group(3)?.toUpperCase();
  final String meridiem;
  if (explicit == 'AM' || explicit == 'PM') {
    meridiem = explicit!;
    if (explicit == 'PM' && hour < 12) hour += 12;
    if (explicit == 'AM' && hour == 12) hour = 0;
  } else {
    meridiem = hour < 12 ? 'AM' : 'PM';
  }
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final minuteStr = minute.toString().padLeft(2, '0');
  return '$hour12:$minuteStr $meridiem';
}

final RegExp _clockRe = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?$');

final RegExp _timeRe = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$');

/// Formats a single `"HH:MM AM/PM"` segment (where `HH` may be given in
/// 24-hour notation) into a proper 12-hour `"H:MM AM/PM"` string. Returns
/// null if [segment] doesn't match the expected shape.
String? _formatSingleTime(String segment) {
  final match = _timeRe.firstMatch(segment);
  if (match == null) return null;

  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;
  if (minute < 0 || minute > 59) return null;

  final meridiem = match.group(3)!.toUpperCase();
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final minuteStr = minute.toString().padLeft(2, '0');
  return '$hour12:$minuteStr $meridiem';
}
