import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models.dart' show CalItem;
import '../services/contact_api.dart';
import '../theme.dart';
import 'common.dart' show PgHeader, FooterUrl, showToast, CalendarEventList;

/// Wraps [child] (typically a notice/notification icon) with a small red
/// dot in the top-right corner when [show] is true — the unread-notice
/// indicator used across every portal's Notice Board entry point.
class UnreadDot extends StatelessWidget {
  final Widget child;
  final bool show;
  const UnreadDot({super.key, required this.child, required this.show});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (show)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// A bell icon (for a portal home screen's AppBar) that fetches its
/// unread-notification count once on mount and shows it as a small
/// circular badge (capped at "9+") — tapping it navigates to
/// [builder]'s screen. Each portal passes its own `fetchUnseenCount`
/// and destination screen.
class NotificationBellAction extends StatefulWidget {
  final Future<int> Function() fetchUnseenCount;
  final WidgetBuilder builder;
  const NotificationBellAction({super.key, required this.fetchUnseenCount, required this.builder});

  @override
  State<NotificationBellAction> createState() => _NotificationBellActionState();
}

class _NotificationBellActionState extends State<NotificationBellAction> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await widget.fetchUnseenCount();
    if (mounted) setState(() => _count = count);
  }

  Future<void> _open() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: widget.builder));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _open,
        ),
        if (_count > 0)
          Positioned(
            right: 4,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text(
                _count > 9 ? '9+' : '$_count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

/// A single tile used in the role-select screen and dashboard grids.
class MenuTile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final bool circleBackground;
  const MenuTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.circleBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (circleBackground)
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22, color: AppColors.blueDark)),
            )
          else
            Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// The floating diagonal-gradient panel used for role-select and the
/// dashboard icon grid, with the footer URL baked into the bottom.
class GradientPanel extends StatelessWidget {
  final Widget child;
  const GradientPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: AppColors.panelGradient,
      ),
      child: child,
    );
  }
}

/// Header showing the AIT crest + wordmark, used above gradient panels.
class AitLogoHeader extends StatelessWidget {
  final double size;
  const AitLogoHeader({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: Color(0xFF1C7A3D), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('🌴', style: TextStyle(fontSize: size * 0.4)),
        ),
        const SizedBox(height: 6),
        const Text('CMS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0E6B34))),
        const Text('Campus Management System', style: TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }
}

/// Standard app bar used across inner screens (purple or blue variant).
PreferredSizeWidget gradientAppBar(BuildContext context, String title, {bool blue = false}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(58),
    child: Container(
      decoration: BoxDecoration(gradient: blue ? AppColors.blueHeaderGradient : AppColors.purpleHeaderGradient),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    ),
  );
}

class DrawerItemData {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const DrawerItemData(this.emoji, this.label, this.onTap);
}

/// Blue side drawer reused for Admin / Employee / Faculty / Student.
class AppSideDrawer extends StatelessWidget {
  final String avatarSeed;
  final String name;
  final List<DrawerItemData> items;
  final VoidCallback onLogout;
  const AppSideDrawer({
    super.key,
    required this.avatarSeed,
    required this.name,
    required this.items,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.blueMid,
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white30)),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Text(name.isNotEmpty ? name[0] : '?')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: items
                    .map((it) => ListTile(
                          leading: Text(it.emoji, style: const TextStyle(fontSize: 18)),
                          title: Text(it.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                          onTap: it.onTap,
                        ))
                    .toList(),
              ),
            ),
            const Divider(color: Colors.white30, height: 1),
            ListTile(
              leading: const Text('🚪', style: TextStyle(fontSize: 18)),
              title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom footer bar with the site URL, used on list-style detail screens.
class FooterUrlBar extends StatelessWidget {
  const FooterUrlBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(gradient: AppColors.footerGradient),
      child: const Text('www.smartcampuses.com',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

/// A labeled stat block used across attendance / registration screens.
class StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatBlock({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

/// Bottom gradient footer bar used as a `bottomNavigationBar` on the
/// Faculty portal's live-data screens — same look as [FooterUrlBar],
/// which is used inline in a body [Column] instead.
class GradientFooterBar extends StatelessWidget {
  const GradientFooterBar({super.key});
  @override
  Widget build(BuildContext context) => const FooterUrlBar();
}

/// Bottom footer bar used inline at the end of a body [Column] on the
/// Faculty portal's live-data screens — same look as [FooterUrlBar].
class SmartCampusesFooter extends StatelessWidget {
  const SmartCampusesFooter({super.key});
  @override
  Widget build(BuildContext context) => const FooterUrlBar();
}

/// Purple page header used on the Faculty portal's live-data screens,
/// with an optional trailing [actions] widget (e.g. a "Mark all as
/// read" button) alongside the back chevron and title.
class RnPageHeader extends StatelessWidget {
  final String title;
  final Widget? actions;
  const RnPageHeader({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) => PgHeader(title: title, color: AppColors.blueMid, actions: actions);
}

/// A single Notice Board entry card (date, title, body).
class NoticeCard extends StatelessWidget {
  final String date;
  final String label;
  final String body;
  const NoticeCard({super.key, required this.date, required this.label, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF981D5C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF981D5C)),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Date: $date', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(body, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
            ),
          ],
        ],
      ),
    );
  }
}

/// One row of [LeaveBalanceTable]: a leave type plus its total/remaining
/// day counts.
class LeaveBalanceTableRow {
  final String title;
  final num total;
  final num remaining;

