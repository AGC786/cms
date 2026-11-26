import 'dart:convert';

import 'api_client.dart';
import 'stu_courses_api.dart';

/// A single day's attendance mark ('P'/'A'/'L').
class StuAttendanceMark {
  final int day;
  final String status;
  const StuAttendanceMark({required this.day, required this.status});
}

/// Fetches the Student portal's own courses and attendance from the
/// AIT SmartCampuses API.
class StuAttendanceApi {
  StuAttendanceApi._();

  /// Returns null on a request/parse failure (including the backend's
  /// known session-gated error path).
  static Future<List<StuCourse>?> fetchCourses() => StuCoursesApi.fetchCourses();

  /// Returns null on a request/parse/session failure.
  ///
  /// Confirmed live against the backend (`Studentportal/attendance_data`):
  /// - It's session-gated — without the `ci_session` cookie the SQL comes
  ///   back with a blank `student_id=` clause (HTTP 500), so this must go
  ///   through [ApiClient].
  /// - `from`/`to` are full `YYYY-MM-DD` date strings, not a bare month
  ///   number — passing just the month silently matched the backend's
  ///   `1970-01-01` fallback and always returned nothing.
  static Future<List<StuAttendanceMark>?> fetchAttendance({
    required String subId,
    required int month,
    required int year,
  }) async {
    try {
      final from = _isoDate(DateTime(year, month, 1));
      final to = _isoDate(DateTime(year, month + 1, 0));
      final response = await ApiClient.instance.postForm(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/attendance_data'),
        fields: {'course': subId, 'from': from, 'to': to},
      );
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! List) return null;

      return (decoded['data'] as List)
          .whereType<Map>()
          .map((raw) {
            final m = raw.map((k, v) => MapEntry(k.toString(), v));
            final dateStr = m['date']?.toString();
            final status = m['status']?.toString();
            if (dateStr == null || status == null) return null;
            final day = int.tryParse(RegExp(r'^(\d{1,2})').firstMatch(dateStr)?.group(1) ?? '') ??
                DateTime.tryParse(dateStr)?.day;
            if (day == null) return null;
            return StuAttendanceMark(day: day, status: status);
          })
          .whereType<StuAttendanceMark>()
          .toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
