import 'package:flutter/material.dart';
import '../../services/leave_balance_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

class EmpLeaveBalanceScreen extends StatefulWidget {
  const EmpLeaveBalanceScreen({super.key});

  @override
  State<EmpLeaveBalanceScreen> createState() => _EmpLeaveBalanceScreenState();
}

class _EmpLeaveBalanceScreenState extends State<EmpLeaveBalanceScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  LeaveBalanceFetchStatus _status = LeaveBalanceFetchStatus.ok;
  List<LeaveTypeBalance> _balances = [];

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
    final result = await LeaveBalanceApi.fetchLeaveBalance();
    if (!mounted) return;
    setState(() {
      _status = result.status;
      _balances = result.balances;
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
            const RnPageHeader(title: 'Leave Balance'),
            Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.blueMid)) : _buildBody()),
            const SmartCampusesFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_status == LeaveBalanceFetchStatus.noSession) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Session expired. Please log in again.', textAlign: TextAlign.center),
        ),
      );
    }
    if (_status == LeaveBalanceFetchStatus.error) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Unable to load leave balance. Please try again later.', textAlign: TextAlign.center),
        ),
      );
    }
    if (_balances.isEmpty) {
      return const Center(child: Text('No leave balance data found.'));
    }
    return SingleChildScrollView(
      child: LeaveBalanceTable(
        rows: _balances
            .map((b) => LeaveBalanceTableRow(title: b.title, total: num.tryParse(b.total) ?? 0, avail: num.tryParse(b.avail), remaining: num.tryParse(b.remaining) ?? 0))
            .toList(),
      ),
    );
  }
}
