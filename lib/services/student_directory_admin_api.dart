import 'dart:convert';

import 'api_client.dart';

/// A single student record returned by
/// [StudentDirectoryAdminApi.fetchStudents].
class StudentRecord {
  final String studentId;
  final String name;
  final String grNo;
  final String program;
  final String batch;
  final String email;
  final String mobile;
  final String cnic;
  final String admissionDate;
  const StudentRecord({
    required this.studentId,
    required this.name,
    required this.grNo,
    required this.program,
    required this.batch,
    required this.email,
    required this.mobile,
    required this.cnic,
    required this.admissionDate,
  });

  /// True if [query] (already lowercased) matches any searchable field —
  /// mirrors the RN screen's multi-field filter.
  bool matches(String query) =>
      name.toLowerCase().contains(query) ||
      studentId.toLowerCase().contains(query) ||
      grNo.toLowerCase().contains(query);
}

/// Fetches the Admin portal's full student directory from the AIT
/// SmartCampuses API.
class StudentDirectoryAdminApi {
  StudentDirectoryAdminApi._();

  /// This endpoint is public (no `ci_session` required, unlike the
  /// portal-specific reads) — `requireSession: false` lets it go through
  /// the same [ApiClient] as every authenticated call anyway, so a 403
  /// here (a genuine "not allowed" rather than a session issue) doesn't
  /// get misread as an expired Admin session.
  static Future<List<StudentRecord>> fetchStudents() async {
    try {
      final response = await ApiClient.instance.get(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Mobile_app/get_student'),
        requireSession: false,
        treatForbiddenAsExpired: false,
      );
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.whereType<Map>().map((raw) {
        final s = raw.map((k, v) => MapEntry(k.toString(), v));
        return StudentRecord(
          studentId: s['student_id']?.toString() ?? '',
          name: _pick(s, ['student_name', 'Student_name', 'fname', 'name', 'Employee_name'], fallback: ''),
          grNo: s['parmanent_id']?.toString() ?? '',
          program: _pick(s, ['s_name', 'program', 'program_name']),
          batch: _pick(s, ['batch_title', 'class_name', 'batch', 'batch_name']),
          email: _pick(s, ['student_email', 'email', 'email_address']),
          mobile: _pick(s, ['mobile_number', 'mobile_no', 'phone']),
          cnic: _pick(s, ['cnic', 'student_cnic']),
          admissionDate: _pick(s, ['admission_date', 'date_of_admission']),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static String _pick(Map<String, dynamic> data, List<String> keys, {String fallback = '-'}) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return fallback;
  }
}
