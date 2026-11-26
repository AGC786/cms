import 'package:flutter/material.dart';
import '../../data/models.dart' show CalItem;
import '../../services/holiday_api.dart';
import '../../services/stu_calendar_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Admin's Events & Holidays — two tabs (Events, Holidays), matching the
/// tabbed layout used by the Student/Faculty/Employee portals'
/// Events & Holiday screen. Holidays come from the Admin-specific
/// `Mobile_app/holiday` endpoint ([HolidayApi]); Events reuse
/// [StuCalendarApi]'s institute-wide calendar (public, no session
/// required) since there's no dedicated Admin events endpoint.
class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  late final Future<StuCalendarData> _calendar;
  late final Future<List<CalItem>> _holidays;

  @override
  void initState() {
    super.initState();
    _calendar = StuCalendarApi.fetchCalendar();
    _holidays = HolidayApi.fetchHolidays();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const PgHeader(title: ' Holidays'),
              const TabBar(
                labelColor: AppColors.maroonBtn,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.maroonBtn,
                tabs: [Tab(text: 'Events'), Tab(text: 'Holidays')],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    CalendarEventList(future: _calendar.then((d) => d.events), emptyMessage: 'No events found.'),
                    CalendarEventList(future: _holidays, emptyMessage: 'No holidays found.'),
                  ],
                ),
              ),
              const FooterUrl(),
            ],
          ),
        ),
      ),
    );
  }
}
