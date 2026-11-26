import 'package:flutter/material.dart';
import '../../services/fac_leave_balance_api.dart';
import '../../services/fac_profile_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

/// Leave types only applicable to female staff — hidden from this list
/// for anyone whose profile `gender` isn't "Female" (missing/unknown
/// gender defaults to showing them, so a profile-fetch failure never
/// hides a leave type a female user is actually entitled to).
const _femaleOnlyLeaveTypes = ['maternity leave', 'eidat leave'];

/// Faculty leave balance — per-type quota vs. remaining, fetched from
/// the AIT SmartCampuses API. Gated by a real, server-side login session
/// rather than any request parameter, so it only returns data once the
/// user has logged in through this app with genuine, valid Faculty
/// credentials (see [FacLeaveBalanceApi]).
class FacLeaveBalanceScreen extends StatefulWidget {
  const FacLeaveBalanceScreen({super.key});

  @override
  State<FacLeaveBalanceScreen> createState() => _FacLeaveBalanceScreenState();
}

class _FacLeaveBalanceScreenState extends State<FacLeaveBalanceScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  FacLeaveBalanceFetchStatus _status = FacLeaveBalanceFetchStatus.ok;
  List<FacLeaveTypeBalance> _balances = [];

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps the balance in step with the web portal without a manual
    // refresh (see AutoRefreshMixin).
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([FacLeaveBalanceApi.fetchLeaveBalance(), FacProfileApi.fetchProfile()]);
    if (!mounted) return;
    final result = results[0] as FacLeaveBalanceResult;
    final profile = results[1] as Map<String, String>?;
    final gender = profile == null ? '' : FacProfileApi.pick(profile, ['gender']);
    final isFemale = gender.trim().toLowerCase() == 'female';
    setState(() {
      _status = result.status;
      _balances = isFemale
          ? result.balances
          : result.balances.where((b) => !_femaleOnlyLeaveTypes.contains(b.title.trim().toLowerCase())).toList();
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
    switch (_status) {
      case FacLeaveBalanceFetchStatus.noSession:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Session expired. Please log in again.', textAlign: TextAlign.center),
          ),
        );
      case FacLeaveBalanceFetchStatus.error:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Unable to load leave balance — this feature requires an active Faculty session, which isn\'t available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        );
      case FacLeaveBalanceFetchStatus.ok:
        if (_balances.isEmpty) {
          return const Center(child: Text('No leave balance data found.', style: TextStyle(color: Colors.black54)));
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
}
