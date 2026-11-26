import 'package:flutter/material.dart';
import '../../services/fac_leave_status_api.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';
import 'fac_add_leave_screen.dart';

const _monthNames = {
  'jan': 1, 'january': 1,
  'feb': 2, 'february': 2,
  'mar': 3, 'march': 3,
  'apr': 4, 'april': 4,
  'may': 5,
  'jun': 6, 'june': 6,
  'jul': 7, 'july': 7,
  'aug': 8, 'august': 8,
  'sep': 9, 'sept': 9, 'september': 9,
  'oct': 10, 'october': 10,
  'nov': 11, 'november': 11,
  'dec': 12, 'december': 12,
};

/// Parses dates in whatever shape this backend sends them —
/// `yyyy-MM-dd[ HH:mm:ss]`, `dd-MM-yyyy`/`dd/MM/yyyy`, or (confirmed live
/// on `Teacherportal/load_leaves`'s `start_date`) `dd-MonthName-yyyy`
/// with the month spelled out, e.g. `09-December-2022` — falling back to
/// [DateTime(0)] for anything unparseable so unsortable rows sink to the
/// bottom rather than crashing the sort.
DateTime _parseLeaveDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return DateTime(0);
  final direct = DateTime.tryParse(s);
  if (direct != null) return direct;
  final numeric = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(s);
  if (numeric != null) {
    final day = int.tryParse(numeric.group(1)!);
    final month = int.tryParse(numeric.group(2)!);
    final year = int.tryParse(numeric.group(3)!);
    if (day != null && month != null && year != null) return DateTime(year, month, day);
  }
  final named = RegExp(r'^(\d{1,2})[-/\s]([A-Za-z]+)[-/\s](\d{4})').firstMatch(s);
  if (named != null) {
    final day = int.tryParse(named.group(1)!);
    final month = _monthNames[named.group(2)!.toLowerCase()];
    final year = int.tryParse(named.group(3)!);
    if (day != null && month != null && year != null) return DateTime(year, month, day);
  }
  return DateTime(0);
}

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

/// Faculty leave application history, styled as pink-outlined cards,
/// fetched from the AIT SmartCampuses API.
class FacLeaveStatusScreen extends StatefulWidget {
  const FacLeaveStatusScreen({super.key});

  @override
  State<FacLeaveStatusScreen> createState() => _FacLeaveStatusScreenState();
}

class _FacLeaveStatusScreenState extends State<FacLeaveStatusScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  bool _unavailable = false;
  List<FacLeaveEntry> _leaveHistory = [];

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps this history in step with new leave applications/approvals
    // made on the web portal (see AutoRefreshMixin).
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await FacLeaveStatusApi.fetchLeaveStatus();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (loaded == null) {
        _unavailable = true;
      } else {
        // Most recently *taken* leave first (by its own start date), not
        // by when it was applied for — an old leave applied for late, or
        // a future leave applied for early, shouldn't jump the queue.
        _leaveHistory = [...loaded]
          ..sort((a, b) => _parseLeaveDate(b.startDate).compareTo(_parseLeaveDate(a.startDate)));
      }
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
    if (_unavailable) {
      message = 'Unable to load leave status — this feature requires an active Faculty session, which isn\'t available yet.';
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
            MaterialPageRoute(builder: (_) => const FacAddLeaveScreen()),
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
                    Text(l.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00558D))),
                    const SizedBox(height: 6),
                    _row('S.No:', l.leaveId),
                    _row('Start Date:', l.startDate),
                    _row('End Date:', l.endDate),
                    _row('Total Days:', l.total),
                    _row('Apply Date:', l.applyDate),
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