  /// The backend's own "Availed" figure (what the web portal shows).
  /// `null` when the backend sent nothing — the table then derives it as
  /// `total - remaining`.
  final num? avail;
  const LeaveBalanceTableRow({required this.title, required this.total, required this.remaining, this.avail});
}

String _leaveNum(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

/// Per-leave-type balance table (Leaves / Total / Avail / Remaining
/// columns) — light grey header row, hairline row dividers, no cell
/// borders. `Avail` is the backend's own figure, falling back to
/// `total - remaining` when it isn't provided.
class LeaveBalanceTable extends StatelessWidget {
  final List<LeaveBalanceTableRow> rows;
  const LeaveBalanceTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.7), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.3)},
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF2F2F6)),
            children: [
              _LeaveBalHeaderCell('Leaves', alignLeft: true),
              _LeaveBalHeaderCell('Total'),
              _LeaveBalHeaderCell('Avail'),
              _LeaveBalHeaderCell('Remaining'),
            ],
          ),
          for (final r in rows)
            TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              children: [
                _LeaveBalCell(r.title, alignLeft: true, bold: true),
                _LeaveBalCell(_leaveNum(r.total)),
                _LeaveBalCell(_leaveNum(r.avail ?? (r.total - r.remaining))),
                _LeaveBalCell(_leaveNum(r.remaining)),
              ],
            ),
        ],
      ),
    );
  }
}

class _LeaveBalHeaderCell extends StatelessWidget {
  final String text;
  final bool alignLeft;
  const _LeaveBalHeaderCell(this.text, {this.alignLeft = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Text(text, textAlign: alignLeft ? TextAlign.left : TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
      );
}

class _LeaveBalCell extends StatelessWidget {
  final String text;
  final bool alignLeft;
  final bool bold;
  const _LeaveBalCell(this.text, {this.alignLeft = false, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Text(
          text,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
      );
}

/// A full-width blue pill-shaped action button.
class BluePillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const BluePillButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueMid,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}

/// A labeled tappable date field ("From"/"To" style), showing the
/// currently selected date and opening a date picker on tap.
class DateFieldRow extends StatelessWidget {
  final String label;
  final String formattedDate;
  final VoidCallback onTap;
  const DateFieldRow({super.key, required this.label, required this.formattedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate, style: const TextStyle(fontSize: 12)),
                const Icon(Icons.calendar_today, size: 14, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A month grid of dots (present/absent/leave), one dot per day, used by
/// the Faculty attendance calendar.
class AttendanceMonthGrid extends StatelessWidget {
  final int daysInMonth;
  final int firstWeekday;
  final Color Function(int day) colorForDay;

  /// When true, renders each day as a black date number with a small dot
  /// underneath (Faculty/Employee attendance calendars) instead of a
  /// filled colored circle (Student attendance calendar's original look).
  final bool dotStyle;
  const AttendanceMonthGrid({
    super.key,
    required this.daysInMonth,
    required this.firstWeekday,
    required this.colorForDay,
    this.dotStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: dotStyle ? 1.1 : 1,
      children: [
        for (final d in ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
          Center(child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted))),
        for (int i = 0; i < firstWeekday; i++) const SizedBox.shrink(),
        for (int day = 1; day <= daysInMonth; day++)
          if (dotStyle)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 3),
                Container(width: 5, height: 5, decoration: BoxDecoration(color: colorForDay(day), shape: BoxShape.circle)),
              ],
            )
          else
            Container(
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colorForDay(day), shape: BoxShape.circle),
              child: Text(
                '$day',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorForDay(day) == Colors.transparent ? AppColors.ink : Colors.white),
              ),
            ),
      ],
    );
  }
}

/// Shared "About Us" content shown from every portal's drawer — same
/// hero-header design and copy the Admin portal originally shipped
/// with, so all four portals show identical content.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar(context, 'About Us', blue: true),
      resizeToAvoidBottomInset: false,
      body: const Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About CMS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF981D5C))),
                    SizedBox(height: 12),
                    Text(
                      'The Campus Management System (CMS) is a comprehensive platform designed to streamline and enhance the management of educational institutions. It offers a wide range of features to support administrative tasks, student records, and academic operations.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.6),
                    ),
                    SizedBox(height: 20),
                    Text('Vision', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF981D5C))),
                    SizedBox(height: 12),
                    Text(
                      'Aspire to establish a centre of excellence recognized for the propagation of contemporary knowledge in the field of science and technology.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.6),
                    ),
                    SizedBox(height: 20),
                    Text('Mission', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF981D5C))),
                    SizedBox(height: 12),
                    Text(
                      'To meet the growing challenges in the new millennium by providing required skills in advanced technologies. Impart education of the highest standard through value based holistic teaching and learning by integrating traditional and innovative practices.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FooterUrl(),
        ],
      ),
    );
  }
}

