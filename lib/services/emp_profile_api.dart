import 'dart:convert';

import 'api_client.dart';
import 'session_manager.dart';

/// Fetches the Employee portal's own profile info from the AIT
/// SmartCampuses Staff Portal API.
///
/// Like the other Staff Portal endpoints, this is gated by a real,
/// server-side login session (`ci_session` cookie) — the `staff_id` in
/// the URL is ignored server-side, confirmed by probing it directly, so
/// this only returns data once the user has logged in with genuine,
/// valid staff credentials through `AuthApi.loginWithSession`.
///
/// The Faculty portal's equivalent login endpoint was confirmed live to
/// already return a full profile record beyond what its dedicated
/// profile endpoint reconstructs — [SessionManager.cacheLoginProfile]
/// caches that same shape for Employee too (unconfirmed live here, no
/// test credentials available), so it's checked first and merged under
/// `profileInfo`'s own fields as a gap-filler rather than a guess-based
/// full replacement.
class EmpProfileApi {
  EmpProfileApi._();

  /// Returns the raw profile fields (label → value) from
  /// `fetch_data[0]`, merged with any cached login-response fields it's
  /// missing, or null if neither source has anything — callers should
  /// fall back to a placeholder in that case rather than showing a
  /// blank profile.
  static Future<Map<String, String>?> fetchProfile({required String staffId}) async {
    Map<String, String>? live;
    try {
      final url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Staffportal/profileInfo/$staffId');
      final response = await ApiClient.instance.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final fetchData = decoded is Map ? decoded['fetch_data'] : null;
        final row = fetchData is List && fetchData.isNotEmpty ? fetchData.first : null;
        if (row is Map) {
          live = row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
        }
      }
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      // fall through to the cached login profile below
    }

    final cached = await SessionManager.instance.getCachedLoginProfile();
    if (cached == null || cached.isEmpty) return live;

    final cachedStrings = cached.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
    if (live == null) return cachedStrings;
    return {...cachedStrings, ...live}; // live values win where both have the same key
  }

  /// Picks the first non-empty value among [keys] (this backend is
  /// inconsistent about exact column/alias names across endpoints).
  /// Skips any value that looks like the institute's own name — the
  /// Faculty portal's equivalent profile fetch was confirmed live to
  /// leak the institute name through a `name`-column join collision, so
  /// this guards Employee's identical merge pattern against the same
  /// class of bug even though it isn't independently confirmed here.
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
