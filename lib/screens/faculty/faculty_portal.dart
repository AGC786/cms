import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/fac_notice_api.dart';
import '../../services/fac_notification_api.dart';
import '../../services/fac_profile_api.dart';
import '../../services/notice_read_tracker.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart' show AboutUsScreen, ContactScreen, NotificationBellAction;
import 'fac_attendance_screen.dart';
import 'fac_student_attendance_screen.dart';
import 'fac_timetable_screen.dart';
import 'fac_salary_slip_screen.dart';
import 'fac_leave_balance_screen.dart';
import 'fac_leave_status_screen.dart';
import 'fac_calendar_screen.dart';
import 'fac_notice_screen.dart';
import 'fac_notifications_screen.dart';

class FacultyPortal extends StatefulWidget {
  const FacultyPortal({super.key});

  @override
  State<FacultyPortal> createState() => _FacultyPortalState();
}

class _FacultyPortalState extends State<FacultyPortal> {
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
    final profile = await FacProfileApi.fetchProfile();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (profile != null) {
        // `Teacherportal/username2` confirmed live: no single name field
        // — `name` is actually the institute's own name (a join
        // collision, blocked by [FacProfileApi.pick]'s institute-name
        // filter regardless), the real name is `fname`+`lname`
        // ("Syeda Javeria "+"Gulshan").
        final fullName = '${FacProfileApi.pick(profile, ['fname'])} ${FacProfileApi.pick(profile, ['lname'])}'.trim();
        _name = fullName.isNotEmpty ? fullName : FacProfileApi.pick(profile, ['teacher_name', 'full_name', 'name'], fallback: 'Faculty');
        // `emp_picture` (confirmed live: already a full URL) wins over
        // the bare `picture` filename when both are present.
        _picture = FacProfileApi.pick(profile, ['emp_picture', 'picture', 'photo', 'image']);
        _info = {
          'Name': _name,
          "Father's Name": FacProfileApi.pick(profile, ['father_name']),
          'Gender': FacProfileApi.pick(profile, ['gender']),
          'Designation': FacProfileApi.pick(profile, ['designation']),
          'Code': FacProfileApi.pick(profile, ['emp_id', 'teacher_id', 'code']),
          'Mobile Number': FacProfileApi.pick(profile, ['mobile_no', 'mobile', 'contact']),
          'Email': FacProfileApi.pick(profile, ['email_address', 'email']),
          'Qualification': FacProfileApi.pick(profile, ['Qualification', 'qualification']),
          'Department': FacProfileApi.pick(profile, ['Department', 'dept_name', 'department']),
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HamburgerHeader(
        title: 'Faculty Portal',
        actions: [
          NotificationBellAction(
            fetchUnseenCount: FacNotificationApi.fetchUnseenCount,
            builder: (_) => const FacNotificationsScreen(),
          ),
        ],
      ),
      drawer: const _FacDrawer(),
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
                        child: Text(_name.isEmpty ? 'Faculty' : _name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

class _FacDrawer extends StatefulWidget {
  const _FacDrawer();

  @override
  State<_FacDrawer> createState() => _FacDrawerState();
}

class _FacDrawerState extends State<_FacDrawer> {
  bool _noticesUnread = false;
  String _name = 'Faculty';
  String? _picture;

  @override
  void initState() {
    super.initState();
    _checkUnread();
    _loadName();
  }

  Future<void> _loadName() async {
    final profile = await FacProfileApi.fetchProfile();
    if (!mounted || profile == null) return;
    final name = FacProfileApi.pick(profile, ['fname', 'name', 'teacher_name', 'full_name']);
    final pic = FacProfileApi.pick(profile, ['emp_picture', 'picture', 'photo', 'image']);
    setState(() {
      if (name.isNotEmpty) _name = name;
      if (pic.isNotEmpty) _picture = pic;
    });
  }

  Future<void> _checkUnread() async {
    final notices = await FacNoticeApi.fetchNotices();
    if (notices == null) return;
    final asMaps = notices.map((n) => {'date': n.date, 'title': n.title, 'body': n.body}).toList();
    final unread = await NoticeReadTracker.hasUnread('faculty', asMaps);
    if (mounted) setState(() => _noticesUnread = unread);
  }

  Future<void> _openNotices(BuildContext context) async {
    Navigator.pop(context);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FacNoticeScreen()));
    final notices = await FacNoticeApi.fetchNotices();
    if (notices != null) {
      final asMaps = notices.map((n) => {'date': n.date, 'title': n.title, 'body': n.body}).toList();
      await NoticeReadTracker.markAllRead('faculty', asMaps);
    }
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
                            'FACULTY',
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
                    DrawerItemRow(iconPath: 'assets/Images/Attendance.png', label: 'My Attendance', onTap: () => _go(context, const FacAttendanceScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/Students.png', label: 'Student Attendance', onTap: () => _go(context, const FacStudentAttendanceScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/schedule.png', label: 'Time Table', onTap: () => _go(context, const FacTimetableScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/monthlySalary.png', label: 'Salary Slip', onTap: () => _go(context, const FacSalarySlipScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/leaveRequest.png', label: 'Leave Balance', onTap: () => _go(context, const FacLeaveBalanceScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/leave-status.png', label: 'Leave Status', onTap: () => _go(context, const FacLeaveStatusScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/Event.png', label: 'Event & Holiday', onTap: () => _go(context, const FacCalendarScreen())),
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
