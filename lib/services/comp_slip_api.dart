import 'dart:convert';

import 'api_client.dart';

/// A single compensation slip record returned by
/// [CompSlipApi.fetchCompensationSlips].
class CompSlipRecord {
  final String username;
  final String empId;
  final String month;
  final String allowanceType;
  final String deptName;
  final String basicSalary;
  final String deductionAmount;
  final String totalPayment;
  final String status;
  const CompSlipRecord({
    required this.username,
    required this.empId,
    required this.month,
    required this.allowanceType,
    required this.deptName,
    required this.basicSalary,
    required this.deductionAmount,
    required this.totalPayment,
    required this.status,
  });
}

enum CompSlipFetchStatus { ok, noSession, error }

class CompSlipFetchResult {
  final CompSlipFetchStatus status;
  final List<CompSlipRecord> records;
  const CompSlipFetchResult(this.status, this.records);
}

/// Fetches the Employee portal's Compensation Slips from the AIT
/// SmartCampuses Staff Portal API. This endpoint is gated by a real,
/// server-side login session (`ci_session` cookie) — it ignores any
/// `emp_id`/`staff_id` passed as a request parameter and reads the
/// employee purely from that session, so it only returns data once the
/// user has logged in with genuine, valid staff credentials through
/// [AuthApi.loginWithSession] (which persists the cookie this call reads).
class CompSlipApi {
  CompSlipApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Staffportal/compensationSlips');

  static Future<CompSlipFetchResult> fetchCompensationSlips() async {
    try {
      final response = await ApiClient.instance.get(_url);

      if (response.statusCode != 200) {
        return const CompSlipFetchResult(CompSlipFetchStatus.error, []);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const CompSlipFetchResult(CompSlipFetchStatus.error, []);
      }

      final records = decoded.whereType<Map>().map((raw) {
        final e = raw;
        return CompSlipRecord(
          username: e['username']?.toString() ?? '',
          empId: e['emp_id']?.toString() ?? '',
          month: e['month1']?.toString() ?? '',
          allowanceType: e['supplementary_type']?.toString() ?? '',
          deptName: e['dept_name']?.toString() ?? '',
          basicSalary: e['basic_salary']?.toString() ?? '',
          deductionAmount: e['deduction_amount']?.toString() ?? '',
          totalPayment: e['total_payment']?.toString() ?? '',
          status: e['st']?.toString() ?? '',
        );
      }).toList();

      return CompSlipFetchResult(CompSlipFetchStatus.ok, records);
    } on ApiNoSessionException {
      return const CompSlipFetchResult(CompSlipFetchStatus.noSession, []);
    } on ApiSessionExpiredException {
      return const CompSlipFetchResult(CompSlipFetchStatus.noSession, []);
    } on ApiNetworkException {
      return const CompSlipFetchResult(CompSlipFetchStatus.error, []);
    } catch (_) {
      return const CompSlipFetchResult(CompSlipFetchStatus.error, []);
    }
  }
}
