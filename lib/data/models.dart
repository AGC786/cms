/// A single calendar entry (Event/Holiday/Academic) — a date or date
/// range plus its title — used by the shared Events/Holidays/Academics
/// screen across the Faculty/Employee/Student portals.
class CalItem {
  final String dates;
  final String title;
  const CalItem(this.dates, this.title);
}

class Person {
  final String name;
  final String sub;
  final String code;
  const Person({required this.name, required this.sub, required this.code});
}

class ClassSession {
  final String name;
  final String teacher;
  final String time;
  const ClassSession({required this.name, required this.teacher, required this.time});
}

class LeaveRecord {
  final String name;
  final String code;
  final String type;
  final String status; // Approved | Pending | Rejected
  final int days;
  const LeaveRecord({
    required this.name,
    required this.code,
    required this.type,
    required this.status,
    required this.days,
  });
}

class CourseProgress {
  final String name;
  final String teacher;
  final int progress;
  const CourseProgress({required this.name, required this.teacher, required this.progress});
}

class ExamEntry {
  final String course;
  final String date;
  final String time;
  const ExamEntry({required this.course, required this.date, required this.time});
}

class CalendarEntry {
  final String date;
  final String event;
  const CalendarEntry({required this.date, required this.event});
}

class PortalMeta {
  final String name;
  final String icon;
  final String demoUser;
  final String demoPass;
  const PortalMeta({
    required this.name,
    required this.icon,
    required this.demoUser,
    required this.demoPass,
  });
}

enum AttendanceStatus { none, present, absent, leave }

extension AttendanceStatusX on AttendanceStatus {
  AttendanceStatus get next {
    switch (this) {
      case AttendanceStatus.none:
        return AttendanceStatus.present;
      case AttendanceStatus.present:
        return AttendanceStatus.absent;
      case AttendanceStatus.absent:
        return AttendanceStatus.leave;
      case AttendanceStatus.leave:
        return AttendanceStatus.none;
    }
  }
}
