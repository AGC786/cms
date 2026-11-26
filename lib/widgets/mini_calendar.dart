import 'package:flutter/material.dart';
import '../data/mock_db.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// Reproduces the "renderMiniCal / cycleDay / shiftMonth" behavior:
/// a month grid where tapping a day cycles Present -> Absent -> Leave -> none.
class MiniCalendar extends StatefulWidget {
  final int initialYear;
  final int initialMonth; // 0-based like JS Date
  const MiniCalendar({super.key, this.initialYear = 2026, this.initialMonth = 6});

  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late int year;
  late int month;
  final Map<String, AttendanceStatus> statuses = {};

  @override
  void initState() {
    super.initState();
    year = widget.initialYear;
    month = widget.initialMonth;
  }

  int _daysInMonth(int y, int m) => DateTime(y, m + 2, 0).day;
  int _firstWeekday(int y, int m) => DateTime(y, m + 1, 1).weekday % 7; // 0=Sun

  void _shift(int delta) {
    setState(() {
      month += delta;
      if (month < 0) {
        month = 11;
        year--;
      } else if (month > 11) {
        month = 0;
        year++;
      }
    });
  }

  void _cycleDay(int day) {
    final key = '$year-$month-$day';
    setState(() {
      statuses[key] = (statuses[key] ?? AttendanceStatus.none).next;
    });
  }

  Color _dayColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return AppColors.green;
      case AttendanceStatus.absent:
        return AppColors.red;
      case AttendanceStatus.leave:
        return AppColors.gold;
      case AttendanceStatus.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _daysInMonth(year, month);
    final start = _firstWeekday(year, month);
    int present = 0, absent = 0, leave = 0;
    for (final s in statuses.values) {
      if (s == AttendanceStatus.present) present++;
      if (s == AttendanceStatus.absent) absent++;
      if (s == AttendanceStatus.leave) leave++;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shift(-1)),
            Text(
              MockDb.monthNames[month],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shift(1)),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: year,
                items: [
                  for (int y = DateTime.now().year - 5; y <= DateTime.now().year; y++)
                    DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => year = v);
                },
              ),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final d in ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
              Center(
                child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
              ),
            for (int i = 0; i < start; i++) const SizedBox.shrink(),
            for (int d = 1; d <= total; d++)
              GestureDetector(
                onTap: () => _cycleDay(d),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _dayColor(statuses['$year-$month-$d'] ?? AttendanceStatus.none),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$d',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (statuses['$year-$month-$d'] ?? AttendanceStatus.none) == AttendanceStatus.none
                          ? AppColors.ink
                          : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Tap a day to cycle Present → Absent → Leave',
            style: TextStyle(fontSize: 10.5, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
        Row(
          children: [
            Expanded(child: StatBlock(label: 'Present', value: '$present', color: AppColors.green)),
            const SizedBox(width: 8),
            Expanded(child: StatBlock(label: 'Absent', value: '$absent', color: AppColors.red)),
            const SizedBox(width: 8),
            Expanded(child: StatBlock(label: 'Leave', value: '$leave', color: AppColors.gold)),
          ],
        ),
      ],
    );
  }
}
