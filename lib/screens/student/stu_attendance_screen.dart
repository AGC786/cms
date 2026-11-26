import 'package:flutter/material.dart';
import '../../services/stu_attendance_api.dart';
import '../../services/stu_courses_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart' hide StatBlock;

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class StuAttendanceScreen extends StatefulWidget {
  const StuAttendanceScreen({super.key});

  @override
  State<StuAttendanceScreen> createState() => _StuAttendanceScreenState();
}

class _StuAttendanceScreenState extends State<StuAttendanceScreen> {
  bool _loadingCourses = true;
  List<StuCourse> _courses = [];
  String? subId;

  int _month = DateTime.now().month;
  final int _year = DateTime.now().year;

  bool _loading = false;
  bool _searched = false;
  Map<int, String> _statusByDay = {};

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await StuAttendanceApi.fetchCourses();
    if (!mounted) return;
    setState(() {
      _courses = courses ?? [];
      _loadingCourses = false;
    });
  }

  Future<void> _view() async {
    if (subId == null) {
      showToast(context, 'Please select a course');
      return;
    }
    setState(() {
      _loading = true;
      _searched = false;
    });
    final marks = await StuAttendanceApi.fetchAttendance(subId: subId!, month: _month, year: _year);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _searched = true;
      _statusByDay = {for (final m in marks ?? []) m.day: m.status};
    });
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

  int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;
  int _firstWeekday(int y, int m) => DateTime(y, m, 1).weekday % 7;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(_year, _month);
    final firstWeekday = _firstWeekday(_year, _month);
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
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DarkPillDropdown<String>(
                      hint: _loadingCourses ? 'Loading...' : 'Select Course',
                      value: subId,
                      items: _courses.map((c) => c.subId).toList(),
                      labelOf: (id) {
                        final matches = _courses.where((c) => c.subId == id);
                        return matches.isEmpty ? id : matches.first.name;
                      },
                      onChanged: (v) => setState(() => subId = v),
                    ),
                    const SizedBox(height: 10),
                    DarkPillDropdown<int>(
                      hint: 'Select Month',
                      value: _month,
                      items: List.generate(12, (i) => i + 1),
                      labelOf: (m) => _monthNames[m - 1],
                      onChanged: (v) => setState(() => _month = v ?? _month),
                    ),
                    const SizedBox(height: 14),
                    Center(child: MaroonPillButton(label: _loading ? 'Loading...' : 'View', onPressed: _loading ? () {} : _view)),
                    if (_searched) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: Text('${_monthNames[_month - 1]} $_year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF7F7FB), borderRadius: BorderRadius.circular(16)),
                        child: AttendanceMonthGrid(
                          daysInMonth: daysInMonth,
                          firstWeekday: firstWeekday,
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
            const FooterUrl(),
          ],
        ),
      ),
    );
  }
}
