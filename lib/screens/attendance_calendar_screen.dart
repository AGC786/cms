import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../theme.dart';

enum DayStatus { none, present, absent, leave }

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});
  @override
  State<AttendanceCalendarScreen> createState() => _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  DateTime _month = DateTime(2026, 7);
  final Map<int, DayStatus> _statuses = {};

  void _cycle(int day) {
    setState(() {
      final cur = _statuses[day] ?? DayStatus.none;
      final next = DayStatus.values[(cur.index + 1) % DayStatus.values.length];
      _statuses[day] = next;
    });
  }

  Color _colorFor(DayStatus s) {
    switch (s) {
      case DayStatus.present:
        return AppColors.green;
      case DayStatus.absent:
        return AppColors.red;
      case DayStatus.leave:
        return AppColors.gold;
      case DayStatus.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7; // 0=Sun
    final present = _statuses.values.where((s) => s == DayStatus.present).length;
    final absent = _statuses.values.where((s) => s == DayStatus.absent).length;
    final leave = _statuses.values.where((s) => s == DayStatus.leave).length;

    return Scaffold(
      appBar: gradientAppBar(context, 'Attendance Details'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                ),
                Text('${_monthName(_month.month)} ${_month.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blueMid)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                ),
              ],
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: daysInMonth + firstWeekday,
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox.shrink();
                final day = index - firstWeekday + 1;
                final status = _statuses[day] ?? DayStatus.none;
                return GestureDetector(
                  onTap: () => _cycle(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: _colorFor(status), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text('$day', style: TextStyle(color: status == DayStatus.none ? Colors.black87 : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            const Text('Tap a day to cycle Present → Absent → Leave', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
            Row(
              children: [
                StatBlock(label: 'Present', value: '$present', color: AppColors.green),
                StatBlock(label: 'Absent', value: '$absent', color: AppColors.red),
                StatBlock(label: 'Leave', value: '$leave', color: AppColors.gold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m - 1];
}
