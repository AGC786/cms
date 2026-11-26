import 'dart:convert';

import 'api_client.dart';

/// A single salary slip summary row returned by
/// [EmpSalarySlipApi.fetchSalarySlips].
class SalarySlipRecord {
  final String salaryId;
  final String date;
  final String amount;
  final String status;
  const SalarySlipRecord({required this.salaryId, required this.date, required this.amount, required this.status});
}

/// A single Earnings/Deductions line item, e.g. `Basic Salary: 45000`.
class SalaryLineItem {
  final String item;
  final String amount;
  const SalaryLineItem({required this.item, required this.amount});
}

/// Full Earnings/Deductions breakdown for one salary slip, shown in the
/// "Salary Details" preview dialog.
class SalarySlipDetail {
  final List<SalaryLineItem> earnings;
  final List<SalaryLineItem> deductions;
  final String grossSalary;
  final String totalDeductions;
  final String netSalary;
  const SalarySlipDetail({
    required this.earnings,
    required this.deductions,
    required this.grossSalary,
    required this.totalDeductions,
    required this.netSalary,
  });
}

enum SalarySlipFetchStatus { ok, noSession, error }

class SalarySlipFetchResult {
  final SalarySlipFetchStatus status;
  final List<SalarySlipRecord> records;
  const SalarySlipFetchResult(this.status, this.records);
}

/// Fetches the Employee portal's Salary Slip history and per-slip detail
/// from the AIT SmartCampuses Staff Portal API.
///
/// Like the other Staff Portal endpoints, these are gated by a real,
/// server-side login session (`ci_session` cookie) — they only return
/// data once the user has logged in with genuine, valid staff
/// credentials through `AuthApi.loginWithSession`.
///
/// Response shapes below are taken directly from this app's own React
/// Native source (`EmployeeSalarySlip.js`):
/// - `salarySlipforApp` returns a bare JSON array of slip rows.
/// - `salary_slipforEmployee?salary_id=<id>` returns an object with
///   `my_emp_salary_item_all` (earnings line items), `my_emp_salary_item_ded`
///   (deduction line items), and `my_emp_salary` (a 1-row array whose
///   `total_payment` is the net salary) — not a single-key wrapper.
class EmpSalarySlipApi {
  EmpSalarySlipApi._();

  static final Uri _listUrl = Uri.parse('https://campus.smartcampuses.com/demo_institute/Staffportal/salarySlipforApp');

  static Future<SalarySlipFetchResult> fetchSalarySlips() async {
    try {
      final response = await ApiClient.instance.get(_listUrl, headers: const {'Content-Type': 'application/json'});

      if (response.statusCode != 200) return const SalarySlipFetchResult(SalarySlipFetchStatus.error, []);

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const SalarySlipFetchResult(SalarySlipFetchStatus.error, []);

      final records = decoded.whereType<Map>().map((raw) {
        final e = raw;
        return SalarySlipRecord(
          salaryId: e['salary_id']?.toString() ?? '',
          date: e['salary_date']?.toString() ?? '',
          amount: e['total_payment']?.toString() ?? '',
          // The RN source reads `item.status` (not `s_status`) for this
          // list — fall back to `s_status` only in case the backend is
          // inconsistent across responses.
          status: (e['status'] ?? e['s_status'])?.toString() ?? '',
        );
      }).toList();

      return SalarySlipFetchResult(SalarySlipFetchStatus.ok, records);
    } on ApiNoSessionException {
      return const SalarySlipFetchResult(SalarySlipFetchStatus.noSession, []);
    } on ApiSessionExpiredException {
      return const SalarySlipFetchResult(SalarySlipFetchStatus.noSession, []);
    } catch (_) {
      return const SalarySlipFetchResult(SalarySlipFetchStatus.error, []);
    }
  }

  static Future<SalarySlipDetail?> fetchSalarySlipDetail(String salaryId) async {
    try {
      final url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Staffportal/salary_slipforEmployee?salary_id=$salaryId');
      final response = await ApiClient.instance.get(url, headers: const {'Content-Type': 'application/json'});

      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      final earningsRaw = decoded['my_emp_salary_item_all'];
      final deductionsRaw = decoded['my_emp_salary_item_ded'];
      if (earningsRaw is! List || deductionsRaw is! List) return null;

      final earnings = earningsRaw.whereType<Map>().map((raw) {
        final m = raw;
        return SalaryLineItem(item: m['item']?.toString() ?? '', amount: m['amount']?.toString() ?? '0');
      }).toList();
      final deductions = deductionsRaw.whereType<Map>().map((raw) {
        final m = raw;
        return SalaryLineItem(item: m['item']?.toString() ?? '', amount: m['amount']?.toString() ?? '0');
      }).toList();

      final gross = earnings.fold<double>(0, (sum, e) => sum + (double.tryParse(e.amount) ?? 0));
      final totalDed = deductions.fold<double>(0, (sum, e) => sum + (double.tryParse(e.amount) ?? 0));

      final salaryRow = decoded['my_emp_salary'];
      final netFromRow = salaryRow is List && salaryRow.isNotEmpty
          ? double.tryParse((salaryRow.first as Map)['total_payment']?.toString() ?? '')
          : null;
      final net = netFromRow ?? (gross - totalDed);

      return SalarySlipDetail(
        earnings: earnings,
        deductions: deductions,
        grossSalary: gross.toStringAsFixed(0),
        totalDeductions: totalDed.toStringAsFixed(0),
        netSalary: net.toStringAsFixed(0),
      );
    } catch (_) {
      return null;
    }
  }
}
