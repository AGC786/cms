import 'package:flutter/material.dart';
import '../../services/stu_class_schedule_api.dart';
import '../../utils/time_format.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common.dart';

class StuClassScheduleScreen extends StatefulWidget {
  const StuClassScheduleScreen({super.key});

  @override
  State<StuClassScheduleScreen> createState() => _StuClassScheduleScreenState();
}

class _StuClassScheduleScreenState extends State<StuClassScheduleScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  String day = 'Monday';
  static const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  bool _loading = true;
  bool _unavailable = false;
  List<StuPeriod> _periods = [];

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps the selected day's timetable in step with the web portal
    // without a manual refresh (see AutoRefreshMixin) — uses the silent
    // variant so it doesn't flash the loading spinner over an already
    // visible schedule every poll.
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
    final loaded = await StuClassScheduleApi.fetchSchedule(day);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (loaded == null) {
        _unavailable = true;
        _periods = [];
      } else {
        _unavailable = false;
        _periods = loaded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Class Schedule', color: AppColors.blueMid),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DarkPillDropdown<String>(
                      hint: 'Day',
                      value: day,
                      items: days,
                      labelOf: (d) => d,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => day = v);
                        _load();
                      },
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(color: AppColors.blueMid),
                      )
                    else if (_unavailable)
                      const Text(
                        'Unable to load the class schedule — this feature requires an active Student session.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      )
                    else if (_periods.isEmpty)
                      Text('No classes scheduled on $day.', style: const TextStyle(color: AppColors.muted))
                    else
                      ..._periods.map(
                        (c) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blueMid)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.course, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.blueMid)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _field('Lecture Type:', c.lectureType)),
                                  Expanded(child: _field('Teacher:', c.teacher)),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _field('Time:', formatTimeRange(c.time))),
                                  Expanded(child: _field('Room:', c.room)),
                                ],
                              ),
                            ],
                          ),
                        ),
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
