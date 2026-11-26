import 'package:flutter/material.dart';
import '../../services/stu_exam_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class StuExamScreen extends StatefulWidget {
  const StuExamScreen({super.key});

  @override
  State<StuExamScreen> createState() => _StuExamScreenState();
}

class _StuExamScreenState extends State<StuExamScreen> {
  bool _loadingBreakdowns = true;
  List<ExamBreakdown> _breakdowns = [];
  String? _selectedId;

  bool _loading = false;
  List<ExamScheduleRow>? _rows;

  @override
  void initState() {
    super.initState();
    _loadBreakdowns();
  }

  Future<void> _loadBreakdowns() async {
    final loaded = await StuExamApi.fetchBreakdowns();
    if (!mounted) return;
    setState(() {
      _breakdowns = loaded;
      _loadingBreakdowns = false;
    });
  }

  Future<void> _view() async {
    if (_selectedId == null) return;
    setState(() => _loading = true);
    final rows = await StuExamApi.fetchExamSchedule(_selectedId!);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Exam Schedule', color: AppColors.blueMid),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DarkPillDropdown<String>(
                      hint: _loadingBreakdowns ? 'Loading...' : 'Select Schedule',
                      value: _selectedId,
                      items: _breakdowns.map((b) => b.id).toList(),
                      labelOf: (id) {
                        final matches = _breakdowns.where((b) => b.id == id);
                        return matches.isEmpty ? id : matches.first.title;
                      },
                      onChanged: (v) => setState(() {
                        _selectedId = v;
                        _rows = null;
                      }),
                    ),
                    const SizedBox(height: 14),
                    if (!_loadingBreakdowns && _breakdowns.isEmpty)
                      const Text('No exam schedules are currently available.', style: TextStyle(color: AppColors.muted))
                    else ...[
                      Center(
                        child: MaroonPillButton(
                          label: _loading ? 'Loading...' : 'View',
                          onPressed: (_loading || _selectedId == null) ? () {} : _view,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_rows != null)
                        if (_rows!.isEmpty)
                          const Text('No exam schedule found for this selection.', style: TextStyle(color: AppColors.muted))
                        else
                          ..._rows!.map(
                            (e) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blueMid)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.blueMid)),
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _field('Date:', e.date)),
                                      Expanded(child: _field('Time:', e.time)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
