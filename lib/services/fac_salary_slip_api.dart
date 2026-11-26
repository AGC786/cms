import 'dart:convert';

import 'package:http/http.dart' as http;

class FacSalarySlip {
  final String salaryId;
  final String date;
  final String amount;
  final String status;
  const FacSalarySlip({required this.salaryId, required this.date, required this.amount, required this.status});
}

class FacSalaryLineItem {
  final String item;
  final String amount;
  const FacSalaryLineItem({required this.item, required this.amount});
}

class FacSalaryDetail {
  final List<FacSalaryLineItem> earnings;
  final List<FacSalaryLineItem> deductions;
  final String grossSalary;
  final String totalDeductions;
  final String netSalary;
  const FacSalaryDetail({
    required this.earnings,
    required this.deductions,
    required this.grossSalary,
    required this.totalDeductions,
    required this.netSalary,
  });
}

/// Fetches the Faculty portal's Salary Slip history and per-slip detail
/// from the AIT SmartCampuses API. Both endpoints take plain request
/// parameters and were confirmed to work without any login session.
class FacSalarySlipApi {
  FacSalarySlipApi._();

  /// `employeeId` is required (no hardcoded fallback) — callers must
  /// pass the real logged-in faculty's id
  /// (`SessionManager.instance.getFacultyId()`), never a demo persona.
  static Future<List<FacSalarySlip>> fetchSalarySlips({required String employeeId, String branchId = '1'}) async {
    try {
      final url = Uri.parse('https://campus.smartcampuses.com/demo_institute/mobile_app/teacher_salaryslip?employee_id=$employeeId&branch_id=$branchId');
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      return decoded.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacSalarySlip(
          salaryId: m['salary_id']?.toString() ?? '',
          date: m['salary_date']?.toString() ?? '',
          amount: m['total_payment']?.toString() ?? '',
          status: m['status']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<FacSalaryDetail?> fetchDetail(String salaryId) async {
    try {
      final url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Teacherportal/salary_slipForTeacher?salary_id=$salaryId');
      final response = await http
          .get(url, headers: const {
            'Accept': 'application/json',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          })
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      final earningsRaw = decoded['my_emp_salary_item_all'];
      final deductionsRaw = decoded['my_emp_salary_item_ded'];
      if (earningsRaw is! List || deductionsRaw is! List) return null;

      final earnings = earningsRaw.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacSalaryLineItem(item: m['item']?.toString() ?? '', amount: m['amount']?.toString() ?? '0');
      }).toList();
      final deductions = deductionsRaw.whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        return FacSalaryLineItem(item: m['item']?.toString() ?? '', amount: m['amount']?.toString() ?? '0');
      }).toList();

      final gross = earnings.fold<double>(0, (sum, e) => sum + (double.tryParse(e.amount) ?? 0));
      final totalDed = deductions.fold<double>(0, (sum, e) => sum + (double.tryParse(e.amount) ?? 0));

      final salaryRow = decoded['my_emp_salary'];
      final firstSalaryRow = salaryRow is List && salaryRow.isNotEmpty && salaryRow.first is Map ? salaryRow.first as Map : null;
      final netFromRow = firstSalaryRow != null ? double.tryParse(firstSalaryRow['total_payment']?.toString() ?? '') : null;
      final net = netFromRow ?? (gross - totalDed);

      return FacSalaryDetail(
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
