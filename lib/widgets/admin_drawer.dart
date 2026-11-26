import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/admin/academic_calendar_screen.dart';
import '../screens/admin/holidays_screen.dart';
import '../screens/admin/leave_status_admin_screen.dart';
import '../screens/admin/notice_board_admin_screen.dart';
import '../services/notice_api.dart';
import '../services/notice_read_tracker.dart';
import '../services/session_manager.dart';
import '../theme/app_colors.dart';
import 'common.dart';
import 'common_widgets.dart' show AboutUsScreen, ContactScreen, UnreadDot;

class AdminSideDrawer extends StatefulWidget {
  const AdminSideDrawer({super.key});

  @override
  State<AdminSideDrawer> createState() => _AdminSideDrawerState();
}

class _AdminSideDrawerState extends State<AdminSideDrawer> {
  String? _adminName;
  bool _loading = true;
  bool _noticesUnread = false;

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    _checkUnread();
  }

  Future<void> _checkUnread() async {
    final notices = await NoticeApi.fetchAdminNotices();
    final unread = await NoticeReadTracker.hasUnread('admin', notices);
    if (mounted) setState(() => _noticesUnread = unread);
  }

  Future<void> _openNotices() async {
    Navigator.pop(context);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoticeBoardAdminScreen()));
    final notices = await NoticeApi.fetchAdminNotices();
    await NoticeReadTracker.markAllRead('admin', notices);
    _checkUnread();
  }

  Future<void> _loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username');
    if (!mounted) return;
    setState(() {
      _adminName = name;
      _loading = false;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showToast(context, 'Unable to open link');
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.roleGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Image.asset('assets/Images/appstore.png', width: 36, height: 36),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _adminName?.isNotEmpty == true ? _adminName! : 'Admin',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'ADMIN',
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                  _DrawerAction(
                    iconPath: 'assets/Images/Calender.png',
                    label: 'Academic Calender',
                    onTap: () => _navigateTo(const AcademicCalendarScreen()),
                  ),
                  _DrawerAction(
                    iconPath: 'assets/Images/RMS.png',
                    label: 'Leave Status',
                    onTap: () => _navigateTo(const LeaveStatusAdminScreen()),
                  ),
                  _DrawerAction(
                    iconPath: 'assets/Images/notifyBoard.png',
                    label: 'Notice Board',
                    showUnreadDot: _noticesUnread,
                    onTap: _openNotices,
                  ),
                  _DrawerAction(
                    iconPath: 'assets/Images/Holiday.png',
                    label: 'Events & Holidays',
                    onTap: () => _navigateTo(const HolidaysScreen()),
                  ),
                  _DrawerAction(
                    iconPath: 'assets/Images/aboutus.png',
                    label: 'About us',
                    onTap: () => _navigateTo(const AboutUsScreen()),
                  ),
                  _DrawerAction(
                    iconPath: 'assets/Images/contactus.png',
                    label: 'Contact',
                    onTap: () => _navigateTo(const ContactScreen()),
                  ),
                  _DrawerAction(
                    iconPath: 'assets/Images/rateus.png',
                    label: 'Rate Us',
                    onTap: () => _openUrl('https://play.google.com/store/apps/details?id=com.smartcampuses.newapp&pcampaignid=web_share'),
                  ),
                  _DrawerAction(
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
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 16),
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
}

class _DrawerAction extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;
  final bool showUnreadDot;
  const _DrawerAction({required this.iconPath, required this.label, required this.onTap, this.showUnreadDot = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            UnreadDot(show: showUnreadDot, child: Image.asset(iconPath, width: 20, height: 20, color: Colors.white)),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
