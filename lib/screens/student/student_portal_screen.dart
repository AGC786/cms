import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/notice_read_tracker.dart';
import '../../services/stu_notice_api.dart';
import '../../services/stu_notification_api.dart';
import '../../services/stu_profile_api.dart';
import '../../services/session_manager.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart' show AboutUsScreen, ContactScreen, NotificationBellAction;
import 'stu_attendance_screen.dart';
import 'stu_courses_screen.dart';
import 'stu_fee_screen.dart';
import 'stu_exam_screen.dart';
import 'stu_events_screen.dart';
import 'stu_notice_screen.dart';
import 'stu_notifications_screen.dart';
import 'stu_class_schedule_screen.dart';

class StudentPortalScreen extends StatefulWidget {
  const StudentPortalScreen({super.key});

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
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
    final profile = await StuProfileApi.fetchProfile();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (profile != null) {
        // `Studentportal/studentportal23` field names confirmed live
        // against a real authenticated response: `fname` (full name, one
        // field — `lname` is separate but often blank), `father_fname`
        // (Father's Name — top-level `father_name` doesn't exist at all),
        // `date_of_birth`, `gender`, `parmanent_id` (GR No), `s_name`
        // (Program, from the joined `session` table), `class_name` (Year).
        // `mobile_number` is NOT the student's own contact — confirmed
        // live to be a duplicate of `father_mobile` from the joined
        // `parents` table; the student's real number is `student_mobile`.
        _name = StuProfileApi.pick(profile, ['fname', 'name', 'student_name', 'Student_name', 'full_name'], fallback: 'Student');
        _picture = StuProfileApi.pick(profile, ['picture', 'photo', 'image']);
        _info = {
          'Name': _name,
          "Father's Name": StuProfileApi.pick(profile, ['father_fname', 'father_name', 'Father_Name', 'FatherName', 'guardian_fname']),
          'Gender': StuProfileApi.pick(profile, ['gender']),
          'Program': StuProfileApi.pick(profile, ['s_name', 'program', 'course_name', 'program_name']),
          'GR No': StuProfileApi.pick(profile, ['parmanent_id', 'gr_no', 'grno']),
          'Year': StuProfileApi.pick(profile, ['class_name', 'year', 'batch_year']),
          'Date of Birth': StuProfileApi.pick(profile, ['date_of_birth', 'dob']),
          'Contact': StuProfileApi.pick(profile, ['student_mobile', 'mobile_number', 'mobile_no', 'mobile', 'contact']),
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HamburgerHeader(
        title: 'Student Portal',
        actions: [
          NotificationBellAction(
            fetchUnseenCount: StuNotificationApi.fetchUnseenCount,
            builder: (_) => const StuNotificationsScreen(),
          ),
        ],
      ),
      drawer: const _StuDrawer(),
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
                        child: Text(_name.isEmpty ? 'Student' : _name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

class _StuDrawer extends StatefulWidget {
  const _StuDrawer();

  @override
  State<_StuDrawer> createState() => _StuDrawerState();
}

class _StuDrawerState extends State<_StuDrawer> {
  bool _noticesUnread = false;
  String _name = 'Student';
  String? _picture;

  @override
  void initState() {
    super.initState();
    _checkUnread();
    _loadName();
  }

  Future<void> _loadName() async {
    final profile = await StuProfileApi.fetchProfile();
    if (!mounted || profile == null) return;
    final name = StuProfileApi.pick(profile, ['fname', 'name', 'student_name', 'full_name']);
    final pic = StuProfileApi.pick(profile, ['picture', 'photo', 'image']);
    setState(() {
      if (name.isNotEmpty) _name = name;
      if (pic.isNotEmpty) _picture = pic;
    });
  }

  Future<void> _checkUnread() async {
    final notices = await _fetchNoticeMaps();
    final unread = await NoticeReadTracker.hasUnread('student', notices);
    if (mounted) setState(() => _noticesUnread = unread);
  }

  Future<void> _openNotices(BuildContext context) async {
    Navigator.pop(context);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StuNoticeScreen()));
    final notices = await _fetchNoticeMaps();
    await NoticeReadTracker.markAllRead('student', notices);
    _checkUnread();
  }

  Future<List<Map<String, String>>> _fetchNoticeMaps() async {
    final loaded = await StuNoticeApi.fetchNotices();
    if (loaded == null) return [];
    return loaded.map((n) => {'date': n.date, 'title': n.title, 'body': n.body}).toList();
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
                            'STUDENT',
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
                    DrawerItemRow(iconPath: 'assets/Images/Attendance.png', label: 'Attendance', onTap: () => _go(context, const StuAttendanceScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/course.png', label: 'My Courses', onTap: () => _go(context, const StuCoursesScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/feesCollection.png', label: 'Fees Challan', onTap: () => _go(context, const StuFeeScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/quiz.png', label: 'Exam Schedule', onTap: () => _go(context, const StuExamScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/Event.png', label: 'Events & Holiday', onTap: () => _go(context, const StuEventsScreen())),
                    DrawerItemRow(iconPath: 'assets/Images/notifyBoard.png', label: 'Notice Board', showUnreadDot: _noticesUnread, onTap: () => _openNotices(context)),
                    DrawerItemRow(iconPath: 'assets/Images/schedule.png', label: 'Class Schedule', onTap: () => _go(context, const StuClassScheduleScreen())),
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
