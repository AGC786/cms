import 'dart:convert';

import 'api_client.dart';

/// A single notice board entry.
class StuNotice {
  final String date;
  final String title;
  final String body;
  const StuNotice({required this.date, required this.title, required this.body});
}

/// Fetches the Student portal's Notice Board from the AIT SmartCampuses API.
class StuNoticeApi {
  StuNoticeApi._();

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Returns null on a request/parse failure (including the backend's
  /// known session-gated error path).
  static Future<List<StuNotice>?> fetchNotices() async {
    try {
      final response = await ApiClient.instance.get(Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/noticeboardapi'));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['note'] is! List) return null;

      return (decoded['note'] as List).whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return StuNotice(
          date: _formatDate(m['noticedate']?.toString()),
          title: m['notice_title']?.toString() ?? '',
          body: m['notice']?.toString() ?? '',
        );
      }).toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
