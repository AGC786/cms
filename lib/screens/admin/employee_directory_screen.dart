import 'package:flutter/material.dart';
import '../../services/employee_directory_admin_api.dart';
import '../../widgets/common.dart';

class EmployeeDirectoryScreen extends StatefulWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  State<EmployeeDirectoryScreen> createState() => _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  String query = '';
  bool _loading = true;
  List<EmployeeRecord> _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employees = await EmployeeDirectoryAdminApi.fetchEmployees();
    if (!mounted) return;
    setState(() {
      _employees = employees;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final results = q.isEmpty ? <EmployeeRecord>[] : _employees.where((e) => e.matches(q)).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Employee Directory'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: _loading ? 'Loading employees...' : 'Search by name or id',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: q.isEmpty
                          ? const Center(child: Text('Search for an employee to display results.'))
                          : results.isEmpty
                              ? const Center(child: Text('No employees found.'))
                              : ListView.builder(
                                  itemCount: results.length,
                                  itemBuilder: (ctx, i) {
                                    final e = results[i];
                                    return DirectoryCard(
                                      name: e.name,
                                      sub: e.deptName,
                                      onTap: () => _showEmployeeDetails(context, e),
                                    );
                                  },
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

  void _showEmployeeDetails(BuildContext context, EmployeeRecord employee) {
    showDetailsDialog(
      context,
      title: 'Employee Details',
      rows: [
        MapEntry('Name', employee.name),
        MapEntry('Employee ID', employee.empId),
        MapEntry('Email', employee.email),
        MapEntry('Program Type', employee.programType),
        MapEntry('Scale Type', employee.scaleType),
        MapEntry('Department', employee.deptName),
        MapEntry('Staff Type', employee.staffType),
        MapEntry('Phone No', employee.mobile),
      ],
    );
  }
}
