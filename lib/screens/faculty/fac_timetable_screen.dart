import 'package:flutter/material.dart';
import '../../services/fac_timetable_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../utils/time_format.dart';
import '../../widgets/common.dart';

/// Faculty's weekly time table — pick a day to see that day's classes,
/// fetched from the AIT SmartCampuses API.
class FacTimetableScreen extends StatefulWidget {
  const FacTimetableScreen({super.key});

  @override
  State<FacTimetableScreen> createState() => _FacTimetableScreenState();
}

class _FacTimetableScreenState extends State<FacTimetableScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  String day = 'Monday';
  static const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  bool _loading = true;
  bool _unavailable = false;
  List<FacPeriod> _periods = [];

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps the selected day's timetable in step with the web portal
    // without a manual refresh (see AutoRefreshMixin) — uses the silent
    // variant so it doesn't flash the loading spinner over an already
    // visible timetable every poll.
    startAutoRefresh(_refreshLiveData);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _unavailable = false;
    });
    await _refreshLiveData();
  }

  Future<void> _refreshLiveData() async {
    final loaded = await FacTimetableApi.fetchTimetable(day);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (loaded == null) {
        _unavailable = true;
        _periods = [];
      } else {
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
            const PgHeader(title: 'Time Table', color: AppColors.blueMid),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DarkPillDropdown<String>(
                      hint: day,
                      value: day,
                      items: days,
                      labelOf: (d) => d,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => day = v);
                        _load();
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: AppColors.blueMid),
                      )
                    else if (_unavailable)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Unable to load the time table — this feature requires an active Faculty session, which isn\'t available yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    else if (_periods.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No classes scheduled for $day', style: const TextStyle(color: AppColors.muted)),
                      )
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
                              if (c.courseCode.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(c.courseCode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.muted, letterSpacing: 0.5)),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _field('Lecture Type:', c.type)),
                                  Expanded(child: _field('Batch:', c.batch)),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _field('Time:', formatTimeRange(c.time))),
                                  Expanded(child: _field('Room:', c.room)),
                                ],
                              ),
                              const Divider(height: 16),
                              _field('Semester:', c.semester),
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
