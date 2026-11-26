import 'dart:convert';

import 'api_client.dart';

/// A single enrolled course, shown in the Student portal's My Courses grid.
class StuCourse {
  final String subId;
  final String name;
  final String codeId;
  final String className;
  final String creditHours;
  final String teacherName;
  const StuCourse({
    required this.subId,
    required this.name,
    required this.codeId,
    required this.className,
    required this.creditHours,
    required this.teacherName,
  });
}

/// Fetches the Student portal's enrolled courses from the AIT
/// SmartCampuses API.
class StuCoursesApi {
  StuCoursesApi._();

  /// Returns null on a request/parse failure (including the backend's
  /// known session-gated error path, no local session, or a confirmed
  /// session expiration — [ApiClient] already redirected to login in
  /// that last case, so this just needs to stop rendering course data).
  static Future<List<StuCourse>?> fetchCourses() async {
    try {
      final response = await ApiClient.instance.get(Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/mycourses'));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['course'] is! List) return null;

      return (decoded['course'] as List).whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return StuCourse(
          subId: m['sub_id']?.toString() ?? '',
          name: (m['course_name']?.toString() ?? '').trim(),
          codeId: (m['code_id']?.toString() ?? '').trim(),
          className: m['class_name']?.toString() ?? '',
          creditHours: m['credit_hour']?.toString() ?? '',
          teacherName: '${m['fname'] ?? ''} ${m['lname'] ?? ''}'.trim(),
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }
}
