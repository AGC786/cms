import 'package:flutter/material.dart';
import '../../services/employee_attendance_admin_api.dart';
import '../../services/holiday_api.dart';
import '../../utils/time_format.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  State<EmployeeAttendanceScreen> createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  final nameCtrl = TextEditingController();
  DateTime from = DateTime.now().subtract(const Duration(days: 7));
  DateTime to = DateTime.now();

  bool _loadingEmployees = true;
  List<EmployeeInfo> _employees = [];
  EmployeeInfo? _selected;

  bool _loading = false;
  bool _searched = false;
  AttendanceReport? _report;
  List<({DateTime from, DateTime to})> _holidayRanges = const [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await EmployeeAttendanceAdminApi.fetchEmployees();
    if (!mounted) return;
    setState(() {
      _employees = employees;
      _loadingEmployees = false;
    });
  }

  List<EmployeeInfo> get _matches {
    final q = nameCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    // Match name *or* employee id — the field hint says "name or id"
    // (e.g. "0109" / "109" for Ali Imran Siddiqui).
    return _employees
        .where((e) => e.name.toLowerCase().contains(q) || e.empId.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: isFrom ? from : to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isFrom ? from = picked : to = picked);
  }

  /// Resolves the employee to query: the tapped suggestion if there is
  /// one, otherwise the typed text if it uniquely identifies an employee
  /// (exact id/name match, or a single search hit) — so hitting "View
  /// Attendance" right after typing works instead of silently doing
  /// nothing.
  EmployeeInfo? _resolveEmployee() {
    if (_selected != null) return _selected;
    final q = nameCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final e in _employees) {
      if (e.empId.toLowerCase() == q || e.name.toLowerCase() == q) return e;
    }
    final hits = _matches;
    return hits.length == 1 ? hits.first : null;
  }

  Future<void> _view() async {
    final emp = _resolveEmployee();
    if (emp == null || to.isBefore(from)) {
      showToast(context, emp == null ? 'Please select an employee from the search suggestions.' : 'Please pick a valid date range.');
      return;
    }
    if (_selected != emp) {
      setState(() {
        _selected = emp;
        nameCtrl.text = emp.name;
      });
    }
    setState(() {
      _loading = true;
      _searched = false;
    });
    final results = await Future.wait([
      EmployeeAttendanceAdminApi.fetchAttendance(empId: emp.empId, from: from, to: to),
      HolidayApi.fetchHolidayRanges(),
    ]);
    if (!mounted) return;
    final report = results[0] as AttendanceReport?;
    setState(() {
      _loading = false;
      _searched = true;
      _report = report;
      _holidayRanges = results[1] as List<({DateTime from, DateTime to})>;
    });
    if (report == null) showToast(context, 'Unable to load attendance for ${emp.name}.');
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  /// P / A / L for a day that should show in the table, or null to hide
  /// it (Day Off, Holiday incl. multi-day spans, not-yet-finished days).
  String? _visibleMark(AttendanceDay d) {
    final n = DateTime.now();
    final mark = EmployeeAttendanceAdminApi.dayMark(d, _holidayRanges, DateTime(n.year, n.month, n.day));
    return (mark == 'P' || mark == 'A' || mark == 'L') ? mark : null;
  }

  /// The rows to render: P/A/L days, but cut off after the last day that
  /// has real recorded attendance (a sign-in, or an explicit Leave).
  /// The backend pre-fills every calendar day and stamps un-entered ones
  /// as "Absent" — those trailing auto-filled rows are dropped so the
  /// table just stops where the actual data does.
  List<({AttendanceDay day, String mark})> _tableRows(AttendanceReport report) {
    final rows = <({AttendanceDay day, String mark})>[];
    for (final d in report.days) {
      final mark = _visibleMark(d);
      if (mark != null) rows.add((day: d, mark: mark));
    }
    var lastReal = -1;
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final recorded = r.mark == 'L' ||
          r.day.signIn.trim().isNotEmpty ||
          r.day.signOut.trim().isNotEmpty;
      if (recorded) lastReal = i;
    }
    return lastReal < 0 ? const [] : rows.sublist(0, lastReal + 1);
  }

  Color _letterColor(String letter) {
    switch (letter) {
      case 'P':
        return AppColors.green;
      case 'A':
        return AppColors.red;
      case 'L':
        return AppColors.gold;
      default:
        return AppColors.orange;
    }
  }

  String _hours(String signIn, String signOut) {
    if (signIn.isEmpty || signOut.isEmpty) return '-';
    final inTime = _parseTimeOfDay(signIn);
    final outTime = _parseTimeOfDay(signOut);
    if (inTime == null || outTime == null) return '-';
    var minutes = (outTime.hour * 60 + outTime.minute) - (inTime.hour * 60 + inTime.minute);
    if (minutes < 0) minutes += 24 * 60;
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  TimeOfDay? _parseTimeOfDay(String raw) {
    // Backend sends "HH:MM:SS AM/PM" (e.g. "02:38:00 PM") — the optional
    // ":SS" must be consumed so the trailing AM/PM is captured, otherwise
    // every afternoon time was read as morning and the Hours column came
    // out wrong across the AM/PM boundary.
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?').firstMatch(raw.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Employee Attendance'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: _loadingEmployees ? 'Loading employees...' : 'Search by name or id',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onChanged: (v) => setState(() => _selected = null),
                    ),
                    if (_selected == null && _matches.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: _matches
                              .map((e) => DirectoryCard(
                                    name: e.name,
                                    sub: e.deptName,
                                    onTap: () => setState(() {
                                      _selected = e;
                                      nameCtrl.text = e.name;
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: UnderlineDateField(label: 'From Date:', value: _fmt(from), onTap: () => _pickDate(true))),
                        const SizedBox(width: 10),
                        Expanded(child: UnderlineDateField(label: 'To Date:', value: _fmt(to), onTap: () => _pickDate(false))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Center(child: MaroonPillButton(label: _loading ? 'Loading...' : 'View Attendance', onPressed: _loading ? () {} : _view)),
                    if (_searched && report != null && _tableRows(report).isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text('No attendance recorded for this range.', style: TextStyle(color: AppColors.muted)),
                      )
                    else if (_searched && report != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Table(
                          border: const TableBorder(horizontalInside: BorderSide(color: AppColors.line)),
                          columnWidths: const {
                            0: FlexColumnWidth(1.3),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1),
                            4: FlexColumnWidth(0.7),
                          },
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(color: AppColors.blueMid),
                              children: [
                                _AttnHeaderCell('Date', alignLeft: true),
                                _AttnHeaderCell('Sign In'),
                                _AttnHeaderCell('Sign Out'),
                                _AttnHeaderCell('Hours'),
                                _AttnHeaderCell('Status'),
                              ],
                            ),
                            // Day Off, Holiday (incl. multi-day spans the
                            // feed mislabels as Absent) and not-yet-
                            // finished days are dropped; the list also
                            // stops after the last genuinely recorded day
                            // so the feed's trailing auto-filled "Absent"
                            // rows don't show.
                            for (final r in _tableRows(report))
                              TableRow(
                                decoration: const BoxDecoration(color: Colors.white),
                                children: [
                                  _AttnCell(r.day.date, alignLeft: true),
                                  _AttnCell(r.day.signIn.isEmpty ? '-' : formatClockTime(r.day.signIn)),
                                  _AttnCell(r.day.signOut.isEmpty ? '-' : formatClockTime(r.day.signOut)),
                                  _AttnCell(_hours(r.day.signIn, r.day.signOut)),
                                  _AttnCell(r.mark, color: _letterColor(r.mark), bold: true),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ] else if (_searched && report == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text('No attendance data found for this range.', style: TextStyle(color: AppColors.muted)),
                      ),
                  ],
                ),
              ),
            ),
            const FooterUrl(),
          ],
        ),
      ),
    );
  }

}

class _AttnHeaderCell extends StatelessWidget {
  final String text;
  final bool alignLeft;
  const _AttnHeaderCell(this.text, {this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      child: Text(text, textAlign: alignLeft ? TextAlign.left : TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.white)),
    );
  }
}

class _AttnCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;
  final bool alignLeft;
  const _AttnCell(this.text, {this.color, this.bold = false, this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(fontSize: 10.5, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.ink),
      ),
    );
  }
}
