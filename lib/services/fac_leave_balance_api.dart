import 'session_manager.dart';
import 'leave_balance_api.dart';

enum FacLeaveBalanceFetchStatus { ok, noSession, error }

/// One leave type's quota vs. what's left, e.g. `CL: 15 total / 12 left`.
/// [total] / [remaining] are the raw backend strings (`remaining` can be
/// fractional).
class FacLeaveTypeBalance {
  final String title;
  final String total;
  final String avail;
  final String remaining;
  const FacLeaveTypeBalance({required this.title, required this.total, required this.avail, required this.remaining});
}

class FacLeaveBalanceResult {
  final FacLeaveBalanceFetchStatus status;
  final List<FacLeaveTypeBalance> balances;
  const FacLeaveBalanceResult(this.status, {this.balances = const []});
}

/// Faculty portal Leave Balance — same shared public endpoint as the
/// Employee portal (`mobile_app/leave_balance?emp_id=<id>`, see
/// [LeaveBalanceApi]); the id here is the logged-in faculty member's
/// `SessionManager.getFacultyId()` (their emp id).
class FacLeaveBalanceApi {
  FacLeaveBalanceApi._();

  static Future<FacLeaveBalanceResult> fetchLeaveBalance() async {
    final result = await LeaveBalanceApi.fetchLeaveBalanceFor(
      () => SessionManager.instance.getFacultyId(),
    );
    return FacLeaveBalanceResult(
      switch (result.status) {
        LeaveBalanceFetchStatus.ok => FacLeaveBalanceFetchStatus.ok,
        LeaveBalanceFetchStatus.noSession => FacLeaveBalanceFetchStatus.noSession,
        LeaveBalanceFetchStatus.error => FacLeaveBalanceFetchStatus.error,
      },
      balances: result.balances
          .map((b) => FacLeaveTypeBalance(title: b.title, total: b.total, avail: b.avail, remaining: b.remaining))
          .toList(),
    );
  }
}
