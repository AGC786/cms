import 'package:flutter/material.dart';
import '../../services/course_attendance_admin_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class CourseAttendanceScreen extends StatefulWidget {
  const CourseAttendanceScreen({super.key});

  @override
  State<CourseAttendanceScreen> createState() => _CourseAttendanceScreenState();
}

class _CourseAttendanceScreenState extends State<CourseAttendanceScreen> {
  bool _loadingCampuses = true;
  List<IdName> _campuses = [];
  String? campusId;

  bool _loadingPrograms = false;
  List<IdName> _programs = [];
  String? programId;

  bool _loadingShifts = false;
  List<IdName> _shifts = [];
  String? shiftId;

  bool _loadingYears = false;
  List<YearOption> _years = [];
  String? classId;
  String? sectionId;

  bool _loadingCourses = false;
  List<CourseOption> _courses = [];
  String? courseId;

  DateTime date = DateTime.now();
  bool showError = false;
  bool _loading = false;
  bool searched = false;
  CourseAttendanceResult? _result;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    final campuses = await CourseAttendanceAdminApi.fetchCampuses();
    if (!mounted) return;
    setState(() {
      _campuses = campuses;
      _loadingCampuses = false;
    });
  }

  Future<void> _selectCampus(String? id) async {
    setState(() {
      campusId = id;
      programId = shiftId = classId = sectionId = courseId = null;
      _programs = _shifts = [];
      _years = [];
      _courses = [];
      searched = false;
      _loadingPrograms = id != null;
    });
    if (id == null) return;
    final programs = await CourseAttendanceAdminApi.fetchPrograms(id);
    if (!mounted) return;
    setState(() {
      _programs = programs;
      _loadingPrograms = false;
    });
  }

  Future<void> _selectProgram(String? id) async {
    setState(() {
      programId = id;
      shiftId = classId = sectionId = courseId = null;
      _shifts = [];
      _years = [];
      _courses = [];
      searched = false;
      _loadingShifts = id != null;
    });
    if (id == null) return;
    final shifts = await CourseAttendanceAdminApi.fetchShifts(id);
    if (!mounted) return;
    setState(() {
      _shifts = shifts;
      _loadingShifts = false;
    });
  }

  Future<void> _selectShift(String? id) async {
    setState(() {
      shiftId = id;
      classId = sectionId = courseId = null;
      _years = [];
      _courses = [];
      searched = false;
      _loadingYears = id != null;
    });
    if (id == null || campusId == null) return;
    final years = await CourseAttendanceAdminApi.fetchYears(campusId!, id);
    if (!mounted) return;
    setState(() {
      _years = years;
      _loadingYears = false;
    });
  }

  Future<void> _selectYear(String? id) async {
    // [id] is a `class_section_id` — the backend returns one row per
    // section and every section of the same year shares one `class_id`,
    // so keying the dropdown on `class_id` collapsed the four sections
    // into a single visible entry.
    final year = _years.where((y) => y.sectionId == id);
    final resolvedClassId = year.isNotEmpty ? year.first.classId : null;
    setState(() {
      sectionId = id;
      classId = resolvedClassId;
      courseId = null;
      _courses = [];
      searched = false;
      _loadingCourses = id != null;
    });
    if (id == null || programId == null || resolvedClassId == null) return;
    final courses = await CourseAttendanceAdminApi.fetchCourses(programId!, resolvedClassId);
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _loadingCourses = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _view() async {
    if (campusId == null || programId == null || shiftId == null || classId == null || sectionId == null || courseId == null) {
      setState(() {
        showError = true;
        searched = false;
      });
      return;
    }
    setState(() {
      showError = false;
      _loading = true;
    });
    final result = await CourseAttendanceAdminApi.fetchAttendance(
      branchId: campusId!,
      programId: programId!,
      batchId: shiftId!,
      classId: classId!,
      sectionId: sectionId!,
      courseId: courseId!,
      date: date,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      searched = true;
      _loading = false;
    });
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${_months[d.month - 1]}-${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Course Attendance'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DarkPillDropdown<String>(
                      hint: _loadingCampuses ? 'Loading...' : 'Select Campus',
                      value: campusId,
                      items: _campuses.map((c) => c.id).toList(),
                      labelOf: (id) => _campuses.firstWhere((c) => c.id == id, orElse: () => IdName(id, id)).name,
                      onChanged: _loadingCampuses ? null : _selectCampus,
                    ),
                    const SizedBox(height: 10),
                    DarkPillDropdown<String>(
                      hint: _loadingPrograms ? 'Loading...' : 'Select Program',
                      value: programId,
                      items: _programs.map((p) => p.id).toList(),
                      labelOf: (id) => _programs.firstWhere((p) => p.id == id, orElse: () => IdName(id, id)).name,
                      onChanged: campusId == null || _loadingPrograms ? null : _selectProgram,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DarkPillDropdown<String>(
                            hint: _loadingShifts ? 'Loading...' : 'Batch',
                            value: shiftId,
                            items: _shifts.map((s) => s.id).toList(),
                            labelOf: (id) => _shifts.firstWhere((s) => s.id == id, orElse: () => IdName(id, id)).name,
                            onChanged: programId == null || _loadingShifts ? null : _selectShift,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DarkPillDropdown<String>(
                            hint: _loadingYears ? 'Loading...' : 'Year',
                            value: sectionId,
                            items: _years.map((y) => y.sectionId).toList(),
                            labelOf: (id) => _years.firstWhere((y) => y.sectionId == id, orElse: () => YearOption('', id, id)).name,
                            onChanged: shiftId == null || _loadingYears ? null : _selectYear,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DarkPillDropdown<String>(
                      hint: _loadingCourses ? 'Loading...' : 'Select Course',
                      value: courseId,
                      items: _courses.map((c) => c.subId).toList(),
                      labelOf: (id) => _courses.firstWhere((c) => c.subId == id, orElse: () => CourseOption(id, id)).name,
                      onChanged: classId == null || _loadingCourses ? null : (id) => setState(() => courseId = id),
                    ),
                    const SizedBox(height: 10),
                    UnderlineDateField(label: 'Date:', value: _fmt(date), onTap: _pickDate),
                    FieldError(message: 'Please select all fields.', show: showError),
                    const SizedBox(height: 14),
                    Center(child: MaroonPillButton(label: _loading ? 'Loading...' : 'View', onPressed: _loading ? () {} : _view)),
                    if (searched && _result != null) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: StatBlock(label: 'Total Students', value: '${_result!.totalStudents}', color: AppColors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: StatBlock(label: 'Present', value: '${_result!.present}', color: AppColors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: StatBlock(label: 'Absent', value: '${_result!.absent}', color: AppColors.orange)),
                          const SizedBox(width: 8),
                          Expanded(child: StatBlock(label: 'Leave', value: '${_result!.leave}', color: AppColors.blueMid)),
                        ],
                      ),
                    ],
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
