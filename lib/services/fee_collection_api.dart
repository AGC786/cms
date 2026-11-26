import 'dart:convert';

import 'package:http/http.dart' as http;

/// A simple id/name pair used for every cascading dropdown level below.
class IdName {
  final String id;
  final String name;
  const IdName(this.id, this.name);
}

/// A Year/Section option for the Fee Collection "Year" dropdown.
///
/// The backend's `get_class` endpoint returns one row **per section**
/// (e.g. "1ST YEAR : A", "1ST YEAR : B", ...), and every section of the
/// same year shares one [classId] while [sectionId] (`class_section_id`)
/// is unique. The old code keyed the dropdown on [classId], so the four
/// sections of a year collapsed into a single visible entry — this keeps
/// them distinct, matching the web portal.
class FeeYear {
  final String classId;
  final String sectionId;
  final String name;
  const FeeYear(this.classId, this.sectionId, this.name);
}

/// Fee/attendance totals returned by [FeeCollectionApi.fetchFeeCollection].
class FeeCollectionResult {
  final int totalStudents;
  final int feePaid;
  final int amount;
  const FeeCollectionResult({required this.totalStudents, required this.feePaid, required this.amount});

  /// `admin_fee_collection` derives `totalStudents` from a
  /// `students.batch_id = <batch>` sub-select (confirmed via a leaked SQL
  /// error) that comes back `0` whenever the enrolment rows sit under a
  /// different batch id than the cascade passes — common for older
  /// batches. A `0` here therefore means "head-count unresolved", not an
  /// empty class.
  bool get hasTotalStudents => totalStudents > 0;

  /// Enrolled minus paid — only meaningful when the backend returned a
  /// usable head-count. `null` (shown as "—") otherwise, instead of a
  /// misleading `0`.
  int? get defaulter {
    if (!hasTotalStudents || totalStudents < feePaid) return null;
    return totalStudents - feePaid;
  }
}

/// Institute-wide defaulter figures from `mobile_app/summary_fee_defaulter`
/// — outstanding [balance] (rupees) and how many students [studentCount]
/// owe it. Both come straight off the endpoint's single `data` row.
class FeeDefaulterSummary {
  final int balance;
  final int? studentCount;
  const FeeDefaulterSummary({required this.balance, this.studentCount});
}

/// Fee-collected figures from `mobile_app/summary_fee_collection` —
/// [totalPaid] rupees collected, across [invoiceCount] paid invoices
/// from [paidStudentCount] students. Matches the web portal's
/// program-wise "Fee Collection / Fee Paid" totals.
class FeeCollectedSummary {
  final int paidStudentCount;
  final int invoiceCount;
  final int totalPaid;
  const FeeCollectedSummary({
    required this.paidStudentCount,
    required this.invoiceCount,
    required this.totalPaid,
  });
}

/// Fetches the Admin portal's Fee Collection cascading filters (Campus →
/// Program → Shift → Year), the final filtered report, and the
/// institute-wide defaulter total from the AIT SmartCampuses API.
class FeeCollectionApi {
  FeeCollectionApi._();

  static const _base = 'https://campus.smartcampuses.com/demo_institute';

  /// Drops rows whose [IdName.id] has already been seen, keeping the
  /// first occurrence and the original order. The cascade dropdowns need
  /// unique option values, and the program/shift lists have been seen to
  /// come back with the same entry twice — this guards every level.
  static List<IdName> _dedupe(Iterable<IdName> items) {
    final seen = <String>{};
    return [
      for (final it in items)
        if (seen.add(it.id)) it,
    ];
  }

