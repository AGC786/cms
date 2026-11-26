import 'dart:convert';

import 'package:http/http.dart' as http;

/// A simple id/name pair used for Campus, Program, and Shift dropdowns.
class IdName {
  final String id;
  final String name;
  const IdName(this.id, this.name);
}

/// A Year/Section option — [classId] and [sectionId] are both required by
/// downstream endpoints (courses, attendance).
class YearOption {
  final String classId;
  final String sectionId;
  final String name;
  const YearOption(this.classId, this.sectionId, this.name);
}

/// A course option — [subId] is the id the attendance endpoint expects as
/// `course_id`.
class CourseOption {
  final String subId;
  final String name;
  const CourseOption(this.subId, this.name);
}

/// Single-day attendance counts for one course/class/section.
class CourseAttendanceResult {
  final int totalStudents;
  final int present;
  final int absent;
  final int leave;
  const CourseAttendanceResult({required this.totalStudents, required this.present, required this.absent, required this.leave});
}

/// Fetches the Admin portal's Course Attendance cascading filters
/// (Campus → Program → Shift → Year → Course) and the day's attendance
/// counts from the AIT SmartCampuses API.
class CourseAttendanceAdminApi {
  CourseAttendanceAdminApi._();

  static const _base = 'https://campus.smartcampuses.com/demo_institute';

  static Future<List<dynamic>?> _getList(Uri url) async {
    try {
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = response.body.trim();
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<IdName>> fetchCampuses() async {
    final list = await _getList(Uri.parse('$_base/mobile_app/load_campus'));
    if (list == null) return [];
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return IdName(m['branch_id'].toString(), (m['name']?.toString() ?? '').trim());
    }).toList();
  }

  static Future<List<IdName>> fetchPrograms(String branchId) async {
    final list = await _getList(Uri.parse('$_base/mobile_app/system_type?branch_id=$branchId'));
    if (list == null) return [];
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return IdName(m['session_id'].toString(), (m['s_name']?.toString() ?? '').trim());
    }).toList();
  }

  static Future<List<IdName>> fetchShifts(String programId) async {
    final list = await _getList(Uri.parse('$_base/mobile_app/load_session?system_type_id=$programId'));
    if (list == null) return [];
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return IdName(m['batch_id'].toString(), (m['batch_title']?.toString() ?? '').trim());
    }).toList();
  }

  static Future<List<YearOption>> fetchYears(String branchId, String shiftId) async {
    final list = await _getList(Uri.parse('$_base/mobile_app/get_class?branch_id=$branchId&system_type_id=$shiftId'));
    if (list == null) return [];
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return YearOption(m['class_id'].toString(), m['class_section_id'].toString(), (m['cs_name']?.toString() ?? '').trim());
    }).toList();
  }

  static Future<List<CourseOption>> fetchCourses(String programId, String classId) async {
    final list = await _getList(Uri.parse('$_base/mobile_app/load_courses?session_id=$programId&class_id=$classId'));
    if (list == null) return [];
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return CourseOption(m['sub_id'].toString(), (m['course_name']?.toString() ?? '').trim());
    }).toList();
  }

  /// Always returns a result (zeroed when the server has no data for this
  /// combination) — matching the RN screen's behavior of always showing
  /// the stat boxes rather than hiding them.
  static Future<CourseAttendanceResult> fetchAttendance({
    required String branchId,
    required String programId,
    required String batchId,
    required String classId,
    required String sectionId,
    required String courseId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final list = await _getList(Uri.parse(
      '$_base/mobile_app/student_attendance'
      '?branch_id=$branchId&program_id=$programId&batch_id=$batchId&class_id=$classId'
      '&class_section_id=$sectionId&course_id=$courseId&date=$dateStr',
    ));

    if (list == null || list.isEmpty) {
      return const CourseAttendanceResult(totalStudents: 0, present: 0, absent: 0, leave: 0);
    }
    final row = list.first as Map<String, dynamic>;
    return CourseAttendanceResult(
      totalStudents: int.tryParse(row['total_students']?.toString() ?? '') ?? 0,
      present: int.tryParse(row['P']?.toString() ?? '') ?? 0,
      absent: int.tryParse(row['A']?.toString() ?? '') ?? 0,
      leave: int.tryParse(row['L']?.toString() ?? '') ?? 0,
    );
  }
}
