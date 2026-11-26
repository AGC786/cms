import 'dart:convert';

import 'api_client.dart';

/// Fetches the Student portal's own profile info from the AIT
/// SmartCampuses API.
///
/// Like the other `Studentportal/*` reads, this is gated by a real,
/// server-side login session (`ci_session` cookie, obtained via
/// `StuAuthApi.login`) — confirmed by probing it directly, which
/// returns a SQL error with a blank student-id clause. The response
/// body is also prefixed with a stray `<script>...</script>` redirect
/// snippet (the same pattern seen on other endpoints in this backend),
/// so the JSON has to be located manually before decoding.
class StuProfileApi {
  StuProfileApi._();

  /// Returns the raw profile fields (label → value) from
  /// `fetch_data[0]`, or null if there's no session / the request fails /
  /// the server returned no data — callers should fall back to a
  /// placeholder in that case rather than showing a blank profile.
  static Future<Map<String, String>?> fetchProfile() async {
    try {
      final url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/studentportal23');
      final response = await ApiClient.instance.get(url);

      if (response.statusCode != 200) return null;

      final body = response.body;
      final jsonStart = body.indexOf('{');
      if (jsonStart == -1) return null;
      final decoded = jsonDecode(body.substring(jsonStart));

      final fetchData = decoded is Map ? decoded['fetch_data'] : null;
      final row = fetchData is List && fetchData.isNotEmpty ? fetchData.first : null;
      if (row is! Map) return null;

      return row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
    } catch (_) {
      return null;
    }
  }

  /// Picks the first non-empty value among [keys] (this backend is
  /// inconsistent about exact column/alias names across endpoints).
  /// Skips any value that looks like the institute's own name — the
  /// Faculty portal's equivalent profile fetch was confirmed live to
  /// leak the institute name through a `name`-column join collision, so
  /// this guards `students`'s multi-table join against the same class of
  /// bug even though it isn't independently confirmed here.
  static String pick(Map<String, String> data, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.trim().isNotEmpty && !_looksLikeInstituteName(v)) return v.trim();
    }
    return fallback;
  }

  static bool _looksLikeInstituteName(String value) {
    final v = value.toLowerCase();
    return v.contains('institute of technology') || v.contains('aligarh');
  }
}
