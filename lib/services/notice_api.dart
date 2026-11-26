import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches portal Notice Boards from the AIT SmartCampuses API.
class NoticeApi {
  NoticeApi._();

  static Uri _adminUrl(int branchId) =>
      Uri.parse('https://campus.smartcampuses.com/demo_institute/mobile_app/admin_notice?branch_id=$branchId');

  static final Uri _employeeUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Staffportal/noticeBoardForApp');

  /// Returns notices as `{'date', 'title', 'body'}` maps — the shape
  /// [NoticeBoardScreen] already expects — or an empty list on any
  /// network/parsing failure.
  static Future<List<Map<String, String>>> fetchAdminNotices({int branchId = 1}) async {
    final body = await _get(_adminUrl(branchId));
    if (body == null) return [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return [];
    return _parseList(decoded);
  }

  /// Same shape as [fetchAdminNotices], but from the staff-portal endpoint
  /// used by the Employee portal. The response body is prefixed with a
  /// stray `<script>...</script>` redirect snippet before the JSON, and
  /// the notices are wrapped in a `{"note": [...]}` object rather than a
  /// bare array, so this is parsed separately.
  static Future<List<Map<String, String>>> fetchEmployeeNotices() async {
    final body = await _get(_employeeUrl);
    if (body == null) return [];
    final jsonStart = body.indexOf(RegExp(r'[\{\[]'));
    if (jsonStart == -1) return [];
    final decoded = jsonDecode(body.substring(jsonStart));
    if (decoded is! Map || decoded['note'] is! List) return [];
    return _parseList(decoded['note'] as List);
  }

  static Future<String?> _get(Uri url) async {
    try {
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      return response.statusCode == 200 ? response.body : null;
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, String>> _parseList(List<dynamic> raw) {
    return raw.whereType<Map>().map((item) {
      final n = item;
      return {
        'date': _formatDate(n['noticedate']?.toString() ?? ''),
        'title': _clean(n['notice_title']?.toString() ?? ''),
        'body': _clean(n['notice']?.toString() ?? ''),
      };
    }).toList();
  }

  /// API sends dates as `yyyy-MM-dd`; the UI displays `dd/MM/yyyy`.
  static String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length != 3) return raw;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  static String _clean(String raw) => raw
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}
