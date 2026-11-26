import 'employee_attendance_admin_api.dart';

/// A single day's attendance status ('P'resent / 'A'bsent / 'L'eave).
class AttendanceMark {
  final int day;
  final int year;
  final String status;
  const AttendanceMark({required this.day, required this.year, required this.status});
}

/// Fetches the Employee portal's own monthly attendance.
///
/// Backed by the shared `employee_attendance_report` endpoint (via
/// [EmployeeAttendanceAdminApi.fetchMonthlyMarks]) — the old
/// `Employee/employee_Attendance` feed is blocked by the server's
/// Mod_Security and, when it did respond, marked approved-leave days as
/// plain Present/Absent so "Leave" never showed on the calendar.
///
/// `staffId` is required (no hardcoded fallback) — callers must pass the
/// real logged-in employee's id (`SessionManager.instance.getStaffId()`).
class EmpAttendanceApi {
  EmpAttendanceApi._();

  static Future<List<AttendanceMark>> fetchMonth(int month, {required String staffId, int? year}) async {
    final y = year ?? DateTime.now().year;
    final marks = await EmployeeAttendanceAdminApi.fetchMonthlyMarks(empId: staffId, month: month, year: y);
    return marks.map((m) => AttendanceMark(day: m.day, year: m.year, status: m.status)).toList();
  }
}
