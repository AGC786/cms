import 'package:flutter/material.dart';
import '../../services/student_directory_admin_api.dart';
import '../../services/student_attendance_admin_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final nameCtrl = TextEditingController();
  // Student attendance is mostly historical, so a 7-day default almost
  // always came back empty — start a full year back instead.
  DateTime from = DateTime.now().subtract(const Duration(days: 365));
  DateTime to = DateTime.now();

  bool _loadingStudents = true;
  List<StudentRecord> _students = [];
  StudentRecord? _selected;

  bool _loading = false;
  bool _searched = false;
  StudentAttendanceSummary? _report;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final students = await StudentDirectoryAdminApi.fetchStudents();
    if (!mounted) return;
    setState(() {
      _students = students;
      _loadingStudents = false;
    });
  }

  List<StudentRecord> get _matches {
    final q = nameCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _students.where((s) => s.matches(q)).take(6).toList();
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

  Future<void> _view() async {
    final student = _selected;
    if (student == null || to.isBefore(from)) {
      showToast(context, student == null ? 'Please select a student from the search suggestions.' : 'Please pick a valid date range.');
      return;
    }
    setState(() {
      _loading = true;
      _searched = false;
    });
    final report = await StudentAttendanceAdminApi.fetchSummary(studentId: student.studentId, from: from, to: to);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _searched = true;
      _report = report;
    });
    if (report == null) showToast(context, 'No attendance found for ${student.name} in this range.');
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Student Attendance'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: _loadingStudents ? 'Loading students...' : 'Search by name or GR No.',
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
                              .map((s) => DirectoryCard(
                                    name: s.name,
                                    sub: '${s.program} • ${s.grNo}',
                                    onTap: () => setState(() {
                                      _selected = s;
                                      nameCtrl.text = s.name;
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
                    if (_searched && report != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: StatBlock(label: 'Total Days', value: '${report.totalDays}', color: AppColors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: StatBlock(label: 'Present', value: '${report.present}', color: AppColors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: StatBlock(label: 'Absent', value: '${report.absent}', color: AppColors.orange)),
                          const SizedBox(width: 8),
                          Expanded(child: StatBlock(label: 'Leave', value: '${report.leave}', color: AppColors.blueMid)),
                        ],
                      ),
                      if (report.perCourse.isNotEmpty) ...[
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
                              0: FlexColumnWidth(1.8),
                              1: FlexColumnWidth(0.7),
                              2: FlexColumnWidth(0.7),
                              3: FlexColumnWidth(0.7),
                            },
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(color: AppColors.blueMid),
                                children: [
                                  _AttnHeaderCell('Course', alignLeft: true),
                                  _AttnHeaderCell('P'),
                                  _AttnHeaderCell('A'),
                                  _AttnHeaderCell('L'),
                                ],
                              ),
                              for (final c in report.perCourse)
                                TableRow(
                                  decoration: const BoxDecoration(color: Colors.white),
                                  children: [
                                    _AttnCell(c.courseName.isEmpty ? '-' : c.courseName, alignLeft: true),
                                    _AttnCell('${c.present}', color: AppColors.green, bold: true),
                                    _AttnCell('${c.absent}', color: AppColors.red, bold: true),
                                    _AttnCell('${c.leave}', color: AppColors.blueMid, bold: true),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
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
