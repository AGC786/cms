import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/role_select_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/employee/employee_portal_screen.dart';
import 'screens/faculty/faculty_portal.dart';
import 'screens/student/student_portal_screen.dart';
import 'screens/directory_search_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/attendance_calendar_screen.dart';
import 'screens/home_main_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/new_password_screen.dart';
import 'services/idle_timeout_service.dart';
import 'services/session_manager.dart';

void main() => runApp(const CmsApp());

class CmsApp extends StatefulWidget {
  const CmsApp({super.key});

  @override
  State<CmsApp> createState() => _CmsAppState();
}

class _CmsAppState extends State<CmsApp> {
  @override
  void initState() {
    super.initState();
    IdleTimeoutService.instance.start();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMS Campus Management System',
      debugShowCheckedModeBanner: false,
      navigatorKey: SessionManager.instance.navigatorKey,
      theme: buildAppTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/role': (context) => const RoleSelectScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/homeMain': (context) => const HomeMainScreen(),
        '/otp': (context) => const OtpScreen(),
        '/new-password': (context) => const NewPasswordScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/employee': (context) => const EmployeePortalScreen(),
        '/faculty': (context) => const FacultyPortal(),
        '/student': (context) => const StudentPortalScreen(),
        '/student-directory': (context) => const DirectorySearchScreen(type: DirectoryType.student),
        '/employee-directory': (context) => const DirectorySearchScreen(type: DirectoryType.employee),
        '/contact': (context) => const ContactScreen(),
        '/attendance': (context) => const AttendanceCalendarScreen(),
      },
    );
  }
}
