import 'dart:convert';

import 'api_client.dart';

/// A single employee record returned by
/// [EmployeeDirectoryAdminApi.fetchEmployees].
class EmployeeRecord {
  final String empId;
  final String name;
  final String programType;
  final String scaleType;
  final String deptName;
  final String staffType;
  final String email;
  final String mobile;
  const EmployeeRecord({
    required this.empId,
    required this.name,
    required this.programType,
    required this.scaleType,
    required this.deptName,
    required this.staffType,
    required this.email,
    required this.mobile,
  });

  /// True if [query] (already lowercased) matches any searchable field —
  /// mirrors the RN screen's multi-field filter exactly.
  bool matches(String query) =>
      name.toLowerCase().contains(query) ||
      empId.toLowerCase().contains(query) ||
      programType.toLowerCase().contains(query) ||
      scaleType.toLowerCase().contains(query) ||
      deptName.toLowerCase().contains(query) ||
      staffType.toLowerCase().contains(query) ||
      email.toLowerCase().contains(query) ||
      mobile.toLowerCase().contains(query);
}

/// Fetches the Admin portal's full employee directory from the AIT
/// SmartCampuses API.
class EmployeeDirectoryAdminApi {
  EmployeeDirectoryAdminApi._();

  /// This endpoint is public (no `ci_session` required, unlike the
  /// portal-specific reads) — `requireSession: false` lets it go through
  /// the same [ApiClient] as every authenticated call anyway, so a 403
  /// here (a genuine "not allowed" rather than a session issue) doesn't
  /// get misread as an expired Admin session.
  static Future<List<EmployeeRecord>> fetchEmployees() async {
    try {
      final response = await ApiClient.instance.get(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Mobile_app/get_emp'),
        requireSession: false,
        treatForbiddenAsExpired: false,
      );
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.whereType<Map>().map((raw) {
        final e = raw;
        return EmployeeRecord(
          empId: e['emp_id']?.toString() ?? '',
          name: (e['Employee_name']?.toString() ?? '').trim(),
          programType: e['program_type']?.toString() ?? '',
          scaleType: e['scale_type']?.toString() ?? '',
          deptName: (e['dept_name']?.toString() ?? '').trim(),
          staffType: e['staff_type']?.toString() ?? '',
          email: e['email_address']?.toString() ?? '',
          mobile: e['mobile_no']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