  static Future<List<dynamic>?> _getList(Uri url) async {
    try {
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = response.body.trim();
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<IdName>> fetchCampuses() async {
    final list = await _getList(Uri.parse('$_base/mobile_app/load_campus'));
    if (list == null) return [];
    return _dedupe(list.whereType<Map>().map((m) {
      return IdName(m['branch_id'].toString(), (m['name']?.toString() ?? '').trim());
    }));
  }

  static Future<List<IdName>> fetchPrograms(String branchId) async {
    final list = await _getList(Uri.parse('$_base/mobile_app/system_type?branch_id=$branchId'));
    if (list == null) return [];
    return _dedupe(list.whereType<Map>().map((m) {
      return IdName(m['session_id'].toString(), (m['s_name']?.toString() ?? '').trim());
    }));
  }

  static Future<List<IdName>> fetchShifts(String programId) async {
    final list = await _getList(Uri.parse('$_base/mobile_app/load_session?system_type_id=$programId'));
    if (list == null) return [];
    return _dedupe(list.whereType<Map>().map((m) {
      return IdName(m['batch_id'].toString(), (m['batch_title']?.toString() ?? '').trim());
    }));
  }

  /// One row per **section** — `system_type_id` here is actually the
  /// batch id (confirmed live: passing a `batch_id` returns that batch's
  /// year/section rows, e.g. batch 112 → "1ST YEAR : A/B/C/D",
  /// "2ND YEAR : A/B", "3RD YEAR : A"). Keyed on `class_section_id` so
  /// every section stays selectable.
  static Future<List<FeeYear>> fetchYears(String branchId, String batchId) async {
    final list = await _getList(Uri.parse('$_base/mobile_app/get_class?branch_id=$branchId&system_type_id=$batchId'));
    if (list == null) return [];
    final seen = <String>{};
    return [
      for (final m in list.whereType<Map>())
        if (seen.add(m['class_section_id'].toString()))
          FeeYear(
            m['class_id'].toString(),
            m['class_section_id'].toString(),
            (m['cs_name']?.toString() ?? '').trim(),
          ),
    ];
  }

  /// Returns null when the server has no fee data for this combination.
  ///
  /// `admin_fee_collection` aggregates at the year (`class` = `class_id`)
  /// level; `class_section_id` is sent for parity with the web portal
  /// even though the backend currently ignores it. The backend often
  /// reports `totalStudents` as `0` even for a year that has a real
  /// `StudentFeePaid`/`TotalAmount`, so "no data" is only inferred when
  /// every figure is empty/zero.
  static Future<FeeCollectionResult?> fetchFeeCollection({
    required String branchId,
    required String programId,
    required String batchId,
    required String classId,
    required String classSectionId,
  }) async {
    final list = await _getList(
      Uri.parse('$_base/mobile_app/admin_fee_collection?branch=$branchId&session=$programId'
          '&batch_id=$batchId&class=$classId&class_section_id=$classSectionId'),
    );
    if (list == null || list.isEmpty) return null;
    final row = list.first;
    if (row is! Map) return null;

    final totalStudents = int.tryParse(row['totalStudents']?.toString() ?? '') ?? 0;
    final feePaid = int.tryParse(row['StudentFeePaid']?.toString() ?? '') ?? 0;
    final amount = int.tryParse(row['TotalAmount']?.toString() ?? '') ?? 0;
    if (totalStudents == 0 && feePaid == 0 && amount == 0) return null;

    return FeeCollectionResult(totalStudents: totalStudents, feePaid: feePaid, amount: amount);
  }

  /// Outstanding (unpaid) fee-defaulter balance + defaulter head-count
  /// from `mobile_app/summary_fee_defaulter` — the live source for the
  /// screen's "Total Fee Defaulter Balance" banner.
  ///
  /// Scoping (confirmed live):
  ///   * no params → institute-wide total;
  ///   * `program=<session_id>` → that program only (e.g. `program=77`
  ///     for "AI (E)" → balance 395000 / 14 students);
  ///   * `program=<id>&batch=<batch_id>` → that program's single batch —
  ///     the per-batch batches of one program sum exactly to the
  ///     `program`-only figure.
  ///
  /// `batch` is only honoured **alongside** `program` (on its own it
  /// 500s), and `branch`/`class`/`class_section_id` are ignored — so the
  /// banner can follow the Campus→Program→Batch cascade down to batch
  /// level but not Year/Section.
  ///
  /// Response shape differs from every other endpoint here —
  /// `{"success", "message", "data": [{"balance": "...", "student_count":
  /// "..."}]}`, a wrapped object rather than a bare list — so it doesn't
  /// go through [_getList]. Returns null on a request/parse failure or
  /// when `balance` is missing/unparseable.
  static Future<FeeDefaulterSummary?> fetchDefaulterBalance({String? programId, String? batchId}) async {
    try {
      final params = <String, String>{};
      if (programId != null && programId.isNotEmpty) {
        params['program'] = programId;
        // The backend rejects `batch` without `program`.
        if (batchId != null && batchId.isNotEmpty) params['batch'] = batchId;
      }
      final url = Uri.parse('$_base/mobile_app/summary_fee_defaulter')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      if (data is! List || data.isEmpty) return null;
      final row = data.first;
      if (row is! Map) return null;

      final balance = int.tryParse(row['balance']?.toString() ?? '');
      if (balance == null) return null;
      return FeeDefaulterSummary(
        balance: balance,
        studentCount: int.tryParse(row['student_count']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fee **collected** summary from `mobile_app/summary_fee_collection`.
  ///
  /// Scoping (confirmed live — full drill-down, unlike
  /// [fetchDefaulterBalance] which stops at batch):
  ///   * no params → institute-wide;
  ///   * `session=<id>` → that program;
  ///   * `session=<id>&batch_id=<batch_id>` → one batch (222 students);
  ///   * `session=<id>&class=<class_id>` → one year;
  ///   * `session=<id>&class=<class_id>&batch_id=<batch_id>&classSection=<class_section_id>`
  ///     → one section (54 students — the four sections of a batch sum
  ///     back to the 222 batch total).
  ///
  /// Param names here: `session` / `class` / `batch_id` / `classSection`
  /// (bare `batch`/`program`/`class_id`/`class_section_id` are ignored).
  /// Response is a bare object `{"status":"success","student_count":n,
  /// "invoice_count":n,"total_paid":n}`. Returns null on failure / an
  /// all-zero result.
  static Future<FeeCollectedSummary?> fetchCollectionSummary({
    String? programId,
    String? batchId,
    String? classId,
    String? classSectionId,
  }) async {
    try {
      final params = <String, String>{};
      if (programId != null && programId.isNotEmpty) {
        params['session'] = programId;
        if (batchId != null && batchId.isNotEmpty) params['batch_id'] = batchId;
        if (classId != null && classId.isNotEmpty) {
          params['class'] = classId;
          if (classSectionId != null && classSectionId.isNotEmpty) params['classSection'] = classSectionId;
        }
      }
      final url = Uri.parse('$_base/mobile_app/summary_fee_collection')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(url, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['status'] != 'success') return null;

      final totalPaid = int.tryParse(decoded['total_paid']?.toString() ?? '') ?? 0;
      final students = int.tryParse(decoded['student_count']?.toString() ?? '') ?? 0;
      final invoices = int.tryParse(decoded['invoice_count']?.toString() ?? '') ?? 0;
      if (totalPaid == 0 && students == 0 && invoices == 0) return null;

      return FeeCollectedSummary(paidStudentCount: students, invoiceCount: invoices, totalPaid: totalPaid);
    } catch (_) {
      return null;
    }
  }
}
