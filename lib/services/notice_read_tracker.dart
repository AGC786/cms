import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which notices a portal's user has already seen, so the
/// Notice Board icon can show a red "unread" dot only for notices
/// posted since the user last opened the board — and, once they've
/// seen everything, stays clear on every subsequent login until a
/// genuinely new notice is added (rather than re-alerting on the same
/// old notices every time, or never clearing at all).
///
/// The backend notice APIs don't hand back a stable numeric id, so each
/// notice is identified by `date|title` (see [_keyOf]) — stable enough
/// in practice since a board doesn't repost the same title on the same
/// date.
class NoticeReadTracker {
  NoticeReadTracker._();

  static String _prefsKey(String portal) => 'seen_notices_$portal';

  static String _keyOf(Map<String, String> notice) =>
      '${notice['date'] ?? ''}|${notice['title'] ?? ''}|${notice['body'] ?? ''}';

  /// True if any notice in [notices] hasn't been marked seen yet for
  /// [portal] — drives the red dot on that portal's Notice Board icon.
  static Future<bool> hasUnread(String portal, List<Map<String, String>> notices) async {
    if (notices.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_prefsKey(portal)) ?? const []).toSet();
    return notices.any((n) => !seen.contains(_keyOf(n)));
  }

  /// Call once the user has opened/viewed the Notice Board — clears the
  /// red dot for every notice currently on the board. Any notice posted
  /// afterwards will show as unread again on its own.
  static Future<void> markAllRead(String portal, List<Map<String, String>> notices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey(portal), notices.map(_keyOf).toList());
  }
}
