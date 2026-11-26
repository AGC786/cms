import 'dart:convert';

import 'api_client.dart';

/// A single row of the Student portal's fee challan history table.
class FeeInvoiceRow {
  final String feeInvoiceId;
  final String date;
  final String amount;
  final String status;
  const FeeInvoiceRow({required this.feeInvoiceId, required this.date, required this.amount, required this.status});
}

/// Full detail of a single fee challan, shown in the Preview dialog.
class FeeChallanDetail {
  final String challanId;
  final String studentName;
  final String className;
  final String date;
  final String validUpto;
  final String total;
  final String remaining;
  final String status;
  const FeeChallanDetail({
    required this.challanId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.validUpto,
    required this.total,
    required this.remaining,
    required this.status,
  });
}

/// Fetches the Student portal's fee challan history and per-challan
/// detail from the AIT SmartCampuses API.
class StuFeeApi {
  StuFeeApi._();

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Returns null on a request/parse failure (including the backend's
  /// known session-gated error path).
  static Future<List<FeeInvoiceRow>?> fetchInvoices() async {
    try {
      final response = await ApiClient.instance.get(Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/feeinvoice3'));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['fetch_data'] is! List) return null;

      return (decoded['fetch_data'] as List).whereType<Map>().map((raw) {
        final m = raw.map((k, v) => MapEntry(k.toString(), v));
        final total = (m['total']?.toString() ?? '').replaceAll('-', '');
        return FeeInvoiceRow(
          feeInvoiceId: m['fee_invoice_id']?.toString() ?? '',
          date: m['feedate']?.toString() ?? '-',
          amount: total,
          status: m['status']?.toString() ?? '',
        );
      }).toList();
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<FeeChallanDetail?> fetchChallanDetail(String feeInvoiceId) async {
    try {
      final response =
          await ApiClient.instance.get(Uri.parse('https://campus.smartcampuses.com/demo_institute/Studentportal/fee_challanPreview?fee=$feeInvoiceId'));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      final invoice = decoded['fee_invoice_res'];
      final student = decoded['student_res'];
      final year = decoded['student_year_res'];
      if (invoice is! Map || student is! Map) return null;

      return FeeChallanDetail(
        challanId: invoice['fee_invoice_id']?.toString() ?? '',
        studentName: student['fname']?.toString() ?? '-',
        className: year is Map ? (year['class_name']?.toString() ?? '-') : '-',
        date: _formatDate(invoice['fee_issuance_date']?.toString()),
        validUpto: _formatDate(invoice['fee_submission_date']?.toString()),
        total: invoice['total']?.toString() ?? '-',
        remaining: invoice['remaining']?.toString() ?? '0',
        status: invoice['status']?.toString() ?? '-',
      );
    } on ApiSessionExpiredException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
