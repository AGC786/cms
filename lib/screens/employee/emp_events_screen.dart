import 'package:flutter/material.dart';
import '../../services/stu_calendar_api.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

/// Employee-portal entry point for the shared Events & Holiday screen.
/// The Employee portal has no dedicated calendar endpoint of its own, so
/// this reuses the same public institute-wide calendar
/// (`Studentportal/studentcalender`) the Student portal shows, fetching
/// Events/Holidays/Academics in one call.
class EmpEventsScreen extends StatefulWidget {
  const EmpEventsScreen({super.key});

  @override
  State<EmpEventsScreen> createState() => _EmpEventsScreenState();
}

class _EmpEventsScreenState extends State<EmpEventsScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  late Future<StuCalendarData> _calendar;

  @override
  void initState() {
    super.initState();
    _calendar = StuCalendarApi.fetchCalendar();
    // Keeps events/holidays/academics in step with the web portal
    // without a manual refresh (see AutoRefreshMixin).
    startAutoRefresh(_reload);
  }

  Future<void> _reload() async {
    final fetched = StuCalendarApi.fetchCalendar();
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
