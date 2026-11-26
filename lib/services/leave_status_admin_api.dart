import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single employee returned by [LeaveStatusAdminApi.fetchEmployees].
class EmployeeInfo {
  final String empId;
  final String name;
  final String employeeCode;
  final String designation;
  const EmployeeInfo(
    this.empId,
    this.name,
    this.employeeCode,
    this.designation,
  );
}

/// A single leave record returned by [LeaveStatusAdminApi.fetchLeaveDetails].
class LeaveEntry {
  final String title;
  final String status;
  final String applyDate;
  const LeaveEntry({
    required this.title,
    required this.status,
    required this.applyDate,
  });
}

/// Fetches the Admin portal's employee list and per-employee leave
/// history from the AIT SmartCampuses API.
class LeaveStatusAdminApi {
  LeaveStatusAdminApi._();

  static Future<List<EmployeeInfo>> fetchEmployees() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://campus.smartcampuses.com/demo_institute/Mobile_app/get_emp',
            ),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.whereType<Map>().map((e) {
        final empId = e['emp_id']?.toString().trim() ?? '';
        final employeeCode = _firstValue(e, [
          'employee_code',
          'emp_code',
          'Employee_code',
          'Employee_Code',
        ]);
        return EmployeeInfo(
          empId,
          (e['Employee_name']?.toString() ?? '').trim(),
          employeeCode.isEmpty ? empId : employeeCode,
          _firstValue(e, [
            'designation',
            'Designation',
            'employee_designation',
            'emp_designation',
          ]),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<LeaveEntry>> fetchLeaveDetails(String empId) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://campus.smartcampuses.com/demo_institute/Grid/leavegridstatus?emp_id=$empId',
            ),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.map((raw) {
        final e = raw as Map<String, dynamic>;
        return LeaveEntry(
          title: e['leave_title']?.toString() ?? '',
          status: e['Leavestatuss']?.toString() ?? '',
          applyDate: _formatDate(e['apply_date']?.toString() ?? ''),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static String _firstValue(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  /// API sends `yyyy-MM-dd HH:mm:ss`; the UI displays `dd/MM/yyyy`.
  static String _formatDate(String raw) {
    final datePart = raw.split(' ').first;
    final parts = datePart.split('-');
    if (parts.length != 3) return raw;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}
