import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches the Admin portal's Alerts (student/staff application
/// requests) from the AIT SmartCampuses API.
class AlertApi {
  AlertApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Mobile_app/alerts');

  /// Whether the user has tapped "mark all as read" in the Alerts screen
  /// during this app session. This endpoint has no per-alert id and no
  /// mark-read write endpoint (see `AdminAlertScreen`), so there's
  /// nothing to persist server-side — this flag is the only "read"
  /// state that exists, and is what [fetchUnreadCount] reports against
  /// so the dashboard's bell badge agrees with the Alerts screen instead
  /// of re-showing a stale server count right after it was cleared.
  static bool _markedAllReadThisSession = false;

  /// This endpoint has no per-alert id and no server-side mark-read
  /// write, so "read" state is tracked locally: each alert is keyed by
  /// `date|subject|content` (stable enough — the same subject isn't
  /// reposted on the same date) and the seen keys are persisted in
  /// shared_preferences so a blue dot stays cleared across app restarts.
  static const _readPrefsKey = 'read_alerts_admin';

  static String _keyOf(Map<String, String> a) =>
      '${a['date'] ?? ''}|${a['subject'] ?? ''}|${a['content'] ?? ''}';

  /// Marks one alert read locally (called when the user opens it).
  static Future<void> markReadLocally(Map<String, String> alert) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_readPrefsKey) ?? const <String>[]).toSet()..add(_keyOf(alert));
    await prefs.setStringList(_readPrefsKey, set.toList());
  }

  /// Marks every alert currently on screen read — both the session flag
  /// [fetchUnreadCount] reads and the persisted per-alert set, so the
  /// dots don't come back on the next launch.
  static Future<void> markAllReadLocally([List<Map<String, String>> alerts = const []]) async {
    _markedAllReadThisSession = true;
    if (alerts.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_readPrefsKey) ?? const <String>[]).toSet()
      ..addAll(alerts.map(_keyOf));
    await prefs.setStringList(_readPrefsKey, set.toList());
  }

  /// Returns alerts as `{'date', 'subject', 'parmanent_id', 'content',
  /// 'status'}` maps, newest first, or an empty list on any network/
  /// parsing failure.
  static Future<List<Map<String, String>>> fetchAlerts() async {
    try {
      final response = await http.get(_url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      final alerts = decoded.whereType<Map>().map((raw) {
        final a = raw;
        return {
          'date': a['date']?.toString() ?? '',
          'subject': (a['subject']?.toString() ?? '').trim(),
          'parmanent_id': a['parmanent_id']?.toString() ?? '',
          'content': (a['content']?.toString() ?? '').trim(),
          'status': a['status']?.toString() ?? '',
        };
      }).toList();

      alerts.sort((a, b) => b['date']!.compareTo(a['date']!));

      // Fold in the locally-tracked read state so an alert the user has
      // already opened comes back without its blue dot.
      final prefs = await SharedPreferences.getInstance();
      final readSet = (prefs.getStringList(_readPrefsKey) ?? const <String>[]).toSet();
      for (final a in alerts) {
        if (readSet.contains(_keyOf(a))) a['status'] = 'Read';
      }
      return alerts;
    } catch (_) {
      return [];
    }
  }

  /// Unread-alert count for the dashboard bell badge — `0` once
  /// [markAllReadLocally] has been called this session, otherwise the
  /// real count of `status == 'Unread'` rows from [fetchAlerts].
  static Future<int> fetchUnreadCount() async {
    if (_markedAllReadThisSession) return 0;
    final alerts = await fetchAlerts();
    return alerts.where((a) => a['status'] == 'Unread').length;
  }
}
