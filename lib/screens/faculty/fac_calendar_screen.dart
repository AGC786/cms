import 'package:flutter/material.dart';
import '../../services/fac_calendar_api.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

/// Faculty's Event & Holiday calendar, fetching Events/Holidays/Academics
/// in one call from the live AIT SmartCampuses API
/// (`Teacherportal/calenderforTeacher` — public, no login session
/// required) via the shared [EventsHolidayScreen].
class FacCalendarScreen extends StatefulWidget {
  const FacCalendarScreen({super.key});

  @override
  State<FacCalendarScreen> createState() => _FacCalendarScreenState();
}

class _FacCalendarScreenState extends State<FacCalendarScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  late Future<FacCalendarData> _calendar;

  @override
  void initState() {
    super.initState();
    _calendar = FacCalendarApi.fetchCalendar();
    // Keeps events/holidays/academics in step with the web portal
    // without a manual refresh (see AutoRefreshMixin).
    startAutoRefresh(_reload);
  }

  Future<void> _reload() async {
    final fetched = FacCalendarApi.fetchCalendar();
    await fetched;
    if (!mounted) return;
    setState(() => _calendar = fetched);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetched once and shared across all three sections via `.then` so
    // each `FutureBuilder` resolves independently without triggering
    // three separate network calls.
    return EventsHolidayScreen(
      eventsFuture: _calendar.then((d) => d.events),
      holidaysFuture: _calendar.then((d) => d.holidays),
      academicsFuture: _calendar.then((d) => d.academics),
    );
  }
}
