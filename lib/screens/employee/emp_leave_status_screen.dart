import 'package:flutter/material.dart';
import '../../services/emp_leave_status_api.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';
import 'emp_add_leave_screen.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'Approved':
      return const Color(0xFF1E8A3C);
    case 'Denied':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFFE07A1F);
  }
}

/// Employee leave application history, styled as pink-outlined cards —
/// identical UI to the Faculty portal's Leave Status screen.
class EmpLeaveStatusScreen extends StatefulWidget {
  const EmpLeaveStatusScreen({super.key});

  @override
  State<EmpLeaveStatusScreen> createState() => _EmpLeaveStatusScreenState();
}

class _EmpLeaveStatusScreenState extends State<EmpLeaveStatusScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  LeaveStatusFetchStatus _status = LeaveStatusFetchStatus.ok;
  List<LeaveStatusRecord> _leaveHistory = [];

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
    final result = await EmpLeaveStatusApi.fetchLeaveStatus();
    if (!mounted) return;
    setState(() {
      _status = result.status;
      _leaveHistory = result.records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const RnPageHeader(title: 'Leave Status'),
            Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF981D5C))) : _buildBody()),
            const SmartCampusesFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    String? message;
    if (_status == LeaveStatusFetchStatus.noSession) {
      message = 'Session expired. Please log in again.';
    } else if (_status == LeaveStatusFetchStatus.error) {
      message = 'Unable to load leave status. Please try again later.';
    } else if (_leaveHistory.isEmpty) {
      message = 'No Leave Status Found';
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            foregroundColor: const Color(0xFF981D5C),
            side: const BorderSide(color: Color(0xFF981D5C)),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EmpAddLeaveScreen()),
          ),
          child: const Text('+ Apply for Leave'),
        ),
        const SizedBox(height: 20),
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 15)),
          )
        else
          ..._leaveHistory.map((l) => Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF981D5C)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.leaveTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00558D))),
                    const SizedBox(height: 6),
                    _row('S.No:', l.leaveId),
                    _row('Start Date:', l.startDate),
                    _row('End Date:', l.endDate),
                    _row('Total Days:', l.total),
                    _row('Apply Date:', l.createdAt),
                    _row('Reason:', l.reason),
                    _row('Status:', l.status, valueColor: _statusColor(l.status)),
                  ],
                ),
              )),
      ],
    );
  }

  static Widget _row(String label, String value, {Color valueColor = Colors.black}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
            Expanded(
              child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: valueColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
