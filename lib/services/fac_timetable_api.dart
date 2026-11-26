import 'dart:convert';

import 'api_client.dart';

/// A single period in the Faculty portal's weekly time table.
class FacPeriod {
  final String course;
  final String courseCode;
  final String batch;
  final String room;
  final String time;
  final String semester;
  final String type;
  const FacPeriod({
    required this.course,
    required this.courseCode,
    required this.batch,
    required this.room,
    required this.time,
    required this.semester,
    required this.type,
  });
}

/// Fetches the Faculty portal's weekly time table (by weekday) from the
/// AIT SmartCampuses API.
///
/// Like the other `Teacherportal/*` reads, this is gated by a real,
/// server-side login session (`ci_session` cookie, obtained via
/// `FacAuthApi.login`) — confirmed by probing it directly (even with an
/// explicit `teacher_id` request parameter, which the backend ignores),
/// which returns a SQL error with a blank `teacher_id =` clause.
class FacTimetableApi {
  FacTimetableApi._();

  /// Returns null when there's no session / the request fails / the
  /// server returned no usable data.
  static Future<List<FacPeriod>?> fetchTimetable(String day) async {
    try {
      final response = await ApiClient.instance.postForm(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacherportal/load_timetables'),
        fields: {'days': day},
      );
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;

      return decoded.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacPeriod(
          course: m['course']?.toString() ?? '',
          courseCode: (m['code_id'] ?? m['course_code'] ?? m['subject_code'] ?? m['code'])?.toString() ?? '',
          batch: m['batch']?.toString() ?? '',
          room: m['floor_number']?.toString() ?? '',
          time: m['time']?.toString() ?? '',
          semester: m['semester']?.toString() ?? '',
          type: m['type']?.toString() ?? '',
        );
      }).toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
