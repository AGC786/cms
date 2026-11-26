import 'package:flutter/material.dart';
import '../../services/employee_attendance_admin_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class EmployeeSummaryScreen extends StatefulWidget {
  const EmployeeSummaryScreen({super.key});

  @override
  State<EmployeeSummaryScreen> createState() => _EmployeeSummaryScreenState();
}

class _EmployeeSummaryScreenState extends State<EmployeeSummaryScreen> {
  final nameCtrl = TextEditingController();
  DateTime from = DateTime.now().subtract(const Duration(days: 30));
  DateTime to = DateTime.now();

  bool _loadingEmployees = true;
  List<EmployeeInfo> _employees = [];
  EmployeeInfo? _selected;

  bool _loading = false;
  bool _searched = false;
  AttendanceSummary? _summary;

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
    // Match name *or* employee id — the field hint says "name or id".
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
  /// (exact id/name match, or a single search hit).
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
    final summary = await EmployeeAttendanceAdminApi.fetchSummary(empId: emp.empId, from: from, to: to);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _searched = true;
      _summary = summary;
    });
    if (summary == null) showToast(context, 'Unable to load attendance for ${emp.name}.');
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = _summary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Employee Attendance Summary'),
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
                    Center(child: MaroonPillButton(label: _loading ? 'Loading...' : 'View Summary', onPressed: _loading ? () {} : _view)),
                    if (_searched && s != null) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: StatBlock(label: 'Total Days', value: '${s.workingDays}', color: AppColors.blueMid)),
                          const SizedBox(width: 8),
                          Expanded(child: StatBlock(label: 'Present', value: '${s.present}', color: AppColors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: StatBlock(label: 'Absent', value: '${s.absent}', color: AppColors.red)),
                          const SizedBox(width: 8),
                          Expanded(child: StatBlock(label: 'Leave', value: '${s.leave}', color: AppColors.orange)),
                        ],
                      ),
                    ] else if (_searched && s == null)
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
