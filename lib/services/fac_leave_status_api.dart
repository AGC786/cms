import 'dart:convert';

import 'api_client.dart';

/// A single Faculty leave application history entry.
class FacLeaveEntry {
  final String title;
  final String leaveId;
  final String startDate;
  final String endDate;
  final String total;
  final String applyDate;
  final String reason;
  final String status;
  const FacLeaveEntry({
    required this.title,
    required this.leaveId,
    required this.startDate,
    required this.endDate,
    required this.total,
    required this.applyDate,
    required this.reason,
    required this.status,
  });
}

/// Fetches the Faculty portal's leave application history from the AIT
/// SmartCampuses API.
///
/// Like the Employee Staff Portal endpoints, this is gated by a real,
/// server-side login session (`ci_session` cookie, obtained via
/// `FacAuthApi.login`) — confirmed by probing it directly, which
/// returns a SQL error with a blank `emp_leave.emp_id=` clause.
class FacLeaveStatusApi {
  FacLeaveStatusApi._();

  /// Returns null when there's no session / the request fails / the
  /// server returned no usable data — callers should show a clear
  /// "unavailable" state in that case rather than a blank list.
  static Future<List<FacLeaveEntry>?> fetchLeaveStatus() async {
    try {
      final response = await ApiClient.instance.get(Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacherportal/load_leaves'));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;

      return decoded.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacLeaveEntry(
          // `load_leaves` joins `emp_leave` with the `leaves` catalog
          // table (`leaves.L_id`, `emp_leave.L_type` — confirmed live
          // from the endpoint's own session-gated SQL error) via a bare
          // `SELECT *` with no alias for the leave type's name, so
          // `leave_title` isn't confirmed to exist — widened with that
          // table's apparent `L_` naming convention as a fallback.
          title: _pick(m, ['leave_title', 'L_name', 'leave_name', 'title']),
          leaveId: _pick(m, ['leave_id', 'emp_leave_req_id', 'emp_leave_id']),
          startDate: _pick(m, ['start_date', 'from_date', 'leave_from']),
          endDate: _pick(m, ['end_date', 'to_date', 'leave_to']),
          total: _pick(m, ['total', 'total_days', 'no_of_days', 'days']),
          applyDate: _pick(m, ['created_at', 'apply_date', 'applied_on']),
          reason: m['reason']?.toString() ?? '',
          status: _mapStatus(m),
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  static final Uri _addUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacherportal/add_leave');

  /// Submits a new leave application. `Teacherportal/add_leave` is
  /// confirmed live to exist and be session-gated (probed directly: a
  /// non-existent route returns CodeIgniter's 404 page, this one instead
  /// returns the same blank-body/redirect-to-login signature every other
  /// session-gated Teacherportal endpoint gives without a valid session)
  /// — but its exact POST field names aren't independently confirmed, so
  /// this mirrors [fetchLeaveStatus]'s own response field names
  /// (`leave_title`/`start_date`/`end_date`/`reason`), which is this
  /// module's established naming for this exact data. [dates] are sent
  /// as `yyyy-MM-dd`, matching every other date-bearing POST endpoint in
  /// this app. Returns false (never throws) on any failure, including an
  /// unrecognised response shape — callers should tell the user the
  /// submission failed rather than assume success.
  static Future<bool> submitLeave({
    required String leaveTitle,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final response = await ApiClient.instance.postForm(_addUrl, fields: {
        'leave_title': leaveTitle,
        'start_date': _isoDate(startDate),
        'end_date': _isoDate(endDate),
        'reason': reason,
      });
      if (response.statusCode != 200) return false;
      final body = response.body.trim();
      if (body.isEmpty) return false;
      final decoded = jsonDecode(body);
      if (decoded is Map) return decoded['status'] == 1 || decoded['success'] == true;
      return decoded == 1 || decoded.toString() == '1';
    } catch (_) {
      return false;
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The old code read a single numeric `status` and mapped `1 →
  /// Approved`, everything else → `Denied` — so a still-pending request
  /// (`0`) showed up as "Denied". This prefers a ready-made word status
  /// (the sibling `Grid/leavegridstatus` endpoint exposes it as
  /// `Leavestatuss`), and only falls back to interpreting a numeric code,
  /// with `0`/blank treated as Pending rather than Denied.
  static String _mapStatus(Map<String, dynamic> data) {
    final word = _pick(data, ['Leavestatuss', 'leave_status', 'status_text', 'status_name']);
    if (word.isNotEmpty && int.tryParse(word) == null) return word;
    final code = (word.isNotEmpty ? word : data['status']?.toString() ?? '').trim();
    switch (code) {
      case '1':
        return 'Approved';
      case '2':
      case '3':
        return 'Denied';
      case '0':
      case '':
        return 'Pending';
      default:
        return code;
    }
  }

  static String _pick(Map<String, dynamic> data, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return fallback;
  }
}
