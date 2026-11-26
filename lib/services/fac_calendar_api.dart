import 'dart:convert';

import 'package:http/http.dart' as http;
import '../data/models.dart' show CalItem;

/// Combined Events/Holidays/Academics payload from
/// `Teacherportal/calenderforTeacher`.
class FacCalendarData {
  final List<CalItem> events;
  final List<CalItem> holidays;
  final List<CalItem> academics;
  const FacCalendarData({required this.events, required this.holidays, required this.academics});

  static const empty = FacCalendarData(events: [], holidays: [], academics: []);
}

/// Fetches the Faculty portal's Event & Holiday calendar from the AIT
/// SmartCampuses API. Public — confirmed by the app's own React Native
/// source (`FacultyCalender.tsx`), which calls this with a plain
/// `fetch()` and no `ci_session` cookie or auth header of any kind.
class FacCalendarApi {
  FacCalendarApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacherportal/calenderforTeacher');

  static Future<FacCalendarData> fetchCalendar() async {
    try {
      final response = await http.get(_url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return FacCalendarData.empty;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return FacCalendarData.empty;

      final events = _parseList(decoded['event'], titleKey: 'event_title');
      final holidays = _parseList(decoded['holiday'], titleKey: 'title');
      final academics = _parseList(decoded['academic'], titleKey: 'title');
      if (events == null || holidays == null || academics == null) return FacCalendarData.empty;

      return FacCalendarData(events: events, holidays: holidays, academics: academics);
    } catch (_) {
      return FacCalendarData.empty;
    }
  }

  /// `event`/`holiday`/`academic` share this shape: a list of
  /// `{<titleKey>, start_date, end_date}` rows, sorted newest-first by
  /// `end_date` — matching the RN screen's `sortByDateDesc`.
  static List<CalItem>? _parseList(dynamic raw, {required String titleKey}) {
    if (raw is! List) return null;

    final entries = raw.whereType<Map>().map((item) {
      final m = item.map((k, v) => MapEntry(k.toString(), v));
      final start = m['start_date']?.toString() ?? '';
      final end = m['end_date']?.toString() ?? '';
      final title = (m[titleKey]?.toString() ?? '').trim();
      final sortKey = _parseDate(end) ?? DateTime(0);
      return (sortKey, CalItem(start == end ? _formatDate(start) : '${_formatDate(start)} – ${_formatDate(end)}', title));
    }).toList();

    entries.sort((a, b) => b.$1.compareTo(a.$1));
    return entries.map((e) => e.$2).toList();
  }

  /// The backend sends ISO dates (`yyyy-MM-dd`); displayed here as
  /// `dd-MM-yyyy`, matching the RN screen's `formatDate`.
  static String _formatDate(String raw) {
    final date = _parseDate(raw);
    if (date == null) return raw;
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  static DateTime? _parseDate(String raw) => DateTime.tryParse(raw);
}
