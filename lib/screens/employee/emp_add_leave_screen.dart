
import 'package:flutter/material.dart';
import '../../services/leave_balance_api.dart';
import '../../services/emp_leave_status_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart';

/// Leave application form — leave type, date range, and reason — pushed
/// from the Employee Leave Status screen's "Apply for Leave" button.
///
/// Calendar validation: no past dates, no weekends (Saturday/Sunday —
/// this institute doesn't hold classes those days, so leave isn't
/// applicable), "To" can't be before "From", and the requested day count
/// can't exceed the selected leave type's remaining balance (when that
/// balance is known — see [_remainingFor]).
class EmpAddLeaveScreen extends StatefulWidget {
  const EmpAddLeaveScreen({super.key});

  @override
  State<EmpAddLeaveScreen> createState() => _EmpAddLeaveScreenState();
}

class _EmpAddLeaveScreenState extends State<EmpAddLeaveScreen> {
  String? leaveType;
  DateTime? fromDate;
  DateTime? toDate;
  final _reasonCtrl = TextEditingController();

  List<LeaveTypeBalance> _balances = [];
  bool _submitting = false;

  static const leaveTypes = ['CL', 'CPL', 'EL', 'EOL', 'Hajj Leave', 'Medical Leave', 'Umrah Leave'];

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final result = await LeaveBalanceApi.fetchLeaveBalance();
    if (!mounted) return;
    if (result.status == LeaveBalanceFetchStatus.ok) {
      setState(() => _balances = result.balances);
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isWeekend(DateTime d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  /// Remaining days for the currently selected [leaveType], matched
  /// case-insensitively (exact or "starts with") against the balance
  /// titles the backend returns — those titles aren't guaranteed to be
  /// the same short codes shown in the dropdown, so an unmatched type
  /// returns null and the balance check is skipped rather than guessed.
  num? _remainingFor(String type) {
    for (final b in _balances) {
      final title = b.title.trim().toLowerCase();
      final t = type.trim().toLowerCase();
      if (title == t || title.startsWith(t) || t.startsWith(title)) {
        return num.tryParse(b.remaining);
      }
    }
    return null;
  }

  Future<void> _pickDate(bool isFrom) async {
    final today = _dateOnly(DateTime.now());
    final firstSelectable = isFrom ? today : (fromDate ?? today);
    final picked = await showAppDatePicker(
      context: context,
      initialDate: (isFrom ? fromDate : toDate) ?? firstSelectable,
      firstDate: firstSelectable,
      lastDate: DateTime(today.year + 2),
      selectableDayPredicate: (d) => !_isWeekend(d),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        fromDate = picked;
        // A "To" picked before the new "From" is no longer valid.
        if (toDate != null && toDate!.isBefore(picked)) toDate = null;
      } else {
        toDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (leaveType == null || fromDate == null || toDate == null) {
      showToast(context, 'Please fill in the leave type and date range.');
      return;
    }
    if (toDate!.isBefore(fromDate!)) {
      showToast(context, 'To date cannot be before From date.');
      return;
    }
    final days = toDate!.difference(fromDate!).inDays + 1;
    final remaining = _remainingFor(leaveType!);
    if (remaining != null && days > remaining) {
      showToast(context, 'You only have $remaining day(s) of $leaveType left, but selected $days.');
      return;
    }
    setState(() => _submitting = true);
    final ok = await EmpLeaveStatusApi.submitLeave(
      leaveTitle: leaveType!,
      startDate: fromDate!,
      endDate: toDate!,
      reason: _reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      showToast(context, 'Leave application submitted');
      Navigator.of(context).pop();
    } else {
      showToast(context, 'Unable to submit leave application. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Application Form for Leave', color: AppColors.blueMid),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Choose Leave Type:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: leaveType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Select Leave Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => leaveType = v),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DateFieldRow(
                            label: 'From',
                            formattedDate: fromDate == null ? 'Select date' : _fmt(fromDate!),
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DateFieldRow(
                            label: 'To',
                            formattedDate: toDate == null ? 'Select date' : _fmt(toDate!),
                            onTap: () => _pickDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Reason:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reasonCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Reason for Leave',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: MaroonPillButton(label: _submitting ? 'Submitting...' : 'Submit', onPressed: _submitting ? () {} : _submit)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const GradientFooterBar(),
    );
  }
}
