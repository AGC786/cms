import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'fac_salary_slip_api.dart';
import 'session_manager.dart';

/// Fetches the Faculty portal's own profile info.
///
/// Every call re-fetches live from `Teacherportal/salary_slipForTeacher`
/// (so profile changes on the backend show up on the next screen visit —
/// no logout/login required to see them), then fills in any field that
/// response is missing (confirmed live to lack a department name, for
/// instance) from the profile snapshot cached at login time (see
/// [SessionManager.cacheLoginProfile] — `Teacherportal/username2` is
/// confirmed live to return the faculty's full record: `dept_name`,
/// `designation`, `gender`, `father_name`, `mobile_no`,
/// `email_address`, `qualification`, `picture`, ...). If the live call
/// fails entirely (no session, network error, no salary slips yet),
/// the cached login snapshot is returned on its own rather than nothing.
class FacProfileApi {
  FacProfileApi._();

  /// Returns the raw profile fields (label → value) from a live salary
  /// slip lookup merged with the cached login snapshot, or null if
  /// neither source has anything — callers should fall back to a
  /// placeholder in that case.
  static Future<Map<String, String>?> fetchProfile() async {
    final live = await _fetchLive();

    final cached = await SessionManager.instance.getCachedLoginProfile();
    if (cached == null || cached.isEmpty) return live;

    final cachedStrings = cached.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
    if (live == null) return cachedStrings;
    return {...cachedStrings, ...live}; // live values win where both have the same key
  }

  static Future<Map<String, String>?> _fetchLive() async {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('emp_id');
    if (empId == null || empId.isEmpty) return null;

    final slips = await FacSalarySlipApi.fetchSalarySlips(employeeId: empId);
    if (slips.isEmpty) return null;

    try {
      final url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacherportal/salary_slipForTeacher?salary_id=${slips.first.salaryId}');
      final response = await http
          .get(url, headers: const {
            'Accept': 'application/json',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          })
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      final myData = decoded is Map ? decoded['mydata'] : null;
      final row = myData is List && myData.isNotEmpty ? myData.first : null;
      if (row is! Map) return null;

      final map = row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
      // Reported live: this endpoint's `name` column comes back as the
      // institute/branch name (e.g. "ALIGARH INSTITUTE OF TECHNOLOGY"),
      // not the faculty member's own name — presumably a duplicate-alias
      // collision in the underlying query's join. The login snapshot's
      // `name` (see [FacLoginResult.rawProfile]) is the one actually
      // confirmed to be the faculty's own name, so it's dropped here to
      // stop `fetchProfile`'s live-wins merge from clobbering it.
      map.remove('name');
      return map;
    } catch (_) {
      return null;
    }
  }

  static String pick(Map<String, String> data, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.trim().isNotEmpty && !_looksLikeInstituteName(v)) return v.trim();
    }
    return fallback;
  }

  /// Reported live: even after excluding the live salary-slip fetch's
  /// `name` column (a confirmed institute-name collision — see
  /// [_fetchLive]), the faculty's own "Name" field still showed the
  /// institute's name, meaning the cached login snapshot's `name` field
  /// carries the same pollution. Since there's no confirmed-clean source
  /// for it, [pick] instead skips any candidate value that looks like
  /// the institute's own name outright, so callers naturally fall
  /// through to the next candidate (or their fallback) instead of
  /// displaying it.
  static bool _looksLikeInstituteName(String value) {
    final v = value.toLowerCase();
    return v.contains('institute of technology') || v.contains('aligarh');
  }
}
