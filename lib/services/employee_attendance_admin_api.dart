import 'dart:convert';

import 'package:http/http.dart' as http;

import 'holiday_api.dart';

/// A single employee returned by
/// [EmployeeAttendanceAdminApi.fetchEmployees].
class EmployeeInfo {
  final String empId;
  final String name;
  final String deptName;
  const EmployeeInfo(this.empId, this.name, this.deptName);
}

/// A single day's attendance log returned by
/// [EmployeeAttendanceAdminApi.fetchAttendance].
class AttendanceDay {
  final String date;
  final String dayName;
  final String signIn;
  final String signOut;
  final String status;
  final String? leaveType;
  final String? holiday;
  const AttendanceDay({
    required this.date,
    required this.dayName,
    required this.signIn,
    required this.signOut,
    required this.status,
    this.leaveType,
    this.holiday,
  });
}

/// The employee-level fields that come alongside [AttendanceDay]s from
/// [EmployeeAttendanceAdminApi.fetchAttendance] — the report's own
/// `emp_name`/`dept`/`day_off` (independent of [EmployeeInfo], which
/// comes from the separate employee-list endpoint).
class AttendanceReport {
  final String empName;
  final String dept;
  final String dayOff;
  final List<AttendanceDay> days;
  const AttendanceReport({required this.empName, required this.dept, required this.dayOff, required this.days});
}

/// Pre-aggregated attendance totals from
/// `mobile_app/employee_attendance_summary` — the backend does the
/// counting, so the Summary screen no longer sums a day list itself
/// (which used to miscount Day Off / Holiday as Leave).
class AttendanceSummary {
  final String empName;
  final String dept;
  final int present;
  final int absent;
  final int leave;
  final int holiday;
  final int dayOff;
  const AttendanceSummary({
    required this.empName,
    required this.dept,
    required this.present,
    required this.absent,
    required this.leave,
    required this.holiday,
    required this.dayOff,
  });

  /// Counted attendance days (excludes Day Off / Holiday).
  int get workingDays => present + absent + leave;
}

/// Fetches the Admin portal's employee list and per-employee daily
/// attendance log from the AIT SmartCampuses API.
class EmployeeAttendanceAdminApi {
  EmployeeAttendanceAdminApi._();

