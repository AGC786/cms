import 'dart:convert';

import 'package:http/http.dart' as http;

/// A simple id/name pair used for the Program and Shift dropdowns.
class IdName {
  final String id;
  final String name;
  const IdName(this.id, this.name);
}

/// A Year/Section option — [classId] and [sectionId] are both required by
/// the timetable endpoint.
class YearOption {
  final String classId;
  final String sectionId;
  final String name;
  const YearOption(this.classId, this.sectionId, this.name);
}

/// A single scheduled period returned by
/// [ClassScheduleAdminApi.fetchTimetable].
class ClassPeriod {
  final String subject;
  final String teacher;
  final String time;
  final String type;
  final String? room;
  const ClassPeriod({required this.subject, required this.teacher, required this.time, required this.type, this.room});
}

/// Fetches the Admin portal's Class Schedule cascading filters (Program →
/// Shift → Year) and the day's timetable from the AIT SmartCampuses API.
class ClassScheduleAdminApi {
  ClassScheduleAdminApi._();

  static const _base = 'https://campus.smartcampuses.com/demo_institute/mobile_app';

  static Future<List<dynamic>?> _getList(Uri url) async {
    try {
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = response.body.trim();
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<IdName>> fetchPrograms({String branchId = '1'}) async {
    final list = await _getList(Uri.parse('$_base/system_type?branch_id=$branchId'));
    if (list == null) return [];
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return IdName(m['session_id'].toString(), (m['s_name']?.toString() ?? '').trim());
    }).toList();
  }

  static Future<List<IdName>> fetchShifts(String programId) async {
    final list = await _getList(Uri.parse('$_base/load_session?system_type_id=$programId'));
    if (list == null) return [];
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return IdName(m['batch_id'].toString(), (m['batch_title']?.toString() ?? '').trim());
    }).toList();
  }

  static Future<List<YearOption>> fetchYears(String shiftId, {String branchId = '1'}) async {
    final list = await _getList(Uri.parse('$_base/get_class?branch_id=$branchId&system_type_id=$shiftId'));
    if (list == null) return [];
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return YearOption(
        m['class_id'].toString(),
        m['class_section_id'].toString(),
        (m['cs_name']?.toString() ?? '').trim(),
      );
    }).toList();
  }

  static Future<List<ClassPeriod>> fetchTimetable({
    required String classId,
    required String classSectionId,
    required String batchId,
    required String dayOfWeek,
  }) async {
    final list = await _getList(Uri.parse(
      '$_base/admin_timetable?class_id=$classId&class_section_id=$classSectionId&batch_id=$batchId&day_of_week=$dayOfWeek',
    ));
    if (list == null) return [];

    return list
        .map((raw) => raw as Map<String, dynamic>)
        .where((m) => m['subject'] != 'N/A' && m['teacher'] != 'N/A' && m['time1'] != 'N/A' && m['type'] != 'N/A')
        .map((m) => ClassPeriod(
              subject: (m['subject']?.toString() ?? '').trim(),
              teacher: (m['teacher']?.toString() ?? '').trim(),
              time: m['time1']?.toString() ?? '',
              type: m['type']?.toString() ?? '',
              room: m['room']?.toString(),
            ))
        .toList();
  }
}
