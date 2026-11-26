import 'dart:convert';

import 'api_client.dart';

/// A single Faculty notice board entry.
class FacNotice {
  final String date;
  final String title;
  final String body;
  const FacNotice({required this.date, required this.title, required this.body});
}

/// Fetches the Faculty portal's Notice Board from the AIT SmartCampuses
/// API. Gated by a real, server-side login session (`ci_session` cookie,
/// obtained via `FacAuthApi.login`).
class FacNoticeApi {
  FacNoticeApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacherportal/noticeboardforTeacher');

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Returns null on a missing session / request / parse failure —
  /// callers should show a clear "unavailable" state in that case.
  static Future<List<FacNotice>?> fetchNotices() async {
    try {
      final response = await ApiClient.instance.get(_url);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      final list = decoded is Map ? decoded['note'] : (decoded is List ? decoded : null);
      if (list is! List) return null;

      return list.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacNotice(
          date: _formatDate(m['noticedate']?.toString()),
          title: m['notice_title']?.toString() ?? '',
          body: m['notice']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }
}
