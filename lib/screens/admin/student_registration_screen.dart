import 'package:flutter/material.dart';
import '../../services/student_registration_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  bool _loading = true;
  RegistrationSummary? _summary;

  /// "Total Students" (all years combined) + academic sessions
  /// "2022-2023" … "<current>-<current+1>", newest first. The selected
  /// value is sent to the API as `?session=<value>`; [_allYears] sends
  /// no param and returns the overall total.
  static const _allYears = 'Total Students';
  static final List<String> _sessions = [
    _allYears,
    for (var y = DateTime.now().year; y >= 2022; y--) '$y-${y + 1}',
  ];
  String _session = _allYears;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await StudentRegistrationApi.fetchSummary(
      years: _session == _allYears ? null : _session,
    );
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = _summary;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Student Registration'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      DarkPillDropdown<String>(
                        hint: 'Select Session',
                        value: _session,
                        items: _sessions,
                        labelOf: (s) => s,
                        onChanged: (v) {
                          if (v == null || v == _session) return;
                          setState(() => _session = v);
                          _load();
                        },
                      ),
                      const SizedBox(height: 16),
                      _loading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : d == null
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Text(
                                    'Unable to load registration data. Pull down to retry.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                                  ),
                                )
                              : Column(
                                  children: [
                                    const Text(
                                      'Registration Summary',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                                    ),
                                    const SizedBox(height: 16),
                                StatBlockLarge(label: 'Total Students', value: '${d.totalStudents}', color: AppColors.green),
                                const SizedBox(height: 10),
                                StatBlockLarge(label: 'Total Inquiries', value: '${d.inquiry}', color: AppColors.red),
                                const SizedBox(height: 10),
                                StatBlockLarge(label: 'Total Unattended', value: '${d.unattended}', color: AppColors.orange),
                                const SizedBox(height: 10),
                                StatBlockLarge(label: 'Total Interviews', value: '${d.interview}', color: AppColors.blueMid),
                                const SizedBox(height: 10),
                                    StatBlockLarge(label: 'Total Tests', value: '${d.test}', color: AppColors.maroonBtn),
                                  ],
                                ),
                    ],
                  ),
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
