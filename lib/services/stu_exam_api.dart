import 'dart:convert';

import 'api_client.dart';
import '../utils/time_format.dart';

/// A single exam schedule breakdown (term/session) option.
class ExamBreakdown {
  final String id;
  final String title;
  const ExamBreakdown(this.id, this.title);
}

/// A single row of an exam timetable.
class ExamScheduleRow {
  final String courseName;
  final String date;
  final String time;
  const ExamScheduleRow({required this.courseName, required this.date, required this.time});
}

/// Fetches the Student portal's Exam Schedule breakdown list and
/// timetable from the AIT SmartCampuses API.
///
/// Both confirmed live against a real login:
/// - The breakdown list has no JSON API of its own — the web portal
///   renders `<option value='<id>'>TITLE</option>` pairs directly into
///   the HTML of `Student/Exam-Schedule` (a normal session-gated portal
///   page, not a REST endpoint), so [fetchBreakdowns] fetches that page
///   and regex-extracts them. (`Studentportal/app_exam_schedule`, used
///   here previously, is a different, unrelated endpoint that returns
///   only the single most current exam timetable with no breakdown
///   selection — it was a mistaken stand-in for this.)
/// - `Studentportal/load_examschedule` (POST, `breakdown=<id>`) returns
///   a bare JSON list of `{course_name, date, timestart, timeend, ...}`
///   rows for that breakdown — confirmed with a real `breakdown_id`
///   (id from `fetchBreakdowns`, not a small guessed integer, which
///   always came back as bare `0`/invalid).
class StuExamApi {
  StuExamApi._();

  static final Uri _breakdownsPageUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Student/Exam-Schedule');
  static final Uri _scheduleUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/load_examschedule');

  static final RegExp _optionPattern = RegExp(r"<option value='(\d+)'>\s*([^<]+?)\s*</option>", dotAll: true);

  /// Returns an empty list on any request/parse/session failure, or
  /// when the student genuinely has no exam breakdowns published yet.
  static Future<List<ExamBreakdown>> fetchBreakdowns() async {
    try {
      final response = await ApiClient.instance.get(_breakdownsPageUrl, treatHtmlBodyAsExpired: false);
      if (response.statusCode != 200) return [];

      return _optionPattern.allMatches(response.body).map((m) {
        return ExamBreakdown(m.group(1)!, m.group(2)!.trim());
      }).toList();
    } on ApiSessionExpiredException {
      return [];
    } catch (_) {
      return [];
    }
  }

  static String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (_) {
      return raw;
    }
  }

  /// The backend's own `DATE_FORMAT(..., '%h:%i:%s')` already reduces
  /// these to a 12-hour clock with no AM/PM marker (confirmed live:
  /// `15:00:00` in the DB comes back as `"03:00:00"` here) — the web
  /// portal displays them exactly as sent (just trimming seconds), so
  /// this does the same rather than guessing at an AM/PM it can't know.
  static String _formatTime(String? start, String? end) {
    if (start == null || end == null || start.isEmpty || end.isEmpty) return '-';
    return '${_trimSeconds(start)} - ${_trimSeconds(end)}';
  }

  static String _trimSeconds(String hhmmss) {
    final parts = hhmmss.split(':');
    final trimmed = parts.length >= 2 ? '${parts[0]}:${parts[1]}' : hhmmss;
    return formatClockTime(trimmed);
  }

  /// Returns null on a request/parse/session failure, and an empty list
  /// when the server genuinely has no exam schedule for this breakdown.
  static Future<List<ExamScheduleRow>?> fetchExamSchedule(String breakdownId) async {
    try {
      final response = await ApiClient.instance.postForm(_scheduleUrl, fields: {'breakdown': breakdownId});
      if (response.statusCode != 200) return null;

      final body = response.body.trim();
      if (body.isEmpty || body == '0') return [];

      final decoded = jsonDecode(body);
      if (decoded is! List) return [];

      return decoded.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return ExamScheduleRow(
          courseName: m['course_name']?.toString() ?? '*',
          date: m['date'] != null ? _formatDate(m['date'].toString()) : '-',
          time: _formatTime(m['timestart']?.toString(), m['timeend']?.toString()),
        );
      }).toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
