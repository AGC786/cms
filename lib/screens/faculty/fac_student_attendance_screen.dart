import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/fac_student_attendance_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/natural_sort.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart';

class _StudentRow {
  final String id, name, rollNo;
  String status;
  _StudentRow(this.id, this.name, this.rollNo) : status = '';
}

/// Faculty marks student attendance here — program/batch/year/course
/// filters, then a per-student present/absent/leave picker, all backed
/// by the AIT SmartCampuses API.
class FacStudentAttendanceScreen extends StatefulWidget {
  const FacStudentAttendanceScreen({super.key});

  @override
  State<FacStudentAttendanceScreen> createState() => _FacStudentAttendanceScreenState();
}

class _FacStudentAttendanceScreenState extends State<FacStudentAttendanceScreen> {
  bool _loadingPrograms = true;
  List<FacProgramOption> _programs = [];
  bool _loadingShifts = false;
  List<FacShiftOption> _shifts = [];
  bool _loadingYears = false;
  List<FacYearOption> _years = [];
  bool _loadingCourses = false;
  List<FacCourseOption> _courses = [];
  List<FacCourseTypeOption> _courseTypes = [];

  String? sessionId;
  String? batchId;
  String? classId;
  String? sectionId;
  String? courseId;
  String? courseTypeId;
  DateTime date = DateTime.now();

