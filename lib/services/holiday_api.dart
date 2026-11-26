import 'dart:convert';

import 'package:http/http.dart' as http;
import '../data/models.dart' show CalItem;

/// Fetches the Admin portal's Holiday list from the AIT SmartCampuses API.
class HolidayApi {
  HolidayApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Mobile_app/holiday');

  /// Returns holidays as [CalItem]s (dates range + title), newest first —
  /// the shape the shared Events/Holidays/Academics screen already
  /// expects — or an empty list on any network/parsing failure.
  static Future<List<CalItem>> fetchHolidays() async {
    try {
      final response = await http.get(_url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.map((raw) {
        final h = raw as Map<String, dynamic>;
        final start = h['start_date']?.toString() ?? '';
        final end = h['end_date']?.toString() ?? '';
        final title = (h['title']?.toString() ?? '').trim();
        return CalItem(start == end ? start : '$start – $end', title);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Holiday date **ranges** (inclusive), for cross-referencing against
  /// the attendance feed — which only tags the first day of a multi-day
  /// holiday as "Holiday" and leaves the rest as "Absent". Returns an
  /// empty list on any failure (caller then just skips the correction).
  static Future<List<({DateTime from, DateTime to})>> fetchHolidayRanges() async {
    try {
      final response = await http.get(_url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      final out = <({DateTime from, DateTime to})>[];
      for (final raw in decoded.whereType<Map>()) {
        final f = _parseDate(raw['start_date']?.toString());
        if (f == null) continue;
        out.add((from: f, to: _parseDate(raw['end_date']?.toString()) ?? f));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Parses `dd-MM-yyyy` (the holiday feed's format) or `yyyy-MM-dd`.
  static DateTime? _parseDate(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final p = s.split(RegExp(r'[-/]'));
    if (p.length != 3) return null;
    final a = int.tryParse(p[0]), b = int.tryParse(p[1]), c = int.tryParse(p[2]);
    if (a == null || b == null || c == null) return null;
    if (c > 31) return DateTime(c, b, a); // dd-MM-yyyy
    if (a > 31) return DateTime(a, b, c); // yyyy-MM-dd
    return null;
  }
}
