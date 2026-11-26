import 'dart:convert';

import 'api_client.dart';

/// A single row from `Studentportal/get_notifications`. Field names
/// (`alert_id`, `title`, `seen`, `link`) are confirmed against the
/// portal's own JS (`loadNotifications()`/`markSeen()`); `message`/`date`
/// aren't rendered there so they're still picked from plausible aliases.
class StuNotification {
  final String id;
  final String title;
  final String message;
  final String date;
  final String link;
  final bool seen;

  const StuNotification({required this.id, required this.title, required this.message, required this.date, required this.link, required this.seen});
}

/// Student portal notifications, backed by the real session-gated
/// endpoints (`$_SESSION['std_Id']` etc. are populated server-side by the
/// PHP session the login cookie already carries — no extra params
/// needed on our end beyond the `ci_session` cookie [ApiClient] attaches
/// automatically).
class StuNotificationApi {
  StuNotificationApi._();

  static final Uri _listUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/get_notifications');
  static final Uri _markSeenUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/mark_seen');

  /// Fetches the student's notification list, newest first. Returns an
  /// empty list on any failure (no session, network error, unexpected
  /// shape, or `status != 'success'`) so callers can render an empty
  /// state rather than crash.
  static Future<List<StuNotification>> fetchNotifications() async {
    final decoded = await _fetchDecoded();
    if (decoded == null) return [];
    return _parseList(decoded);
  }

  /// Fetches just the unread count for the bell badge — reads the
  /// server's own `unseen_count` (confirmed by the portal JS setting
  /// `#bell_badge` from it directly) instead of recomputing it from the
  /// list, so it stays correct even if the list response is paginated.
  static Future<int> fetchUnseenCount() async {
    final decoded = await _fetchDecoded();
    if (decoded == null) return 0;
    if (decoded is Map && decoded['unseen_count'] != null) {
      return int.tryParse(decoded['unseen_count'].toString()) ?? _parseList(decoded).where((n) => !n.seen).length;
    }
    return _parseList(decoded).where((n) => !n.seen).length;
  }

  static Future<dynamic> _fetchDecoded() async {
    try {
      final response = await ApiClient.instance.get(_listUrl);
      if (response.statusCode != 200) return null;

      final body = response.body;
      final jsonStart = body.indexOf(RegExp(r'[\[{]'));
      if (jsonStart == -1) return null;
      final decoded = jsonDecode(body.substring(jsonStart));

      if (decoded is Map && decoded['status'] != null && decoded['status'] != 'success') return null;
      return decoded;
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static List<StuNotification> _parseList(dynamic decoded) {
    final list = decoded is List
        ? decoded
        : decoded is Map
            ? (decoded['data'] ?? decoded['notifications'] ?? decoded['fetch_data'] ?? decoded['list'])
            : null;
    if (list is! List) return [];

    return list.whereType<Map>().map((raw) {
      final m = raw.map((k, v) => MapEntry(k.toString(), v));
      final seenRaw = _pick(m, ['seen', 'is_seen', 'read']).toLowerCase();
      return StuNotification(
        id: _pick(m, ['alert_id', 'id', 'notification_id']),
        title: _pick(m, ['title', 'notification_title', 'subject', 'heading'], fallback: 'Notification'),
        message: _pick(m, ['message', 'description', 'notification_message', 'body', 'details']),
        date: _formatDate(_pick(m, [
          'created_at', 'date', 'created_date', 'notification_date', 'created_on',
          'added_on', 'alert_date', 'datetime', 'date_time', 'dated', 'insert_date',
          'create_date', 'notification_added', 'time',
        ])),
        link: _pick(m, ['link', 'url']),
        seen: seenRaw == '1' || seenRaw == 'true' || seenRaw == 'seen' || seenRaw == 'yes',
      );
    }).toList();
  }

  /// Marks a single alert as seen (appends this student to
  /// `notification_alert.std_ids` server-side). Fire-and-forget from the
  /// UI's perspective — failure just means it'll show as unseen again
  /// next refresh, which is harmless.
  static Future<void> markSeen(String alertId) async {
    if (alertId.isEmpty) return;
    try {
      await ApiClient.instance.postForm(_markSeenUrl, fields: {'alert_id': alertId});
    } catch (_) {
      // best-effort
    }
  }

  /// Normalises the raw date field to `dd-MM-yyyy`.
  ///
  /// The backend has been seen to hand back `0000-00-00`, an empty
  /// value, or a `0`/tiny Unix timestamp for notifications whose
  /// `created_at` column was never populated — all of which rendered as
  /// "1970". Those are dropped (empty string → the tile hides the date
  /// line) rather than shown as a bogus year. A real `yyyy-MM-dd ...`
  /// string or a seconds/millis timestamp is formatted; anything else
  /// unrecognised is passed through untouched.
  static String _formatDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s.startsWith('0000')) return '';

    final ts = int.tryParse(s);
    if (ts != null) {
      if (ts <= 0) return '';
      final ms = s.length >= 12 ? ts : ts * 1000; // secs vs millis
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return d.year < 2000 ? '' : _ddMmYyyy(d);
    }

    final d = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    if (d == null) return s;
    return d.year < 2000 ? '' : _ddMmYyyy(d);
  }

  static String _ddMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  static String _pick(Map<String, dynamic> data, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return fallback;
  }
}
