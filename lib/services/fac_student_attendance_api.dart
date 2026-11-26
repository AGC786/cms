import 'dart:convert';

import 'api_client.dart';

class FacProgramOption {
  final String id; // session_id
  final String name;
  const FacProgramOption(this.id, this.name);
}

class FacShiftOption {
  final String id; // batch_id
  final String title;
  const FacShiftOption(this.id, this.title);
}

class FacYearOption {
  final String classId;
  final String sectionId;
  final String name;
  const FacYearOption({required this.classId, required this.sectionId, required this.name});
}

class FacCourseOption {
  final String id; // sub_id
  final String name;
  const FacCourseOption(this.id, this.name);
}

class FacCourseTypeOption {
  final String id;
  final String name;
  const FacCourseTypeOption(this.id, this.name);
}

class FacStudentRow {
  final String studentId;
  final String name;
  final String rollNo;
  const FacStudentRow(this.studentId, this.name, [this.rollNo = '']);
}

/// Fetches the Faculty portal's Student Attendance cascade (Program →
/// Shift → Year → Course/Course Type → student list) and submits marked
/// attendance, all against the AIT SmartCampuses API.
///
/// Every step here is gated by a real, server-side login session
/// (`ci_session` cookie, obtained via `FacAuthApi.login`) — confirmed by
/// probing the first endpoint directly (even with an explicit `t_id`
/// request parameter, which the backend ignores), which returns a SQL
/// error with a blank `teacher_id =` clause.
class FacStudentAttendanceApi {
  FacStudentAttendanceApi._();

  static Future<List<FacProgramOption>?> fetchPrograms() async {
    try {
      final response = await ApiClient.instance.get(Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacher/Session-Api-Mobile'));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      final list = decoded is Map ? decoded['session'] : null;
      if (list is! List) return null;
      return list.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacProgramOption(m['session_id']?.toString() ?? '', m['s_name']?.toString() ?? '');
      }).toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<FacShiftOption>?> fetchShifts(String sessionId) async {
    try {
      final response = await ApiClient.instance.postForm(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacher/Load-Batch-Api-Mobile'),
        fields: {'s_id': sessionId},
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      final list = decoded is Map ? decoded['batch'] : null;
      if (list is! List) return null;
      return list.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacShiftOption(m['batch_id']?.toString() ?? '', (m['batch']?.toString() ?? '').trim());
      }).toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<FacYearOption>?> fetchYears(String batchId) async {
    try {
      final response = await ApiClient.instance.postForm(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacher/Load-Classes-Api-Mobile'),
        fields: {'id': batchId},
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;
      return decoded.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacYearOption(
          classId: m['class_id']?.toString() ?? '',
          sectionId: m['class_section_id']?.toString() ?? '',
          name: m['class_name']?.toString() ?? '',
        );
      }).toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<(List<FacCourseOption>, List<FacCourseTypeOption>)?> fetchCourses({
    required String sessionId,
    required String className,
  }) async {
    try {
      final response = await ApiClient.instance.postForm(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacher/Load-Courrse-Api-Mobile'),
        fields: {'p_id': sessionId, 'id': className},
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final coursesRaw = decoded['courses'];
      final typesRaw = decoded['course_type'];
      if (coursesRaw is! List || typesRaw is! List) return null;

      final courses = coursesRaw.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacCourseOption(m['sub_id']?.toString() ?? '', m['course_name']?.toString() ?? '');
      }).toList();
      final types = typesRaw.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacCourseTypeOption(m['course_type_id']?.toString() ?? '', m['course_type_title']?.toString() ?? '');
      }).toList();

      return (courses, types);
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<FacStudentRow>?> fetchStudents({
    required String date1,
    required String courseTypeId,
    required String courseId,
    required String batchId,
    required String classId,
    required String sectionId,
  }) async {
    try {
      final response = await ApiClient.instance.postForm(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacher/Load-Student-Attendance-Api-Mobile'),
        fields: {
          'date1': date1,
          'course_type_id': courseTypeId,
          'course': courseId,
          'batch_id': batchId,
          'id': classId,
          'sid': sectionId,
          'section_id': sectionId,
          'br': '1',
        },
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      final list = decoded is Map ? decoded['data'] : null;
      if (list is! List) return null;
      return list.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        final roll = m['roll_no'] ?? m['rollno'] ?? m['roll_number'] ?? m['reg_no'] ?? m['registration_no'] ?? m['student_roll_no'];
        return FacStudentRow(m['student_id']?.toString() ?? '', m['fname']?.toString() ?? '', roll?.toString() ?? '');
      }).toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true only on a confirmed server-side success
  /// (`{"status": 1, ...}`).
  static Future<bool> saveAttendance({
    required String date1,
    required String courseTypeId,
    required String courseId,
    required String className,
    required String classId,
    required String sectionId,
    required String username,
    required List<FacStudentRow> students,
    required Map<String, String> statusByStudentId,
  }) async {
    try {
      final body = <String, String>{
        'date1': date1,
        'course_type_id': courseTypeId,
        'course': courseId,
        'classname1': className,
        'class': '$classId,$sectionId',
        'length': '${students.length}',
        'user_name': username,
      };
      for (var i = 0; i < students.length; i++) {
        body['student_id[$i]'] = students[i].studentId;
        body['attendance_status[$i]'] = statusByStudentId[students[i].studentId] ?? 'Present';
      }

      final response = await ApiClient.instance.postForm(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacher/Save-Student-Attendance-Api-Mobile'),
        fields: body,
      );
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['status'] == 1;
    } on ApiSessionExpiredException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
