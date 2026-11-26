import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/emp_notification_api.dart';
import '../../services/emp_profile_api.dart';
import '../../services/notice_api.dart';
import '../../services/notice_read_tracker.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart' show AboutUsScreen, ContactScreen, NotificationBellAction;
import 'emp_attendance_screen.dart';
import 'emp_leave_balance_screen.dart';
import 'emp_leave_status_screen.dart';
import 'emp_salary_slip_screen.dart';
import 'emp_comp_slip_screen.dart';
import 'emp_events_screen.dart';
import 'emp_notice_screen.dart';
import 'emp_notifications_screen.dart';

class EmployeePortalScreen extends StatefulWidget {
  const EmployeePortalScreen({super.key});

  @override
  State<EmployeePortalScreen> createState() => _EmployeePortalScreenState();
}

class _EmployeePortalScreenState extends State<EmployeePortalScreen> {
  bool _loading = true;
  String _name = '';
  String? _picture;
  Map<String, String> _info = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final staffId = await SessionManager.instance.getEmployeeId();
    final profile = staffId == null ? null : await EmpProfileApi.fetchProfile(staffId: staffId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (profile != null) {
        // `Staffportal/profileInfo` has no single `name`/`staff_name`
        // field at all (confirmed live) — only separate `fname`/`lname`.
        final fullName = '${EmpProfileApi.pick(profile, ['fname'])} ${EmpProfileApi.pick(profile, ['lname'])}'.trim();
        _name = fullName.isNotEmpty ? fullName : EmpProfileApi.pick(profile, ['name', 'staff_name', 'full_name'], fallback: 'Employee');
        _picture = EmpProfileApi.pick(profile, ['picture', 'photo', 'image']);
        _info = {
          'Name': _name,
          "Father's Name": EmpProfileApi.pick(profile, ['father_name']),
          'Gender': EmpProfileApi.pick(profile, ['gender']),
          'Designation': EmpProfileApi.pick(profile, ['designation']),
          'Code': EmpProfileApi.pick(profile, ['emp_id', 'staff_id', 'code']),
          'Mobile Number': EmpProfileApi.pick(profile, ['mobile_no', 'mobile', 'contact']),
          'Email': EmpProfileApi.pick(profile, ['email_address', 'email']),
          // `Staffportal/profileInfo` aliases these columns with capitals
          // (`... emp_qualifications.degree as Qualification, ...
          // departments.dept_name as Department ...` — confirmed live from
          // the endpoint's own session-gated SQL error) — the lookup is
          // case-sensitive, so the capitalized keys must be tried too.
          'Qualification': EmpProfileApi.pick(profile, ['Qualification', 'qualification']),
          'Department': EmpProfileApi.pick(profile, ['Department', 'dept_name', 'department']),
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HamburgerHeader(
        title: 'Employee Portal',
        actions: [
          NotificationBellAction(
            fetchUnseenCount: EmpNotificationApi.fetchUnseenCount,
            builder: (_) => const EmpNotificationsScreen(),
          ),
        ],
      ),
      drawer: const _EmpDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.blueMid))
                : ListView(
                    children: [
                      const SizedBox(height: 16),
                      Center(child: ProfileAvatarCircle(pictureUrl: _picture)),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(_name.isEmpty ? 'Employee' : _name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: _info.entries.map((e) => ProfileInfoRow(label: e.key, value: e.value)).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
          const FooterUrl(),
        ],
      ),
    );
  }
}

class _EmpDrawer extends StatefulWidget {
  const _EmpDrawer();

  @override
  State<_EmpDrawer> createState() => _EmpDrawerState();
}

class _EmpDrawerState extends State<_EmpDrawer> {
  bool _noticesUnread = false;
  String _name = 'Employee';
  String? _picture;

  @override
  void initState() {
    super.initState();
    _checkUnread();
    _loadName();
  }

  Future<void> _loadName() async {
    final staffId = await SessionManager.instance.getEmployeeId();
    final profile = staffId == null ? null : await EmpProfileApi.fetchProfile(staffId: staffId);
    if (!mounted || profile == null) return;
    final name = EmpProfileApi.pick(profile, ['fname', 'name', 'staff_name', 'full_name']);
    final pic = EmpProfileApi.pick(profile, ['emp_picture', 'picture', 'photo', 'image']);
    setState(() {
      if (name.isNotEmpty) _name = name;
      if (pic.isNotEmpty) _picture = pic;
    });
  }

  Future<void> _checkUnread() async {
    final notices = await NoticeApi.fetchEmployeeNotices();
    final unread = await NoticeReadTracker.hasUnread('employee', notices);
    if (mounted) setState(() => _noticesUnread = unread);
  }

  Future<void> _openNotices(BuildContext context) async {
    Navigator.pop(context);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmpNoticeScreen()));
    final notices = await NoticeApi.fetchEmployeeNotices();
    await NoticeReadTracker.markAllRead('employee', notices);
    _checkUnread();
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      showToast(context, 'Unable to open link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.roleGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ProfileAvatarCircle(
                          pictureUrl: _picture,
                          size: 40,
                          borderColor: Colors.white,
                          fallback: Container(
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: Image.asset('assets/Images/appstore.png', width: 26, height: 26),
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          const Text(
                            'EMPLOYEE',
                            style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView(
                  children: [
                    DrawerItemRow(iconPath: 'assets/Images/employeeattend.png', label: 'Attendance', onTap: () => _go(context, const EmpAttendanceScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/leaveRequest.png', label: 'Leave Balance', onTap: () => _go(context, const EmpLeaveBalanceScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/leave-status.png', label: 'Leave Status', onTap: () => _go(context, const EmpLeaveStatusScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/monthlySalary.png', label: 'Salary Slip', onTap: () => _go(context, const EmpSalarySlipScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/Compensation.png', label: 'Compansation Slip', onTap: () => _go(context, const EmpCompSlipScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/Event.png', label: 'Event & Holiday', onTap: () => _go(context, const EmpEventsScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/notifyBoard.png', label: 'Notice Board', showUnreadDot: _noticesUnread, onTap: () => _openNotices(context)),
                    DrawerItemRow(iconPath: 'assets/Images/aboutus.png', label: 'About us', onTap: () => _go(context, const AboutUsScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/contactus.png', label: 'Contact', onTap: () => _go(context, const ContactScreen())),
                    DrawerItemRow(
                      iconPath: 'assets/Images/rateus.png',
                      label: 'Rate Us',
                      onTap: () {
                        Navigator.pop(context);
                        _openUrl(context, 'https://play.google.com/store/apps/details?id=com.smartcampuses.newapp&pcampaignid=web_share');
                      },
                    ),
                    DrawerItemRow(
                      iconPath: 'assets/Images/share.png',
                      label: 'Share',
                      onTap: () {
                        Navigator.pop(context);
                        showFollowModal(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 12),
                child: InkWell(
                  onTap: () async {
                    final ok = await showLogoutModal(context);
                    if (!context.mounted) return;
                    if (ok) {
                      await SessionManager.instance.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/homeMain', (route) => false);
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Icon(Icons.logout, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('END SESSION', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
