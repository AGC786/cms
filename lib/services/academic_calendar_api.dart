import 'dart:convert';

import 'package:http/http.dart' as http;
import '../data/models.dart' show CalItem;

/// Fetches the Admin portal's Academic Calendar from the AIT
/// SmartCampuses API.
class AcademicCalendarApi {
  AcademicCalendarApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Mobile_app/academic_calendar');

  /// Same endpoint as [fetchEvents], returned as [CalItem]s (date range +
  /// title, newest first) — the shape the shared Events/Holidays/
  /// Academics screen expects — for the Faculty/Employee/Student "Event
  /// & Holiday" screens' Academics section.
  static Future<List<CalItem>> fetchAsCalItems() async {
    try {
      final response = await http.get(_url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      final rows = decoded.whereType<Map>().toList()
        ..sort((a, b) => _parseDdMmYyyy(b['start_date']?.toString() ?? '')
            .compareTo(_parseDdMmYyyy(a['start_date']?.toString() ?? '')));

      return rows.map((e) {
        final start = e['start_date']?.toString() ?? '';
        final end = e['end_date']?.toString() ?? '';
        final title = (e['title']?.toString() ?? '').trim();
        return CalItem(start == end ? start : '$start – $end', title);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns events as `{'calender_id', 'title', 'start_date', 'end_date'}`
  /// maps, sorted by start date **newest first** (2026, 2025, 2024, ...)
  /// — the shape [AcademicCalendarScreen] already expects — or an empty
  /// list on any network/parsing failure.
  static Future<List<Map<String, String>>> fetchEvents() async {
    try {
      final response = await http.get(_url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      final events = decoded.map((raw) {
        final e = raw as Map<String, dynamic>;
        return {
          'calender_id': e['calender_id']?.toString() ?? '',
          'title': (e['title']?.toString() ?? '').trim(),
          'start_date': e['start_date']?.toString() ?? '',
          'end_date': e['end_date']?.toString() ?? '',
        };
      }).toList();

      events.sort((a, b) => _parseDdMmYyyy(b['start_date']!).compareTo(_parseDdMmYyyy(a['start_date']!)));
      return events;
    } catch (_) {
      return [];
    }
  }

  /// API sends dates as `dd-MM-yyyy`; parsed here only for chronological
  /// sorting (the UI displays the raw string as-is).
  static DateTime _parseDdMmYyyy(String raw) {
    final parts = raw.split('-');
    if (parts.length != 3) return DateTime(0);
    final day = int.tryParse(parts[0]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;
    final year = int.tryParse(parts[2]) ?? 0;
    return DateTime(year, month, day);
  }
}
