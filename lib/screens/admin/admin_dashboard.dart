import 'package:flutter/material.dart';
import '../../services/alert_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart' show NotificationBellAction;
import 'admin_alert_screen.dart';
import 'student_directory_screen.dart';
import 'student_registration_screen.dart';
import 'student_attendance_screen.dart';
import 'class_schedule_screen.dart';
import 'fee_collection_screen.dart';
import 'course_attendance_screen.dart';
import 'employee_directory_screen.dart';
import 'employee_attendance_screen.dart';
import 'employee_summary_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static final _tiles = <_TileDef>[
    _TileDef('assets/Images/studentRegistration.png', const Color(0xFF6A2F8F), 'Student\nRegistration', (ctx) => const StudentRegistrationScreen()),
    _TileDef('assets/Images/Directory.png', const Color(0xFF1C4FA0), 'Student\nDirectory', (ctx) => const StudentDirectoryScreen()),
    _TileDef('assets/Images/Attendance.png', const Color(0xFF1E8A3C), 'Student\nAttendance', (ctx) => const StudentAttendanceScreen()),
    _TileDef('assets/Images/schedule.png', const Color(0xFFC79A12), 'Class\nSchedule', (ctx) => const ClassScheduleScreen()),
    _TileDef('assets/Images/feesCollection.png', const Color(0xFFC62828), 'Fee\nCollection', (ctx) => const FeeCollectionScreen()),
    _TileDef('assets/Images/course.png', const Color(0xFF981D5C), 'Course\nAttendance', (ctx) => const CourseAttendanceScreen()),
    _TileDef('assets/Images/employees.png', const Color(0xFF555555), 'Employee\nDirectory', (ctx) => const EmployeeDirectoryScreen()),
    _TileDef('assets/Images/employeeattend.png', const Color(0xFF1C4FA0), 'Employee\nAttendance', (ctx) => const EmployeeAttendanceScreen()),
    _TileDef('assets/Images/employee.png', const Color(0xFFE07A1F), 'Employee\nSummary', (ctx) => const EmployeeSummaryScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HamburgerHeader(
        title: 'Admin Portal',
        actions: [
          NotificationBellAction(
            fetchUnseenCount: AlertApi.fetchUnreadCount,
            builder: (_) => const AdminAlertScreen(),
          ),
        ],
      ),
      drawer: const AdminSideDrawer(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Image.asset('assets/Images/logo-sc.png', height: 60, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _tiles.length,
                    itemBuilder: (ctx, i) {
                      final t = _tiles[i];
                      return _AdminGradientTile(
                        assetPath: t.assetPath,
                        iconColor: t.iconColor,
                        label: t.label,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: t.builder)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const FooterUrl(),
        ],
      ),
    );
  }
}

class _TileDef {
  final String assetPath;
  final Color iconColor;
  final String label;
  final WidgetBuilder builder;
  _TileDef(this.assetPath, this.iconColor, this.label, this.builder);
}

class _AdminGradientTile extends StatelessWidget {
  final String assetPath;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _AdminGradientTile({required this.assetPath, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFF1F2F7),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Image.asset(assetPath, width: 24, height: 24, color: Colors.white, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12.5, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
