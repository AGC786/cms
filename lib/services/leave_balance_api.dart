import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session_manager.dart';

enum LeaveBalanceFetchStatus { ok, noSession, error }

/// One leave type's quota vs. what's left, e.g. `CL: 15 total / 12 left`.
/// [total], [avail] and [remaining] are kept as the raw strings the
/// backend sends — matching the web portal's own columns.  Values can be
/// fractional (`"21.5"`); [avail] is empty when the backend sends null.
class LeaveTypeBalance {
  final String title;
  final String total;
  final String avail;
  final String remaining;
  const LeaveTypeBalance({required this.title, required this.total, required this.avail, required this.remaining});
}

class LeaveBalanceResult {
  final LeaveBalanceFetchStatus status;
  final String totalLeaves;
  final String remainingLeaves;
  final List<LeaveTypeBalance> balances;
  const LeaveBalanceResult(this.status, {this.totalLeaves = '', this.remainingLeaves = '', this.balances = const []});
}

/// Employee portal Leave Balance, from the shared public endpoint
/// `mobile_app/leave_balance?emp_id=<id>` (same one the Faculty portal
/// uses — see [FacLeaveBalanceApi]). The employee id comes from the
/// login session (`SessionManager.getStaffId()`), so no `ci_session`
/// cookie is needed.
///
/// Response shape (confirmed live):
/// `{"success": true, "data": {"emp_id": 109, "leaves": [
///   {"leave_title": "CL", "total": "15", "avail": 6, "remaining": "9"},
///   ...]}}` — all three columns (`total` / `avail` / `remaining`) are
/// surfaced as-is to match the web portal; `avail` can be null (shown
/// as "-") and, for some leave types (notably EL), the backend's own
/// figures don't reconcile — that's the source data, not a mapping bug.
class LeaveBalanceApi {
  LeaveBalanceApi._();

  static Future<LeaveBalanceResult> fetchLeaveBalance() =>
      fetchLeaveBalanceFor(() => SessionManager.instance.getStaffId());

  /// Shared implementation — [idOf] supplies the portal's employee id
  /// (staff id for Employee, faculty/emp id for Faculty).
  static Future<LeaveBalanceResult> fetchLeaveBalanceFor(Future<String?> Function() idOf) async {
    try {
      final empId = await idOf();
      if (empId == null || empId.isEmpty) {
        return const LeaveBalanceResult(LeaveBalanceFetchStatus.noSession);
      }

      final response = await http
          .get(
            Uri.parse('https://campus.smartcampuses.com/demo_institute/mobile_app/leave_balance?emp_id=$empId'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const LeaveBalanceResult(LeaveBalanceFetchStatus.error);

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] == false) {
        return const LeaveBalanceResult(LeaveBalanceFetchStatus.error);
      }
      final data = decoded['data'];
      final leaves = data is Map ? data['leaves'] : null;
      if (leaves is! List) return const LeaveBalanceResult(LeaveBalanceFetchStatus.error);

      num totalSum = 0, remainingSum = 0;
      final balances = leaves.whereType<Map>().map((raw) {
        final title = (raw['leave_title']?.toString() ?? '').trim();
        final total = raw['total']?.toString() ?? '0';
        final remaining = raw['remaining']?.toString() ?? '0';
        final availRaw = raw['avail'];
        final avail = (availRaw == null || availRaw.toString().toLowerCase() == 'null')
            ? ''
            : availRaw.toString();
        totalSum += num.tryParse(total) ?? 0;
        remainingSum += num.tryParse(remaining) ?? 0;
        return LeaveTypeBalance(title: title, total: total, avail: avail, remaining: remaining);
      }).toList();

      return LeaveBalanceResult(
        LeaveBalanceFetchStatus.ok,
        totalLeaves: _trimNum(totalSum),
        remainingLeaves: _trimNum(remainingSum),
        balances: balances,
      );
    } catch (_) {
      return const LeaveBalanceResult(LeaveBalanceFetchStatus.error);
    }
  }

  static String _trimNum(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}
