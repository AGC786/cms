import 'package:flutter/material.dart';
import '../../services/emp_salary_slip_api.dart';
import '../../theme.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

/// Employee salary slip history table — identical UI to the Faculty
/// portal's Salary Slip screen.
class EmpSalarySlipScreen extends StatefulWidget {
  const EmpSalarySlipScreen({super.key});

  @override
  State<EmpSalarySlipScreen> createState() => _EmpSalarySlipScreenState();
}

class _EmpSalarySlipScreenState extends State<EmpSalarySlipScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  SalarySlipFetchStatus _status = SalarySlipFetchStatus.ok;
  List<SalarySlipRecord> _slips = [];

  @override
  void initState() {
    super.initState();
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await EmpSalarySlipApi.fetchSalarySlips();
    if (!mounted) return;
    setState(() {
      _status = result.status;
      _slips = result.records;
      _loading = false;
    });
  }

  Future<void> _showDetails(BuildContext context, SalarySlipRecord s) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF981D5C))),
    );
    final detail = await EmpSalarySlipApi.fetchSalarySlipDetail(s.salaryId);
    if (!context.mounted) return;
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
                child: Text('Salary Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.headingSize, color: Color(0xFF3E4185))),
              ),
              const SizedBox(height: 12),
              if (detail == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No detailed data available.', textAlign: TextAlign.center),
                )
              else ...[
                const Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF981D5C))),
                const SizedBox(height: 6),
                for (final e in detail.earnings) _detailRow(e.item, e.amount),
                const Divider(),
                _detailRow('Gross Salary', detail.grossSalary, bold: true),
                const SizedBox(height: 12),
                const Text('Deductions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF981D5C))),
                const SizedBox(height: 6),
                for (final e in detail.deductions) _detailRow(e.item, e.amount),
                const Divider(),
                _detailRow('Total Deductions', detail.totalDeductions, bold: true),
                const SizedBox(height: 12),
                const Divider(thickness: 1.5),
                _detailRow('Net Salary', detail.netSalary, bold: true),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF981D5C),
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
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
        children: [
          const RnPageHeader(title: 'Salary Slip'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF981D5C)))
                : _status == SalarySlipFetchStatus.noSession
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Session expired. Please log in again.', textAlign: TextAlign.center),
                        ),
                      )
                    : _status == SalarySlipFetchStatus.error
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Unable to load salary slips. Please try again later.', textAlign: TextAlign.center),
                            ),
                          )
                        : _slips.isEmpty
                            ? const Center(child: Text('No Salary Slips Found'))
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(15),
                                child: Table(
                                  border: TableBorder.all(color: const Color(0xFFDDDDDD)),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.3),
                                    1: FlexColumnWidth(1.2),
                                    2: FlexColumnWidth(1),
                                    3: FlexColumnWidth(1),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration: BoxDecoration(color: Color(0xFF266892)),
                                      children: [
                                        _HeaderCell('Date'),
                                        _HeaderCell('Amount'),
                                        _HeaderCell('Status'),
                                        _HeaderCell('Action'),
                                      ],
                                    ),
                                    for (final s in _slips)
                                      TableRow(
                                        children: [
                                          _Cell(s.date),
                                          _Cell(s.amount),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                            child: Text(
                                              s.status,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E8A3C)),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                            child: TextButton(
                                              onPressed: () => _showDetails(context, s),
                                              child: const Text('Preview', style: TextStyle(color: Color(0xFF981D5C), fontWeight: FontWeight.bold, fontSize: 13)),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
          ),
          const SmartCampusesFooter(),
        ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
    );
  }
}
