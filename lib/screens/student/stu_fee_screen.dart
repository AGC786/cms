import 'package:flutter/material.dart';
import '../../services/stu_fee_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class StuFeeScreen extends StatefulWidget {
  const StuFeeScreen({super.key});

  @override
  State<StuFeeScreen> createState() => _StuFeeScreenState();
}

class _StuFeeScreenState extends State<StuFeeScreen> {
  late Future<List<FeeInvoiceRow>?> _future;

  @override
  void initState() {
    super.initState();
    _future = StuFeeApi.fetchInvoices();
  }

  Future<void> _preview(String feeInvoiceId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.maroonBtn)),
    );
    final detail = await StuFeeApi.fetchChallanDetail(feeInvoiceId);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Fee Challan Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3E4185))),
              ),
              const SizedBox(height: 12),
              if (detail == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No detailed data available.', textAlign: TextAlign.center),
                )
              else ...[
                _detailRow('Student', detail.studentName),
                _detailRow('Class', detail.className),
                _detailRow('Issue Date', detail.date),
                _detailRow('Valid Upto', detail.validUpto),
                const Divider(),
                _detailRow('Total', detail.total, bold: true),
                _detailRow('Remaining', detail.remaining, bold: true),
                const Divider(thickness: 1.5),
                _detailRow('Status', detail.status, bold: true),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.maroonBtn,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Fee Challan', color: AppColors.blueMid),
            Expanded(
              child: FutureBuilder<List<FeeInvoiceRow>?>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.blueMid));
                  }
                  final rows = snapshot.data;
                  if (rows == null || rows.isEmpty) {
                    return const Center(child: Text('No fee invoices found.', style: TextStyle(color: AppColors.muted)));
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Table(
                      border: TableBorder.all(color: AppColors.line),
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(0.9),
                        3: FlexColumnWidth(1.1),
                        4: FlexColumnWidth(0.9),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: AppColors.blueMid),
                          children: [
                            _Cell('Date', header: true),
                            _Cell('Recipt No', header: true),
                            _Cell('Amount', header: true),
                            _Cell('Status', header: true),
                            _Cell('Action', header: true),
                          ],
                        ),
                        ...rows.map(
                          (r) => TableRow(
                            children: [
                              _Cell(r.date),
                              _Cell(r.feeInvoiceId),
                              _Cell(r.amount),
                              _Cell(r.status, color: AppColors.green, bold: true),
                              _ActionCell(onTap: () => _preview(r.feeInvoiceId)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const FooterUrl(),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool header;
  final bool bold;
  final Color? color;
  const _Cell(this.text, {this.header = false, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: header || bold ? FontWeight.bold : FontWeight.w600,
          color: header ? Colors.white : (color ?? AppColors.ink),
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  final VoidCallback onTap;
  const _ActionCell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: const Text('Preview', style: TextStyle(color: AppColors.maroonBtn, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }
}
