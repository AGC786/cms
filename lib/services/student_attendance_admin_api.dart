import 'dart:convert';

import 'api_client.dart';

/// Attendance totals returned by
/// [StudentAttendanceAdminApi.fetchAttendance].
class StudentAttendanceResult {
  final int totalDays;
  final int present;
  final int absent;
  final int leave;
  const StudentAttendanceResult({required this.totalDays, required this.present, required this.absent, required this.leave});
}

/// One course's P/A/L breakdown within a
/// [StudentAttendanceSummary.perCourse] list.
class CourseAttendanceBreakdown {
  final String courseId;
  final String courseName;
  final int present;
  final int absent;
  final int leave;
  const CourseAttendanceBreakdown({
    required this.courseId,
    required this.courseName,
    required this.present,
    required this.absent,
    required this.leave,
  });
}

/// Server-aggregated attendance summary returned by
/// [StudentAttendanceAdminApi.fetchSummary] — overall totals plus a
/// per-course breakdown, computed backend-side rather than by summing
/// [StudentAttendanceAdminApi.fetchAttendance]'s raw per-day rows
/// client-side.
class StudentAttendanceSummary {
  final int totalDays;
  final int present;
  final int absent;
  final int leave;
  final List<CourseAttendanceBreakdown> perCourse;
  const StudentAttendanceSummary({
    required this.totalDays,
    required this.present,
    required this.absent,
    required this.leave,
    required this.perCourse,
  });
}

/// Fetches per-student attendance totals from the AIT SmartCampuses API.
class StudentAttendanceAdminApi {
  StudentAttendanceAdminApi._();

  /// Confirmed live against the real backend controller
  /// (`summary_student_attendance()`, same `student_id`/`from_date`/
  /// `to_date`/optional `course_id` params as [fetchAttendance]):
  /// returns `{"success": true, "message": "...", "data": {"overall":
  /// {"P": n, "A": n, "L": n, "total": n}, "per_course": [{"course_id",
  /// "course_name", "P", "A", "L"}, ...]}}` — the totals are already
  /// aggregated server-side, so unlike [fetchAttendance] this doesn't
  /// need to sum anything itself. Returns null when `overall.total` is
  /// `0` (nothing to report for this range) rather than a zeroed result.
  static Future<StudentAttendanceSummary?> fetchSummary({
    required String studentId,
    required DateTime from,
    required DateTime to,
    String? courseId,
  }) async {
    try {
      final url = Uri.parse(
        'https://campus.smartcampuses.com/demo_institute/mobile_app/summary_student_attendance'
        '?student_id=$studentId&from_date=${_isoDate(from)}&to_date=${_isoDate(to)}'
        '${courseId != null && courseId.isNotEmpty ? '&course_id=$courseId' : ''}',
      );
      final response = await ApiClient.instance.get(url, requireSession: false, treatForbiddenAsExpired: false);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      final overall = data is Map ? data['overall'] : null;
      if (overall is! Map) return null;

      final present = int.tryParse(overall['P']?.toString() ?? '') ?? 0;
      final absent = int.tryParse(overall['A']?.toString() ?? '') ?? 0;
      final leave = int.tryParse(overall['L']?.toString() ?? '') ?? 0;
      final total = int.tryParse(overall['total']?.toString() ?? '') ?? (present + absent + leave);
      if (total == 0) return null;

      final perCourseRaw = data is Map ? data['per_course'] : null;
      final perCourse = perCourseRaw is List
          ? perCourseRaw.whereType<Map>().map((raw) {
              final m = raw.map((k, v) => MapEntry(k.toString(), v));
              return CourseAttendanceBreakdown(
                courseId: m['course_id']?.toString() ?? '',
                courseName: (m['course_name']?.toString() ?? '').trim(),
                present: int.tryParse(m['P']?.toString() ?? '') ?? 0,
                absent: int.tryParse(m['A']?.toString() ?? '') ?? 0,
                leave: int.tryParse(m['L']?.toString() ?? '') ?? 0,
              );
            }).toList()
          : <CourseAttendanceBreakdown>[];

      return StudentAttendanceSummary(totalDays: total, present: present, absent: absent, leave: leave, perCourse: perCourse);
    } catch (_) {
      return null;
    }
  }

  /// Confirmed live against the real backend controller
  /// (`detailed_student_attendance()`, params `student_id`/`from_date`/
  /// `to_date`/optional `course_id`): returns
  /// `{"success": true, "message": "...", "data": [{"status": "P"|"A",
  /// "date": "yyyy-MM-dd", "course_name": "...", "course_id": "..."},
  /// ...]}` — one row per course per day, not pre-aggregated totals, so
  /// the P/A/L counts here are computed from `data` rather than read
  /// off nonexistent `total_present`/`total_absent`/`total_leaves`
  /// fields. Returns null when `data` is empty (nothing to report for
  /// this range) rather than a zeroed result.
  ///
  /// [courseId] narrows the range to a single course when given
  /// (confirmed live) — omit it to get every course the student had
  /// attendance recorded for in the range.
  static Future<StudentAttendanceResult?> fetchAttendance({
    required String studentId,
    required DateTime from,
    required DateTime to,
    String? courseId,
  }) async {
    try {
      final url = Uri.parse(
        'https://campus.smartcampuses.com/demo_institute/mobile_app/detailed_student_attendance'
        '?student_id=$studentId&from_date=${_isoDate(from)}&to_date=${_isoDate(to)}'
        '${courseId != null && courseId.isNotEmpty ? '&course_id=$courseId' : ''}',
      );
      final response = await ApiClient.instance.get(url, requireSession: false, treatForbiddenAsExpired: false);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! List) return null;

      final rows = (decoded['data'] as List).whereType<Map>();
      if (rows.isEmpty) return null;

      var present = 0, absent = 0, leave = 0;
      for (final raw in rows) {
        switch (raw['status']?.toString()) {
          case 'P':
            present++;
            break;
          case 'A':
            absent++;
            break;
          case 'L':
            leave++;
            break;
        }
      }

      return StudentAttendanceResult(totalDays: present + absent + leave, present: present, absent: absent, leave: leave);
    } catch (_) {
      return null;
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
