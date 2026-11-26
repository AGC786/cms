import 'package:flutter/material.dart';

import '../../services/leave_status_admin_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class LeaveStatusAdminScreen extends StatefulWidget {
  const LeaveStatusAdminScreen({super.key});

  @override
  State<LeaveStatusAdminScreen> createState() => _LeaveStatusAdminScreenState();
}

class _LeaveStatusAdminScreenState extends State<LeaveStatusAdminScreen> {
  String query = '';
  bool _loadingEmployees = true;
  List<EmployeeInfo> _employees = [];

  EmployeeInfo? _selected;
  bool _loadingLeaves = false;
  List<LeaveEntry> _leaves = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await LeaveStatusAdminApi.fetchEmployees();
    if (!mounted) return;
    setState(() {
      _employees = employees;
      _loadingEmployees = false;
    });
  }

  List<EmployeeInfo> get _matches {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _employees
        .where(
          (e) =>
              e.name.toLowerCase().contains(q) ||
              e.employeeCode.toLowerCase().contains(q) ||
              e.designation.toLowerCase().contains(q) ||
              e.empId.toLowerCase().contains(q),
        )
        .take(8)
        .toList();
  }

  Future<void> _selectEmployee(EmployeeInfo emp) async {
    setState(() {
      _selected = emp;
      _loadingLeaves = true;
      _leaves = [];
    });
    final leaves = await LeaveStatusAdminApi.fetchLeaveDetails(emp.empId);
    if (!mounted) return;
    setState(() {
      _leaves = leaves;
      _loadingLeaves = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.green;
      case 'Pending':
        return AppColors.orange;
      default:
        return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Leave Status'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: _loadingEmployees
                            ? 'Loading employees...'
                            : 'Search Employee by name, code or designation',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onChanged: (v) => setState(() {
                        query = v;
                        _selected = null;
                      }),
                    ),
                    if (_selected == null && _matches.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: _matches
                              .map(
                                (e) => DirectoryCard(
                                  name: e.name,
                                  sub: e.empId,
                                  onTap: () => _selectEmployee(e),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _loadingLeaves
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.maroonBtn,
                              ),
                            )
                          : _selected == null
                          ? const Center(
                              child: Text(
                                'Search and select an employee to view leave status.',
                              ),
                            )
                          : ListView(
                              children: [
                                const Center(
                                  child: Text(
                                    'Leave Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppColors.maroonBtn,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.maroonBtn,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _leaveRow('Name:', _selected!.name),
                                      _leaveRow(
                                        'Employee Code:',
                                        _selected!.employeeCode,
                                      ),
                                      _leaveRow(
                                        'Designation:',
                                        _selected!.designation.isEmpty
                                            ? '-'
                                            : _selected!.designation,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_leaves.isEmpty)
                                  const Center(
                                    child: Text('No matching leave records.'),
                                  )
                                else
                                  ..._leaves.map(
                                    (l) => Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.maroonBtn,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          _leaveRow('Leave Title:', l.title),
                                          _leaveRow(
                                            'Leave Status:',
                                            l.status,
                                            valueColor: _statusColor(l.status),
                                          ),
                                          _leaveRow('Apply Date:', l.applyDate),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const FooterUrl(),
          ],
        ),
      ),
    );
  }

  Widget _leaveRow(
    String label,
    String value, {
    Color valueColor = Colors.black,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: valueColor,
            ),
          ),
        ),
      ],
    ),
  );
}
