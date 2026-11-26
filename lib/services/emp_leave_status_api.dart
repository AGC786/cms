import 'dart:convert';

import 'api_client.dart';

/// A single leave application record returned by
/// [EmpLeaveStatusApi.fetchLeaveStatus].
class LeaveStatusRecord {
  final String leaveTitle;
  final String leaveId;
  final String startDate;
  final String endDate;
  final String total;
  final String createdAt;
  final String reason;
  final String status;
  const LeaveStatusRecord({
    required this.leaveTitle,
    required this.leaveId,
    required this.startDate,
    required this.endDate,
    required this.total,
    required this.createdAt,
    required this.reason,
    required this.status,
  });
}

enum LeaveStatusFetchStatus { ok, noSession, error }

class LeaveStatusFetchResult {
  final LeaveStatusFetchStatus status;
  final List<LeaveStatusRecord> records;
  const LeaveStatusFetchResult(this.status, this.records);
}

/// Fetches the Employee portal's leave application history from the AIT
/// SmartCampuses Staff Portal API.
///
/// Like [CompSlipApi] and [LeaveBalanceApi], this endpoint is gated by a
/// real, server-side login session (`ci_session` cookie) — it only
/// returns data once the user has logged in with genuine, valid staff
/// credentials through [AuthApi.loginWithSession].
class EmpLeaveStatusApi {
  EmpLeaveStatusApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Staffportal/load_leaves');

  static Future<LeaveStatusFetchResult> fetchLeaveStatus() async {
    try {
      final response = await ApiClient.instance.get(_url);

      if (response.statusCode != 200) {
        return const LeaveStatusFetchResult(LeaveStatusFetchStatus.error, []);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const LeaveStatusFetchResult(LeaveStatusFetchStatus.error, []);
      }

      final records = decoded.whereType<Map>().map((raw) {
        final e = raw;
        return LeaveStatusRecord(
          // `load_leaves` joins `emp_leave` with the `leaves` catalog
          // table (`leaves.L_id`, `emp_leave.L_type` — confirmed live
          // from the endpoint's own session-gated SQL error) via a bare
          // `SELECT *` with no alias for the leave type's name, so
          // `leave_title` isn't confirmed to exist — widened with that
          // table's apparent `L_` naming convention as a fallback.
          leaveTitle: _pick(e, ['leave_title', 'L_name', 'leave_name', 'title'], fallback: 'N/A'),
          leaveId: _pick(e, ['leave_id', 'emp_leave_req_id', 'emp_leave_id'], fallback: 'N/A'),
          startDate: _pick(e, ['start_date', 'from_date', 'leave_from'], fallback: 'Not Available'),
          endDate: _pick(e, ['end_date', 'to_date', 'leave_to'], fallback: 'Not Available'),
          total: _pick(e, ['total', 'total_days', 'no_of_days', 'days'], fallback: 'N/A'),
          createdAt: _pick(e, ['created_at', 'apply_date', 'applied_on'], fallback: 'N/A'),
          reason: (e['reason']?.toString() ?? '').trim().isEmpty ? 'N/A' : e['reason'].toString().trim(),
          status: _mapStatus(e),
        );
      }).toList();

      return LeaveStatusFetchResult(LeaveStatusFetchStatus.ok, records);
    } on ApiNoSessionException {
      return const LeaveStatusFetchResult(LeaveStatusFetchStatus.noSession, []);
    } on ApiSessionExpiredException {
      return const LeaveStatusFetchResult(LeaveStatusFetchStatus.noSession, []);
    } catch (_) {
      return const LeaveStatusFetchResult(LeaveStatusFetchStatus.error, []);
    }
  }

  static final Uri _addUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Staffportal/add_leave');

  /// Submits a new leave application. `Staffportal/add_leave` is
  /// confirmed live to exist and be session-gated (probed directly: a
  /// non-existent route returns CodeIgniter's 404 page, this one instead
  /// returns the same blank-body/redirect-to-login signature every other
  /// session-gated Staffportal endpoint gives without a valid session) —
  /// but its exact POST field names aren't independently confirmed, so
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
    } on ApiNoSessionException {
      return false;
    } on ApiSessionExpiredException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Prefer a ready-made word status (the sibling `Grid/leavegridstatus`
  /// endpoint exposes it as `Leavestatuss`); only fall back to a numeric
  /// code, with `0`/blank treated as Pending rather than the previous
  /// pass-through that showed a raw `1`/`0` in the UI.
  static String _mapStatus(Map data) {
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

  static String _pick(Map data, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return fallback;
  }
}
