import 'package:flutter/material.dart';
import '../../services/class_schedule_admin_api.dart';
import '../../utils/time_format.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class ClassScheduleScreen extends StatefulWidget {
  const ClassScheduleScreen({super.key});

  @override
  State<ClassScheduleScreen> createState() => _ClassScheduleScreenState();
}

class _ClassScheduleScreenState extends State<ClassScheduleScreen> {
  static const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  bool _loadingPrograms = true;
  List<IdName> _programs = [];
  String? programId;

  bool _loadingShifts = false;
  List<IdName> _shifts = [];
  String? shiftId;

  bool _loadingYears = false;
  List<YearOption> _years = [];
  String? classId;
  String? sectionId;

  String day = 'Monday';
  bool showError = false;
  bool searched = false;
  bool _loading = false;
  List<ClassPeriod> _periods = [];

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    final programs = await ClassScheduleAdminApi.fetchPrograms();
    if (!mounted) return;
    setState(() {
      _programs = programs;
      _loadingPrograms = false;
    });
  }

  Future<void> _selectProgram(String? id) async {
    setState(() {
      programId = id;
      shiftId = null;
      classId = sectionId = null;
      _shifts = [];
      _years = [];
      searched = false;
      _loadingShifts = id != null;
    });
    if (id == null) return;
    final shifts = await ClassScheduleAdminApi.fetchShifts(id);
    if (!mounted) return;
    setState(() {
      _shifts = shifts;
      _loadingShifts = false;
    });
  }

  Future<void> _selectShift(String? id) async {
    setState(() {
      shiftId = id;
      classId = sectionId = null;
      _years = [];
      searched = false;
      _loadingYears = id != null;
    });
    if (id == null) return;
    final years = await ClassScheduleAdminApi.fetchYears(id);
    if (!mounted) return;
    setState(() {
      _years = years;
      _loadingYears = false;
    });
  }

  void _selectYear(String? id) {
    final year = _years.where((y) => y.classId == id);
    setState(() {
      classId = id;
      sectionId = year.isNotEmpty ? year.first.sectionId : null;
      searched = false;
    });
  }

  Future<void> _view() async {
    if (programId == null || shiftId == null || classId == null || sectionId == null) {
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
    final periods = await ClassScheduleAdminApi.fetchTimetable(
      classId: classId!,
      classSectionId: sectionId!,
      batchId: shiftId!,
      dayOfWeek: day,
    );
    if (!mounted) return;
    setState(() {
      _periods = periods;
      searched = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Class Schedule'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DarkPillDropdown<String>(
                      hint: _loadingPrograms ? 'Loading...' : 'Select Program',
                      value: programId,
                      items: _programs.map((p) => p.id).toList(),
                      labelOf: (id) => _programs.firstWhere((p) => p.id == id, orElse: () => IdName(id, id)).name,
                      onChanged: _loadingPrograms ? null : _selectProgram,
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
                            value: classId,
                            items: _years.map((y) => y.classId).toList(),
                            labelOf: (id) => _years.firstWhere((y) => y.classId == id, orElse: () => YearOption(id, '', id)).name,
                            onChanged: shiftId == null || _loadingYears ? null : _selectYear,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DarkPillDropdown<String>(
                      hint: 'Day',
                      value: day,
                      items: days,
                      labelOf: (d) => d,
                      onChanged: (v) => setState(() => day = v ?? day),
                    ),
                    FieldError(message: 'Please select program, batch and year.', show: showError),
                    const SizedBox(height: 14),
                    Center(child: MaroonPillButton(label: _loading ? 'Loading...' : 'View', onPressed: _loading ? () {} : _view)),
                    const SizedBox(height: 14),
                    if (searched)
                      if (_periods.isEmpty)
                        Text('No classes scheduled on $day.', style: const TextStyle(color: AppColors.muted))
                      else
                        ..._periods.map((c) => _ClassCard(c: c)),
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

class _ClassCard extends StatelessWidget {
  final ClassPeriod c;
  const _ClassCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blueMid)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.blueMid)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field('Lecture Type:', c.type)),
              Expanded(child: _field('Teacher:', c.teacher)),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(child: _field('Time:', formatTimeRange(c.time))),
              Expanded(child: _field('Room:', c.room ?? '-')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
            Text(value, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
        ),
      );
}
