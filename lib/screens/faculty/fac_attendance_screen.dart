import 'package:flutter/material.dart';
import '../../services/fac_attendance_api.dart';
import '../../services/fac_leave_status_api.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart' hide StatBlock;

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Faculty's own attendance calendar, fetching the real monthly
/// present/absent/leave log from the AIT SmartCampuses API.
class FacAttendanceScreen extends StatefulWidget {
  const FacAttendanceScreen({super.key});

  @override
  State<FacAttendanceScreen> createState() => _FacAttendanceScreenState();
}

class _FacAttendanceScreenState extends State<FacAttendanceScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  int _selectedMonth = DateTime.now().month - 1; // 0-based
  int _year = DateTime.now().year;

  /// Years offered in the Year dropdown — current year back seven years,
  /// newest first.
  static final List<int> _years = List.generate(7, (i) => DateTime.now().year - i);

  bool _loading = true;
  bool _noSession = false;
  Map<int, String> _statusByDay = {};

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps the attendance log for the selected month in step with the
    // web portal without a manual refresh (see AutoRefreshMixin) — uses
    // the silent variant so it doesn't flash the loading spinner over
    // an already visible calendar every poll.
    startAutoRefresh(_refreshLiveData);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _refreshLiveData();
  }

  Future<void> _refreshLiveData() async {
    // Use the real logged-in faculty's emp_id (saved at login). If it's
    // missing, the user isn't actually logged in as faculty — show that
    // plainly instead of silently fetching the API's demo persona's data
    // and presenting it as if it were the real user's attendance.
    final empId = await SessionManager.instance.getFacultyId();
    if (empId == null || empId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _noSession = true;
        _statusByDay = {};
        _loading = false;
      });
      return;
    }

    final marks = await FacAttendanceApi.fetchMonth(_selectedMonth + 1, employeeId: empId, year: _year);
    final map = {for (final m in marks) m.day: m.status};

    // The attendance feed only turns a day into "Leave" once HR posts the
    // approved leave into the attendance table — until then an approved
    // leave day still reads as Absent (no sign-in). Cross-reference the
    // faculty's own approved leave applications and mark those days 'L'.
    final leaveDays = await _approvedLeaveDays(_year, _selectedMonth + 1);
    for (final d in leaveDays) {
      final cur = map[d];
      if (cur == null || cur == 'A') map[d] = 'L';
    }

    if (!mounted) return;
    setState(() {
      _noSession = false;
      _statusByDay = map;
      _loading = false;
    });
  }

  /// Day-of-month numbers within [year]/[month] (1-based) that fall
  /// inside an **Approved** faculty leave application.
  Future<Set<int>> _approvedLeaveDays(int year, int month) async {
    final leaves = await FacLeaveStatusApi.fetchLeaveStatus();
    if (leaves == null) return {};
    final out = <int>{};
    for (final l in leaves) {
      if (l.status.trim().toLowerCase() != 'approved') continue;
      final from = _parseLeaveDate(l.startDate);
      final to = _parseLeaveDate(l.endDate);
      if (from == null || to == null) continue;
      var d = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day);
      while (!d.isAfter(end)) {
        if (d.year == year && d.month == month) out.add(d.day);
        d = d.add(const Duration(days: 1));
      }
    }
    return out;
  }

  /// Parses a leave date that may arrive as `yyyy-MM-dd` or `dd-MM-yyyy`.
  static DateTime? _parseLeaveDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    final p = s.split(RegExp(r'[-/]'));
    if (p.length != 3) return null;
    final a = int.tryParse(p[0]), b = int.tryParse(p[1]), c = int.tryParse(p[2]);
    if (a == null || b == null || c == null) return null;
    if (c > 31) return DateTime(c, b, a); // dd-MM-yyyy
    if (a > 31) return DateTime(a, b, c); // yyyy-MM-dd
    return null;
  }

  Color _dotColor(String? status) {
    switch (status) {
      case 'P':
        return AppColors.green;
      case 'A':
        return AppColors.red;
      case 'L':
        return AppColors.gold;
      default:
        return Colors.transparent;
    }
  }

  int _daysInMonth(int y, int m) => DateTime(y, m + 2, 0).day;
  int _firstWeekday(int y, int m) => DateTime(y, m + 1, 1).weekday % 7; // 0=Sun

  @override
  Widget build(BuildContext context) {
    final total = _daysInMonth(_year, _selectedMonth);
    final start = _firstWeekday(_year, _selectedMonth);
    int present = 0, absent = 0, leave = 0;
    for (final status in _statusByDay.values) {
      switch (status) {
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Attendance Details', color: AppColors.blueMid),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DarkPillDropdown<int>(
                      hint: 'Select Year',
                      value: _year,
                      items: _years,
                      labelOf: (y) => '$y',
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _year = v);
                        _load();
                      },
                    ),
                    const SizedBox(height: 10),
                    DarkPillDropdown<int>(
                      hint: 'Select Month',
                      value: _selectedMonth,
                      items: List.generate(_monthNames.length, (i) => i),
                      labelOf: (i) => _monthNames[i],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedMonth = v);
                        _load();
                      },
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: AppColors.blueMid),
                      )
                    else if (_noSession)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Session expired. Please log in again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 15),
                        ),
                      )
                    else ...[
                      Text('${_monthNames[_selectedMonth]} $_year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF7F7FB), borderRadius: BorderRadius.circular(16)),
                        child: AttendanceMonthGrid(
                          daysInMonth: total,
                          firstWeekday: start,
                          colorForDay: (d) => _dotColor(_statusByDay[d]),
                          dotStyle: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: StatBlock(label: 'Total Present', value: '$present', color: AppColors.green)),
                          const SizedBox(width: 6),
                          Expanded(child: StatBlock(label: 'Total Absent', value: '$absent', color: AppColors.red)),
                          const SizedBox(width: 6),
                          Expanded(child: StatBlock(label: 'Total Leave', value: '$leave', color: AppColors.gold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const GradientFooterBar(),
    );
  }
}
