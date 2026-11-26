import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../widgets/common_widgets.dart';

enum DirectoryType { student, employee }

class DirectorySearchScreen extends StatefulWidget {
  final DirectoryType type;
  const DirectorySearchScreen({super.key, required this.type});

  @override
  State<DirectorySearchScreen> createState() => _DirectorySearchScreenState();
}

class _DirectorySearchScreenState extends State<DirectorySearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  bool get isStudent => widget.type == DirectoryType.student;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final studentResults = isStudent ? studentDB.where((s) => s.name.toLowerCase().contains(q)).toList() : const <StudentRecord>[];
    final employeeResults = !isStudent ? employeeDB.where((e) => e.name.toLowerCase().contains(q)).toList() : const <EmployeeRecord>[];

    return Scaffold(
      appBar: gradientAppBar(context, isStudent ? 'Student Directory' : 'Employee Directory'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: 'Search by name...', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: q.isEmpty
                ? Center(
                    child: Text('Start typing a name to search ${isStudent ? 'students' : 'employees'}.',
                        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: isStudent
                        ? studentResults.map((s) => _row(s.name, null, () => _showStudentDetail(s))).toList()
                        : employeeResults.map((e) => _row(e.name, e.empId, () => _showEmployeeDetail(e))).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(String name, String? code, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE6E6EF)), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontSize: 13)),
                if (code != null) Text(code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStudentDetail(StudentRecord s) {
    _showDetailDialog('Student Details', {
      'Name:': s.name,
      'GR No:': s.grNo,
      'Email:': s.email,
      'Program:': s.program,
      'Batch:': s.batch,
      'CNIC:': s.cnic,
      'Admission Date:': s.admission,
      'Phone No:': s.phone,
    });
  }

  void _showEmployeeDetail(EmployeeRecord e) {
    _showDetailDialog('Employee Details', {
      'Name:': e.name,
      'Employee ID:': e.empId,
      'Program Type:': e.programType,
      'Scale Type:': e.scaleType,
      'Department Name:': e.department,
      'Staff Type:': e.staffType,
      'Email:': e.email,
      'Phone No:': e.phone,
    });
  }

  void _showDetailDialog(String title, Map<String, String> rows) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),
              ...rows.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 110, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                        Expanded(child: Text(e.value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5))),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C4FA0)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