/// Shared "Contact Us" screen for every portal's drawer — same
/// hero-header design as [AboutUsScreen] and the Admin portal, wired to
/// the real `mobile_app/contact` submit endpoint ([ContactApi]) instead
/// of just simulating a send locally.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final msgCtrl = TextEditingController();
  bool _sending = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      showToast(context, 'Unable to open link');
    }
  }

  void _openMap() {
    const location =
        'AG Consultraining Pvt. Ltd., Suite 401, 4th Floor, Crown Square, 13/B Main University Rd, near Usamania Restaurant, Gulshan 13-B Block 13 B Gulshan-e-Iqbal, Karachi, Sindh 75300, Pakistan';
    _openUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
  }

  void _call() => _openUrl('tel:+923332233287');
  void _email() => _openUrl('mailto:sales@smartcampuses.com');

  Future<void> _send() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final msg = msgCtrl.text.trim();
    final emailValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (name.isEmpty || !emailValid || msg.isEmpty) {
      setState(() {
        _error = 'Please fill in all fields with a valid email.';
        _sent = false;
      });
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final success = await ContactApi.send(name: name, email: email, message: msg);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (success) {
        _sent = true;
        nameCtrl.clear();
        emailCtrl.clear();
        msgCtrl.clear();
      } else {
        _error = 'Unable to send your message right now. Please try again later.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar(context, 'Contact Us', blue: true),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ContactIconButton(icon: Icons.location_pin, onTap: _openMap),
                      const SizedBox(width: 12),
                      _ContactIconButton(icon: Icons.email, onTap: _email),
                      const SizedBox(width: 12),
                      _ContactIconButton(icon: Icons.phone, onTap: _call),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Quick Contact', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black)),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Your Name',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Your Email',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Your Message',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF981D5C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Send', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_sent)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        "✅ Message sent! We'll get back to you soon.",
                        style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const FooterUrl(),
        ],
      ),
    );
  }
}

class _ContactIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ContactIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(color: Color(0xFF981D5C), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}


/// Shared Events/Holidays/Academics tabbed screen — fed by whichever
/// portal-specific calendar API the caller already fetched (Faculty,
/// Employee, and Student portals each build their own three futures and
/// hand them to this one shared screen).
class EventsHolidayScreen extends StatelessWidget {
  final Future<List<CalItem>> eventsFuture;
  final Future<List<CalItem>> holidaysFuture;
  final Future<List<CalItem>> academicsFuture;
  const EventsHolidayScreen({
    super.key,
    required this.eventsFuture,
    required this.holidaysFuture,
    required this.academicsFuture,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const PgHeader(title: 'Events & Holidays', color: AppColors.blueMid),
              const TabBar(
                labelColor: AppColors.purple,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.purple,
                tabs: [Tab(text: 'Events'), Tab(text: 'Holidays'), Tab(text: 'Academics')],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    CalendarEventList(future: eventsFuture, emptyMessage: 'No events found.'),
                    CalendarEventList(future: holidaysFuture, emptyMessage: 'No holidays found.'),
                    CalendarEventList(future: academicsFuture, emptyMessage: 'No academic dates found.'),
                  ],
                ),
              ),
              const FooterUrl(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dark calendar look shared by every portal's date picker
/// (admin / student / faculty / employee): charcoal surface, teal
/// accent on the selected day and the CANCEL / OK actions.
const Color _dpSurface = Color(0xFF4A4A4A);
const Color _dpAccent = Color(0xFF3DD6C4);

ThemeData _darkDatePickerTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: _dpAccent,
      onPrimary: Color(0xFF10201E),
      surface: _dpSurface,
      onSurface: Colors.white,
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: _dpSurface,
      headerBackgroundColor: _dpSurface,
      headerForegroundColor: Colors.white,
      weekdayStyle: TextStyle(color: Colors.white60, fontSize: 12),
      dayStyle: TextStyle(color: Colors.white),
      yearStyle: TextStyle(color: Colors.white),
      todayForegroundColor: WidgetStatePropertyAll(_dpAccent),
      todayBorder: BorderSide(color: _dpAccent),
      surfaceTintColor: Colors.transparent,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _dpAccent),
    ),
  );
}

/// Thin wrapper around [showDatePicker] used by **all four portals'**
/// date pickers — applies the shared dark calendar theme and this
/// app's date-range conventions.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  bool Function(DateTime day)? selectableDayPredicate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    selectableDayPredicate: selectableDayPredicate,
    builder: (context, child) => Theme(data: _darkDatePickerTheme(context), child: child!),
  );
}
