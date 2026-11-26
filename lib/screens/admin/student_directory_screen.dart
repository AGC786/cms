import 'package:flutter/material.dart';
import '../../services/student_directory_admin_api.dart';
import '../../widgets/common.dart';

class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  String query = '';
  bool _loading = true;
  List<StudentRecord> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final students = await StudentDirectoryAdminApi.fetchStudents();
    if (!mounted) return;
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final results = q.isEmpty ? <StudentRecord>[] : _students.where((s) => s.matches(q)).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Student Directory'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: _loading ? 'Loading students...' : 'Search by name or GR No',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: q.isEmpty
                          ? const Center(child: Text('Search for a student to display results.'))
                          : results.isEmpty
                              ? const Center(child: Text('No matches found.'))
                              : ListView.builder(
                                  itemCount: results.length,
                                  itemBuilder: (ctx, i) {
                                    final s = results[i];
                                    return DirectoryCard(
                                      name: s.name,
                                      sub: '${s.program} • ${s.grNo}',
                                      onTap: () => _showStudentDetails(context, s),
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

  void _showStudentDetails(BuildContext context, StudentRecord s) {
    showDetailsDialog(
      context,
      title: 'Student Details',
      rows: [
        MapEntry('Name', s.name),
        MapEntry('GR No', s.grNo),
        MapEntry('Email', s.email),
        MapEntry('Program', s.program),
        MapEntry('Batch', s.batch),
        MapEntry('CNIC', s.cnic),
        MapEntry('Admission Date', s.admissionDate),
        MapEntry('Phone No', s.mobile),
      ],
    );
  }
}