  static Future<List<EmployeeInfo>> fetchEmployees() async {
    try {
      final response = await http
          .get(Uri.parse('https://campus.smartcampuses.com/demo_institute/Mobile_app/get_emp'), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.map((raw) {
        final e = raw as Map<String, dynamic>;
        return EmployeeInfo(
          e['emp_id']?.toString() ?? '',
          (e['Employee_name']?.toString() ?? '').trim(),
          (e['dept_name']?.toString() ?? '').trim(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Old attendance endpoint — replaced below by `employee_attendance_report`,
  // which returns the same per-day log plus employee/department context in
  // one call. Left here only for reference; no longer called anywhere.
  //
  // static Future<List<AttendanceDay>> fetchAttendance({
  //   required String empId,
  //   required DateTime start,
  //   required DateTime end,
  // }) async {
  //   try {
  //     final url = Uri.parse(
  //       'https://campus.smartcampuses.com/demo_institute/Mobile_app/employee_attendance'
  //       '?emp_id=$empId&start_date=${_isoDate(start)}&end_date=${_isoDate(end)}',
  //     );
  //     final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
  //     if (response.statusCode != 200) return [];
  //
  //     final decoded = jsonDecode(response.body);
  //     if (decoded is! List) return [];
  //
  //     return decoded.map((raw) {
  //       final d = raw as Map<String, dynamic>;
  //       return AttendanceDay(
  //         date: d['date']?.toString() ?? '',
  //         signIn: d['sign_in']?.toString() ?? '',
  //         signOut: d['sign_out']?.toString() ?? '',
  //         status: d['on_leave']?.toString() ?? '',
  //       );
  //     }).toList();
  //   } catch (_) {
  //     return [];
  //   }
  // }

  /// Fetches an employee's attendance report for [from]..[to] (inclusive)
  /// from `mobile_app/employee_attendance_report` — confirmed live: returns
  /// `{success, data: {emp_id, emp_name, dept, day_off, days: [{date,
  /// day_name, status, sign_in, sign_out, leave_type, holiday}, ...]}}`.
  /// Returns null on any request/parse failure or when the server reports
  /// `success: false`.
  static Future<AttendanceReport?> fetchAttendance({
    required String empId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final url = Uri.parse(
        'https://campus.smartcampuses.com/demo_institute/mobile_app/employee_attendance_report'
        '?from=${_ddMmYyyy(from)}&to=${_ddMmYyyy(to)}&emp_id=$empId',
      );
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      // Accept the report whenever a usable `data` object is present —
      // only bail on an explicit `success: false`. (The endpoint has
      // been seen to return `{message, data}` without a `success` flag,
      // which the old `success != true` check wrongly rejected.)
      if (decoded['success'] == false) return null;
      final data = decoded['data'];
      if (data is! Map) return null;

      final daysRaw = data['days'];
      final days = daysRaw is! List
          ? <AttendanceDay>[]
          : daysRaw.whereType<Map>().map((raw) {
              final d = raw.map((k, v) => MapEntry(k.toString(), v));
              return AttendanceDay(
                date: d['date']?.toString() ?? '',
                dayName: d['day_name']?.toString() ?? '',
                signIn: d['sign_in']?.toString() ?? '',
                signOut: d['sign_out']?.toString() ?? '',
                status: d['status']?.toString() ?? '',
                leaveType: d['leave_type']?.toString(),
                holiday: d['holiday']?.toString(),
              );
            }).toList();

      return AttendanceReport(
        empName: (data['emp_name']?.toString() ?? '').trim(),
        dept: (data['dept']?.toString() ?? '').trim(),
        dayOff: (data['day_off']?.toString() ?? '').trim(),
        days: days,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses the attendance feed's `dd-MM-yyyy` date (date-only).
  static DateTime? _feedDate(String raw) {
    final p = raw.trim().split('-');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  /// Classifies one [AttendanceDay] into `P` / `A` / `L` / `H` (holiday)
  /// / `O` (weekly day off), or `null` to skip it entirely.
  ///
  /// Corrections the raw feed needs (order matters):
  ///  1. a real sign-in always wins — an employee who came to work on a
  ///     day that's a "holiday" for students is still **Present**;
  ///  2. an approved leave HR hasn't posted yet arrives as "Absent" but
  ///     still carries a `leave_type` — that's **Leave**;
  ///  3. a multi-day holiday only has its **first** day tagged "Holiday";
  ///     the rest come back as "Absent" — so an Absent day inside a
  ///     [holidayRanges] span is a **Holiday**;
  ///  4. a day that hasn't finished yet (today or later) can't be
  ///     "Absent" — skip it.
  static String? dayMark(AttendanceDay d, List<({DateTime from, DateTime to})> holidayRanges, DateTime today) {
    final s = d.status.trim().toLowerCase();
    final date = _feedDate(d.date);
    final hasLeaveType = d.leaveType != null && d.leaveType!.trim().isNotEmpty;

    if (hasLeaveType || s.startsWith('l')) return 'L';
    if (s.startsWith('p')) return 'P';
    if (s == 'holiday' || (d.holiday != null && d.holiday!.trim().isNotEmpty)) return 'H';
    if (s == 'day off') return 'O';
    if (s.startsWith('a')) {
      final inHolidayRange = date != null &&
          holidayRanges.any((h) => !date.isBefore(h.from) && !date.isAfter(h.to));
      if (inHolidayRange) return 'H';
      if (date != null && !date.isBefore(today)) return null; // today / future
      return 'A';
    }
    return null;
  }

  /// Attendance totals for [from]..[to].
  ///
  /// Primary source is the server-aggregated
  /// `employee_attendance_summary` endpoint — it returns
  /// `present`/`absent`/`leave`/`holiday`/`day_off` already separated
  /// (so Leave is never lumped into Present/Absent). Its `absent` is
  /// then corrected down for any day that actually falls inside a
  /// multi-day holiday span (the feed only tags day 1 as Holiday and
  /// leaves the rest as "Absent"). If that endpoint is unavailable the
  /// per-day [fetchAttendance] feed is classified via [dayMark] instead.
  static Future<AttendanceSummary?> fetchSummary({
    required String empId,
    required DateTime from,
    required DateTime to,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final holidayRanges = await HolidayApi.fetchHolidayRanges();

    // 1. Server-aggregated summary (matches the web portal's own numbers).
    try {
      final url = Uri.parse(
        'https://campus.smartcampuses.com/demo_institute/mobile_app/employee_attendance_summary'
        '?from=${_ddMmYyyy(from)}&to=${_ddMmYyyy(to)}&emp_id=$empId',
      );
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        final data = (decoded is Map && decoded['success'] != false) ? decoded['data'] : null;
        if (data is Map) {
          int n(String k) => int.tryParse(data[k]?.toString() ?? '') ?? 0;
          var absent = n('absent');
          var holiday = n('holiday');

          // Move any "Absent" day that sits inside a holiday span into
          // the Holiday bucket, using the per-day feed as a cross-check.
          if (absent > 0 && holidayRanges.isNotEmpty) {
            final report = await fetchAttendance(empId: empId, from: from, to: to);
            if (report != null) {
              var misfiled = 0;
              for (final d in report.days) {
                final s = d.status.trim().toLowerCase();
                if (!s.startsWith('a')) continue;
                final date = _feedDate(d.date);
                if (date != null && holidayRanges.any((h) => !date.isBefore(h.from) && !date.isAfter(h.to))) misfiled++;
              }
              if (misfiled > 0) {
                absent = (absent - misfiled).clamp(0, absent);
                holiday += misfiled;
              }
            }
          }

          return AttendanceSummary(
            empName: (data['emp_name']?.toString() ?? '').trim(),
            dept: (data['dept']?.toString() ?? '').trim(),
            present: n('present'),
            absent: absent,
            leave: n('leave'),
            holiday: holiday,
            dayOff: n('day_off'),
          );
        }
      }
    } catch (_) {
      // fall through to the per-day computation
    }

    // 2. Fallback: classify the per-day feed ourselves.
    final report = await fetchAttendance(empId: empId, from: from, to: to);
    if (report == null) return null;
    var present = 0, absent = 0, leave = 0, holiday = 0, dayOff = 0;
    for (final d in report.days) {
      switch (dayMark(d, holidayRanges, today)) {
        case 'P':
          present++;
        case 'A':
          absent++;
        case 'L':
          leave++;
        case 'H':
          holiday++;
        case 'O':
          dayOff++;
      }
    }
    return AttendanceSummary(
      empName: report.empName,
      dept: report.dept,
      present: present,
      absent: absent,
      leave: leave,
      holiday: holiday,
      dayOff: dayOff,
    );
  }

  /// Per-day P/A/L marks for one calendar month, derived from
  /// [fetchAttendance] (the reliable `employee_attendance_report`) and
  /// classified through [dayMark] — the shared source for the Employee-
  /// and Faculty-portal attendance calendars. Holiday (incl. multi-day
  /// spans), Day Off and not-yet-finished days are omitted; the rest is
  /// `P` / `A` / `L`.
  static Future<List<({int day, int year, String status})>> fetchMonthlyMarks({
    required String empId,
    required int month,
    required int year,
  }) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0); // last day of `month`
    final results = await Future.wait([
      fetchAttendance(empId: empId, from: from, to: to),
      HolidayApi.fetchHolidayRanges(),
    ]);
    final report = results[0] as AttendanceReport?;
    final holidayRanges = results[1] as List<({DateTime from, DateTime to})>;
    if (report == null) return [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final out = <({int day, int year, String status})>[];
    for (final d in report.days) {
      final letter = dayMark(d, holidayRanges, today);
      if (letter != 'P' && letter != 'A' && letter != 'L') continue;
      final day = _feedDate(d.date)?.day;
      if (day == null) continue;
      out.add((day: day, year: year, status: letter!));
    }
    return out;
  }

  static String _ddMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().padLeft(4, '0')}';
}
