import 'employee_attendance_admin_api.dart';

/// A single day's attendance mark ('P'/'A'/'L').
class FacAttendanceMark {
  final int day;
  final String status;
  const FacAttendanceMark({required this.day, required this.status});
}

/// Fetches the Faculty portal's own monthly attendance.
///
/// Backed by the shared `employee_attendance_report` endpoint (via
/// [EmployeeAttendanceAdminApi.fetchMonthlyMarks]) — the old
/// `mobile_app/teacher_attendance` feed returned every day as "A"
/// (Absent), so both Present and Leave days were wrong on the calendar.
///
/// `employeeId` is required (no hardcoded fallback) — callers must pass
/// the real logged-in faculty's id
/// (`SessionManager.instance.getFacultyId()`).
class FacAttendanceApi {
  FacAttendanceApi._();

  static Future<List<FacAttendanceMark>> fetchMonth(
    int month, {
    required String employeeId,
    String branchId = '1',
    int? year,
  }) async {
    final y = year ?? DateTime.now().year;
    final marks = await EmployeeAttendanceAdminApi.fetchMonthlyMarks(empId: employeeId, month: month, year: y);
    return marks.map((m) => FacAttendanceMark(day: m.day, status: m.status)).toList();
  }
}
