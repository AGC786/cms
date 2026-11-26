import 'package:flutter/material.dart';
import '../../services/comp_slip_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common.dart';

/// Employee's Compensation Slip history, fetching the real monthly
/// records from the AIT SmartCampuses Staff Portal API.
class EmpCompSlipScreen extends StatefulWidget {
  const EmpCompSlipScreen({super.key});

  @override
  State<EmpCompSlipScreen> createState() => _EmpCompSlipScreenState();
}

class _EmpCompSlipScreenState extends State<EmpCompSlipScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  CompSlipFetchStatus _status = CompSlipFetchStatus.ok;
  List<CompSlipRecord> _records = [];

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
    final result = await CompSlipApi.fetchCompensationSlips();
    if (!mounted) return;
    setState(() {
      _status = result.status;
      _records = result.records;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'paid':
        return AppColors.green;
      case 'rejected':
        return AppColors.red;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Compensation Slip', color: AppColors.blueMid),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.blueMid))
                  : _status == CompSlipFetchStatus.noSession
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Session expired. Please log in again.', textAlign: TextAlign.center),
                          ),
                        )
                      : _status == CompSlipFetchStatus.error
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Unable to load compensation slips. Please try again later.', textAlign: TextAlign.center),
                              ),
                            )
                          : _records.isEmpty
                              ? const Center(child: Text('No compensation slips found.', style: TextStyle(color: AppColors.muted)))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(14),
                                  itemCount: _records.length,
                                  itemBuilder: (context, i) {
                                    final r = _records[i];
                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: const Color(0xFFF7F7FB), borderRadius: BorderRadius.circular(14)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r.username, style: const TextStyle(color: AppColors.blueMid, fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 10),
                                          _row('Employee ID', r.empId),
                                          _row('Month', r.month),
                                          _row('Allowance Type', r.allowanceType),
                                          _row('Department', r.deptName),
                                          _row('Basic Salary', r.basicSalary),
                                          _row('Deduction Amount', r.deductionAmount),
                                          _row('Total Payment', r.totalPayment),
                                          Row(
                                            children: [
                                              const Text('Status: ', style: TextStyle(fontSize: 12)),
                                              Text(
                                                r.status.isEmpty ? '-' : r.status,
                                                style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor(r.status)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text('$label: ${value.isEmpty ? '-' : value}', style: const TextStyle(fontSize: 12)),
      );
}
