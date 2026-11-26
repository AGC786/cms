import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models.dart' show CalItem;
import '../theme/app_colors.dart';
import 'common_widgets.dart' show UnreadDot;

export 'common_widgets.dart' show showAppDatePicker;

/// Bottom bar shown on most screens: "www.smartcampuses.com"
class FooterUrl extends StatelessWidget {
  const FooterUrl({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(gradient: AppColors.footerGradient),
      child: const Text(
        'www.smartcampuses.com',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
      ),
    );
  }
}

/// Purple/blue page header with a back chevron ("pg-header-blue")
class PgHeader extends StatelessWidget {
  final String title;
  final Color color;
  final Widget? actions;
  const PgHeader({super.key, required this.title, this.color = AppColors.blueMid, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(6, 14, 16, 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?actions,
        ],
      ),
    );
  }
}

/// Header with a hamburger icon opening a drawer, used on portal home screens.
class HamburgerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const HamburgerHeader({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.blueMid,
      elevation: 0,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A solid dark-blue pill-styled dropdown selector used on Admin's
/// cascading filter screens (Class Schedule / Course Attendance / Fee
/// Collection) — dims to a lighter blue while disabled (its options
/// haven't loaded / a parent field isn't picked yet).
class DarkPillDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?>? onChanged;
  const DarkPillDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.blueDk,
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: items.contains(value) ? value : null,
          hint: Text(hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          dropdownColor: Colors.white,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelOf(item), style: const TextStyle(fontSize: 13, color: AppColors.ink), overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          selectedItemBuilder: (context) => items
              .map((item) => Center(
                    child: Text(
                      labelOf(item),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Dashboard grid tile ("tile" / "ic-circle")
class DashboardTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? emoji;
  final String? assetPath;
  final bool showUnreadDot;
  const DashboardTile({
    super.key,
    required this.label,
    required this.onTap,
    this.emoji,
    this.assetPath,
    this.showUnreadDot = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (assetPath != null) {
      iconWidget = Image.asset(assetPath!, width: 28, height: 28, fit: BoxFit.contain);
    } else {
      iconWidget = Text(emoji ?? '', style: const TextStyle(fontSize: 24));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UnreadDot(
            show: showUnreadDot,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3FA),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// Blue-ringed avatar circle shown at the top of every portal's
/// home/profile screen (Student, Faculty, Employee) — shows the live
/// profile photo when the backend has one, or just the empty outline
/// when it doesn't, matching the reference design across all three.
class ProfileAvatarCircle extends StatelessWidget {
  final String? pictureUrl;
  final double size;
  final Color borderColor;

  /// Shown when there's no picture URL or the image fails to load
  /// (e.g. the AIT logo in the portal drawers).
  final Widget? fallback;
  const ProfileAvatarCircle({
    super.key,
    this.pictureUrl,
    this.size = 88,
    this.borderColor = AppColors.blueMid,
    this.fallback,
  });

  /// The backend sometimes gives a full URL (Faculty's login response
  /// confirmed live: `emp_picture` is already `https://.../img/<file>`)
  /// and sometimes just a bare filename (`picture`, e.g.
  /// `student_0008.png`) — confirmed live that the latter resolves under
  /// `https://campus.smartcampuses.com/demo_institute/img/<file>`, so a bare value is
  /// prefixed with that path.
  static String? _resolve(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    return v.startsWith('http') ? v : 'https://campus.smartcampuses.com/demo_institute/img/$v';
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolve(pictureUrl);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2)),
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback ?? const SizedBox.shrink(),
            ),
    );
  }
}

/// A single "Label : Value" row with a hairline divider underneath, used
/// on the Student/Faculty/Employee portal home screens' profile detail
/// list — identical across all three.
class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const ProfileInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 118, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.ink))),
              const SizedBox(width: 6),
              const Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.ink)),
              const SizedBox(width: 10),
              Expanded(child: Text(value.isEmpty ? 'N/A' : value, style: const TextStyle(fontSize: 13.5, color: AppColors.ink))),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.line),
        ],
      ),
    );
  }
}

/// A single item in the side drawer — a real icon asset (tinted white) on
/// the drawer's blue-to-magenta gradient, matching the Admin portal's
/// original drawer design so every portal's drawer looks identical.
class DrawerItemRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;
  final bool showUnreadDot;
  const DrawerItemRow({super.key, required this.iconPath, required this.label, required this.onTap, this.showUnreadDot = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UnreadDot(show: showUnreadDot, child: Image.asset(iconPath, width: 20, height: 20, color: Colors.white)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.white)),
      onTap: onTap,
    );
  }
}

