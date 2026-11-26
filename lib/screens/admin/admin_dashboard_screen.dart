import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/common.dart';
import 'student_directory_screen.dart';
import 'student_registration_screen.dart';
import 'student_attendance_screen.dart';
import 'class_schedule_screen.dart';
import 'fee_collection_screen.dart';
import 'course_attendance_screen.dart';
import 'employee_directory_screen.dart';
import 'employee_attendance_screen.dart';
import 'employee_summary_screen.dart';


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static final _tiles = <_TileDef>[
    _TileDef('assets/Images/studentRegistration.png', 'Student Registration', (ctx) => const StudentRegistrationScreen()),
    _TileDef('assets/Images/Directory.png', 'Student Directory', (ctx) => const StudentDirectoryScreen()),
    _TileDef('assets/Images/Attendance.png', 'Student Attendance', (ctx) => const StudentAttendanceScreen()),
    _TileDef('assets/Images/schedule.png', 'Class Schedule', (ctx) => const ClassScheduleScreen()),
    _TileDef('assets/Images/feesCollection.png', 'Fee Collection', (ctx) => const FeeCollectionScreen()),
    _TileDef('assets/Images/course.png', 'Course Attendance', (ctx) => const CourseAttendanceScreen()),
    _TileDef('assets/Images/employees.png', 'Employee Directory', (ctx) => const EmployeeDirectoryScreen()),
    _TileDef('assets/Images/employeeattend.png', 'Employee Attendance', (ctx) => const EmployeeAttendanceScreen()),
    _TileDef('assets/Images/employee.png', 'Employee Summary', (ctx) => const EmployeeSummaryScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HamburgerHeader(title: 'Admin'),
      endDrawer: const AdminSideDrawer(),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: _tiles.length,
              itemBuilder: (ctx, i) {
                final t = _tiles[i];
                return DashboardTile(
                  assetPath: t.assetPath,
                  label: t.label,
                  onTap: () => Navigator.of(ctx).push(MaterialPageRoute(builder: t.builder)),
                );
              },
            ),
          ),
          const FooterUrl(),
        ],
      ),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.small(
          heroTag: 'admin-menu',
          backgroundColor: AppColors.maroonBtn,
          onPressed: () => Scaffold.of(ctx).openEndDrawer(),
          child: const Icon(Icons.menu, color: Colors.white),
        ),
      ),
    );
  }
}

class _TileDef {
  final String assetPath;
  final String label;
  final WidgetBuilder builder;
  _TileDef(this.assetPath, this.label, this.builder);
}
