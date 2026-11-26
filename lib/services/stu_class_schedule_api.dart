import 'dart:convert';

import 'api_client.dart';

/// A single period in the Student portal's weekly class schedule.
class StuPeriod {
  final String course;
  final String lectureType;
  final String teacher;
  final String time;
  final String room;
  const StuPeriod({required this.course, required this.lectureType, required this.teacher, required this.time, required this.room});
}

/// Fetches the Student portal's class schedule (by weekday) from the
/// AIT SmartCampuses API.
class StuClassScheduleApi {
  StuClassScheduleApi._();

  /// Returns null only on a genuine request/parse failure. A blank 200
  /// body is *not* treated as a failure — confirmed live against two
  /// real, currently-logged-in student sessions: one with a real
  /// timetable got real rows back, the other (equally valid session,
  /// confirmed via a working profile fetch) got a blank body simply
  /// because no timetable has been entered for their class yet. Reading
  /// that as "session unavailable" was actively misleading — it's an
  /// empty result, so an empty list is returned instead.
  static Future<List<StuPeriod>?> fetchSchedule(String day) async {
    try {
      final response = await ApiClient.instance.postForm(
        Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/load_timetable'),
        fields: {'day': day},
      );
      if (response.statusCode != 200) return null;
      if (response.body.trim().isEmpty) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;

      return decoded
          .whereType<Map>()
          .map((raw) {
            final m = raw.map((k, v) => MapEntry(k.toString(), v));
            final type = m['type']?.toString();
            final subject = m['subject']?.toString();
            final teacher = m['teacher']?.toString();
            final time1 = m['time1']?.toString();
            final roomNo = m['room_no']?.toString();
            bool isBlank(String? v) => v == null || v.isEmpty || v == 'N/A';
            // Only real classes: a period with no course name is an empty
            // slot — skip it so the screen doesn't render a card full of
            // "-" placeholders.
            if (isBlank(subject)) return null;
            return StuPeriod(
              course: isBlank(subject) ? '-' : subject!,
              lectureType: isBlank(type) ? '-' : type!,
              teacher: isBlank(teacher) ? '-' : teacher!,
              time: isBlank(time1) ? '-' : time1!,
              room: isBlank(roomNo) ? '-' : roomNo!,
            );
          })
          .whereType<StuPeriod>()
          .toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