/// Colored stat block ("stat-block")
class StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatBlock({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Full-width stat card used on single-column summary screens (e.g. the
/// Student Registration summary) — same idea as [StatBlock] but sized to
/// match that screenshot's much larger label/value text.
class StatBlockLarge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatBlockLarge({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Directory result card (person avatar + name + subtitle)
class DirectoryCard extends StatelessWidget {
  final String name;
  final String sub;
  final VoidCallback onTap;
  const DirectoryCard({super.key, required this.name, required this.sub, required this.onTap});

  String get _initials {
    final parts = name.split(' ');
    final chars = parts.take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
    return chars.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: const Color(0xFFF7F7FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.blueMid,
          child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    );
  }
}

/// Shared notification-list row: a small blue bullet, bold title, and a
/// muted date underneath, on a uniform light card — used by every
/// portal's Notifications screen.
class NotificationTile extends StatelessWidget {
  final String title;
  final String date;
  final VoidCallback? onTap;

  /// Shows the blue leading dot only while the item is unread. Once the
  /// row has been seen/marked read, pass `false` and the dot disappears
  /// (the title stays aligned via an equal-width spacer).
  final bool unread;
  const NotificationTile({super.key, required this.title, required this.date, this.onTap, this.unread = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF0F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unread)
              Container(
                margin: const EdgeInsets.only(top: 6, right: 10),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: AppColors.blueMid, shape: BoxShape.circle),
              )
            else
              const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink)),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(date, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Field-style error text shown below inputs.
class FieldError extends StatelessWidget {
  final String message;
  final bool show;
  const FieldError({super.key, required this.message, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(message, style: const TextStyle(color: AppColors.red, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}

/// Compact pill-shaped maroon button, sized to its label (not full width) —
/// used for the "View" / "View Summary" actions under filter forms.
class MaroonPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const MaroonPillButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.maroonBtn,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 20),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

/// Underlined date field: small grey label, bold date value, a round
/// dropdown-chevron affordance, and a hairline underneath — matches the
/// From/To Date fields shown across the admin filter screens.
class UnderlineDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const UnderlineDateField({super.key, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink))),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: AppColors.muted, shape: BoxShape.circle),
                child: const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.line),
        ],
      ),
    );
  }
}

/// A generic result card with a title and label/value rows ("result-box")
class ResultBox extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const ResultBox({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF7F7FB), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.blueMid)),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const ResultRow({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.ink)),
        ],
      ),
    );
  }
}

/// Notice/holiday row ("holiday-row")
/// Calendar entry card (Events/Holidays/Academics) — bordered card with a
/// centered bold title and Start Date/End Date rows, matching
/// [NoticeCard]'s design language. [dates] is either a single date or a
/// `start – end` range (as produced by every calendar API in this app);
/// when there's no range, Start and End both show that one date.
class CalendarEventCard extends StatelessWidget {
  final String title;
  final String dates;
  const CalendarEventCard({super.key, required this.title, required this.dates});

  @override
  Widget build(BuildContext context) {
    final parts = dates.split(' – ');
    final start = parts.isNotEmpty ? parts[0] : dates;
    final end = parts.length > 1 ? parts[1] : start;
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
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF981D5C)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Start Date:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(start, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('End Date:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(end, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loads a list of calendar entries and renders them as
/// [CalendarEventCard]s — the shared body for every Events/Holidays/
/// Academics tab across all four portals.
class CalendarEventList extends StatelessWidget {
  final Future<List<CalItem>> future;
  final String emptyMessage;
  const CalendarEventList({super.key, required this.future, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CalItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.maroonBtn));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.muted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: items.length,
          itemBuilder: (context, i) => CalendarEventCard(title: items[i].title, dates: items[i].dates),
        );
      },
    );
  }
}

/// Simple toast helper using a SnackBar to mirror `toast(msg)` in the JS.
void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

/// Shared "record details" popup (Student Details / Employee Details) —
/// pale pink card, bold label/value rows, and a centered blue "Close"
/// pill — same on every directory-style screen.
Future<void> showDetailsDialog(BuildContext context, {required String title, required List<MapEntry<String, String>> rows}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFFFBEAEF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.ink)),
            const SizedBox(height: 18),
            for (final r in rows) _DetailsDialogRow(label: r.key, value: r.value),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueMid,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailsDialogRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailsDialogRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 118, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.blueMid))),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 13.5, color: AppColors.ink))),
        ],
      ),
    );
  }
}

/// Confirmation modal mirroring "logout-modal" — same on every portal.
Future<bool> showLogoutModal(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFFFBEAEF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to Logout?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.ink),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _LogoutModalButton(label: 'No', onTap: () => Navigator.pop(ctx, false))),
                const SizedBox(width: 16),
                Expanded(child: _LogoutModalButton(label: 'Yes', onTap: () => Navigator.pop(ctx, true))),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

class _LogoutModalButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LogoutModalButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFE1E1E1), borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
      ),
    );
  }
}

/// "Follow us" modal (Rate Us / Share)
void showFollowModal(BuildContext context) {
  Future<void> open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Text('Follow Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            const Text(
              'Stay connected with us on social media!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13.5),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FollowIcon(
                  gradient: const LinearGradient(colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)]),
                  imagePath: 'assets/Images/instagram_1384015.png',
                  onTap: () => open('https://www.instagram.com/'),
                ),
                const SizedBox(width: 14),
                _FollowIcon(
                  color: const Color(0xFF1877F2),
                  imagePath: 'assets/Images/facebook_3670014.png',
                  onTap: () => open('https://www.facebook.com/'),
                ),
                const SizedBox(width: 14),
                _FollowIcon(
                  color: const Color(0xFF0A66C2),
                  imagePath: 'assets/Images/linkedin_1384014.png',
                  onTap: () => open('https://www.linkedin.com/'),
                ),
                const SizedBox(width: 14),
                _FollowIcon(
                  color: Colors.black,
                  imagePath: 'assets/Images/twitter_3669691.png',
                  onTap: () => open('https://www.x.com/'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _FollowIcon extends StatelessWidget {
  final Color? color;
  final Gradient? gradient;
  final String imagePath;
  final VoidCallback onTap;
  const _FollowIcon({this.color, this.gradient, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: color, gradient: gradient, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Image.asset(imagePath, width: 22, height: 22, color: Colors.white, fit: BoxFit.contain),
      ),
    );
  }
}