  List<_StudentRow> students = [];
  bool _viewed = false;
  bool _unavailable = false;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    final loaded = await FacStudentAttendanceApi.fetchPrograms();
    if (!mounted) return;
    setState(() {
      _programs = sortNatural(loaded ?? [], (p) => p.name);
      _loadingPrograms = false;
    });
  }

  Future<void> _selectProgram(String? id) async {
    setState(() {
      sessionId = id;
      batchId = classId = sectionId = courseId = courseTypeId = null;
      _shifts = [];
      _years = [];
      _courses = [];
      _courseTypes = [];
      _viewed = false;
      _loadingShifts = id != null;
    });
    if (id == null) return;
    final loaded = await FacStudentAttendanceApi.fetchShifts(id);
    if (!mounted) return;
    setState(() {
      _shifts = sortNatural(loaded ?? [], (s) => s.title);
      _loadingShifts = false;
    });
  }

  Future<void> _selectShift(String? id) async {
    setState(() {
      batchId = id;
      classId = sectionId = courseId = courseTypeId = null;
      _years = [];
      _courses = [];
      _courseTypes = [];
      _viewed = false;
      _loadingYears = id != null;
    });
    if (id == null) return;
    final loaded = await FacStudentAttendanceApi.fetchYears(id);
    if (!mounted) return;
    setState(() {
      _years = sortNatural(loaded ?? [], (y) => y.name);
      _loadingYears = false;
    });
  }

  Future<void> _selectYear(String? id) async {
    final year = _years.where((y) => y.classId == id);
    setState(() {
      classId = id;
      sectionId = year.isNotEmpty ? year.first.sectionId : null;
      courseId = courseTypeId = null;
      _courses = [];
      _courseTypes = [];
      _viewed = false;
      _loadingCourses = id != null && sessionId != null;
    });
    if (id == null || sessionId == null || year.isEmpty) return;
    final loaded = await FacStudentAttendanceApi.fetchCourses(sessionId: sessionId!, className: year.first.name);
    if (!mounted) return;
    setState(() {
      _courses = sortNatural(loaded?.$1 ?? [], (c) => c.name);
      _courseTypes = sortNatural(loaded?.$2 ?? [], (t) => t.name);
      _loadingCourses = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted || picked == null) return;
    setState(() => date = picked);
  }

  Future<void> _loadStudents() async {
    if (courseId == null || courseTypeId == null || classId == null || sectionId == null || batchId == null) {
      showToast(context, 'Please select a course');
      return;
    }
    setState(() {
      _loading = true;
      _viewed = true;
      _unavailable = false;
      students = [];
    });
    final rows = await FacStudentAttendanceApi.fetchStudents(
      date1: _apiDate,
      courseTypeId: courseTypeId!,
      courseId: courseId!,
      batchId: batchId!,
      classId: classId!,
      sectionId: sectionId!,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (rows == null) {
        _unavailable = true;
      } else {
        students = rows.map((r) => _StudentRow(r.studentId, r.name, r.rollNo)).toList();
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Present':
        return AppColors.green;
      case 'Absent':
        return AppColors.red;
      case 'Leave':
        return AppColors.orange;
      default:
        return AppColors.muted;
    }
  }

  Future<void> _save() async {
    if (_unavailable) {
      showToast(context, 'Unable to save — this feature requires an active Faculty session');
      return;
    }
    if (students.isEmpty || students.any((s) => s.status.isEmpty)) {
      showToast(context, 'Please mark attendance for all students');
      return;
    }
    final year = _years.where((y) => y.classId == classId);
    if (year.isEmpty) return;

    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';

    final ok = await FacStudentAttendanceApi.saveAttendance(
      date1: _apiDate,
      courseTypeId: courseTypeId!,
      courseId: courseId!,
      className: year.first.name,
      classId: classId!,
      sectionId: sectionId!,
      username: username,
      students: students.map((s) => FacStudentRow(s.id, s.name, s.rollNo)).toList(),
      statusByStudentId: {for (final s in students) s.id: s.status},
    );
    if (!mounted) return;
    setState(() => _saving = false);
    showToast(context, ok ? 'Attendance saved successfully' : 'Failed to save attendance');
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  String get _formattedDate =>
      '${date.day.toString().padLeft(2, '0')}-${_months[date.month - 1]}-${date.year}';

  /// The backend expects `dd-mm-yyyy`.
  String get _apiDate =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Student Attendance', color: AppColors.blueMid),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DarkPillDropdown<String>(
                      hint: _loadingPrograms ? 'Loading...' : 'Program',
                      value: sessionId,
                      items: _programs.map((p) => p.id).toList(),
                      labelOf: (id) => _programs.firstWhere((p) => p.id == id, orElse: () => FacProgramOption(id, id)).name,
                      onChanged: _selectProgram,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DarkPillDropdown<String>(
                            hint: _loadingShifts ? 'Loading...' : 'Batch',
                            value: batchId,
                            items: _shifts.map((s) => s.id).toList(),
                            labelOf: (id) => _shifts.firstWhere((s) => s.id == id, orElse: () => FacShiftOption(id, id)).title,
                            onChanged: _selectShift,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DarkPillDropdown<String>(
                            hint: _loadingYears ? 'Loading...' : 'Year',
                            value: classId,
                            items: _years.map((y) => y.classId).toList(),
                            labelOf: (id) => _years.firstWhere((y) => y.classId == id, orElse: () => FacYearOption(classId: id, sectionId: '', name: id)).name,
                            onChanged: _selectYear,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DarkPillDropdown<String>(
                            hint: _loadingCourses ? 'Loading...' : 'Course',
                            value: courseId,
                            items: _courses.map((c) => c.id).toList(),
                            labelOf: (id) => _courses.firstWhere((c) => c.id == id, orElse: () => FacCourseOption(id, id)).name,
                            onChanged: (v) => setState(() => courseId = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DarkPillDropdown<String>(
                            hint: 'Select Course',
                            value: courseTypeId,
                            items: _courseTypes.map((t) => t.id).toList(),
                            labelOf: (id) => _courseTypes.firstWhere((t) => t.id == id, orElse: () => FacCourseTypeOption(id, id)).name,
                            onChanged: (v) => setState(() => courseTypeId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line, width: 1))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_formattedDate, style: const TextStyle(fontSize: 16, color: AppColors.ink, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_drop_down_circle, size: 20, color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    BluePillButton(label: _loading ? 'Loading...' : 'View', onPressed: _loading ? () {} : _loadStudents),
                    const SizedBox(height: 20),
                    const Text('Student List:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Divider(color: AppColors.line, height: 20, thickness: 1),
                    if (_viewed && _unavailable)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Unable to load students — this feature requires an active Faculty session, which isn\'t available yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    if (_viewed && !_unavailable && students.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No students found for the selected criteria.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                      ),
                    if (_viewed && !_unavailable)
                      ...students.map(
                        (s) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              if (s.rollNo.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('Roll No: ${s.rollNo}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: ['Present', 'Absent', 'Leave']
                                    .map((status) => InkWell(
                                          onTap: () => setState(() => s.status = status),
                                          child: Row(
                                            children: [
                                              Icon(
                                                s.status == status ? Icons.radio_button_checked : Icons.radio_button_off,
                                                size: 18,
                                                color: _statusColor(status),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(status, style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    BluePillButton(label: _saving ? 'Saving...' : 'Save Attendance', onPressed: _saving ? () {} : _save),
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
