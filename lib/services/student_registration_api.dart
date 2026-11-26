import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

/// Registration funnel summary returned by
/// [StudentRegistrationApi.fetchSummary].
class RegistrationSummary {
  final int totalStudents;
  final int inquiry;
  final int interview;
  final int test;
  final int unattended;
  const RegistrationSummary({
    required this.totalStudents,
    required this.inquiry,
    required this.interview,
    required this.test,
    required this.unattended,
  });
}

/// Fetches the Admin portal's Student Registration summary from
/// `Mobile_app/summary_registration_dashboard`.
///
/// The endpoint now answers with a **bare** object
/// `{"total_students":n,"total_unattended":n,"total_interviews":n,
/// "total_tests":n,"total_inquiries":n, ...}` (it used to wrap it in
/// `{"success":true,"data":{...}}` — both shapes are still accepted).
///
/// With no param it returns the whole institute's totals; with
/// `?years=<academic-year>` it scopes to that year — confirmed live:
/// `years=2025-2026` → 1560 students, `years=2024-2025` → 29,
/// `years=2026-2027` → 17 (a year with no registrations comes back
/// all-zero rather than erroring).
class StudentRegistrationApi {
  StudentRegistrationApi._();

  static final Uri _url = Uri.parse('https://campus.smartcampuses.com/demo_institute/Mobile_app/summary_registration_dashboard');

  /// [years] — the selected academic year (e.g. `"2023-2024"`); sent as
  /// `?years=<value>`. Null/empty gives the overall (all-years) total.
  static Future<RegistrationSummary?> fetchSummary({String? years}) async {
    try {
      final uri = (years == null || years.isEmpty)
          ? _url
          : _url.replace(queryParameters: {'years': years});
      final response = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      // Bare object, or the older {success, data:{...}} wrapper.
      final rawRow = decoded['data'] is Map ? decoded['data'] as Map : decoded;
      final row = rawRow.map((k, v) => MapEntry(k.toString(), v));

      return RegistrationSummary(
        totalStudents: int.tryParse(row['total_students']?.toString() ?? '') ?? 0,
        inquiry: int.tryParse(row['total_inquiries']?.toString() ?? '') ?? 0,
        interview: int.tryParse(row['total_interviews']?.toString() ?? '') ?? 0,
        test: int.tryParse(row['total_tests']?.toString() ?? '') ?? 0,
        unattended: int.tryParse(row['total_unattended']?.toString() ?? '') ?? 0,
      );
    } catch (e) {
      developer.log('fetchSummary failed', name: 'StudentRegistrationApi', error: e);
      return null;
    }
  }
}
