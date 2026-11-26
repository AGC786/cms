import 'package:flutter/material.dart';
import '../../services/stu_calendar_api.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

/// Student-portal Event & Holiday calendar, fetching Events/Holidays/
/// Academics in one call from the live AIT SmartCampuses API via the
/// shared [EventsHolidayScreen].
class StuEventsScreen extends StatefulWidget {
  const StuEventsScreen({super.key});

  @override
  State<StuEventsScreen> createState() => _StuEventsScreenState();
}

class _StuEventsScreenState extends State<StuEventsScreen> with WidgetsBindingObserver, AutoRefreshMixin {
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
    return EventsHolidayScreen(
      eventsFuture: _calendar.then((d) => d.events),
      holidaysFuture: _calendar.then((d) => d.holidays),
      academicsFuture: _calendar.then((d) => d.academics),
    );
  }
}
