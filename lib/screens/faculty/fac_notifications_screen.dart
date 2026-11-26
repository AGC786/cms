import 'package:flutter/material.dart';
import '../../services/fac_notification_api.dart';
import '../../theme.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../utils/concurrency.dart';
import '../../widgets/common.dart' show NotificationTile;
import '../../widgets/common_widgets.dart';

/// Faculty portal's live notification list, backed by
/// `Teacherportal/get_notifications` (session-gated — the PHP session
/// the login cookie carries already identifies the faculty member
/// server-side, so no extra params are sent from the app). Tapping an
/// unseen row marks it seen via `Teacherportal/mark_seen`.
class FacNotificationsScreen extends StatefulWidget {
  const FacNotificationsScreen({super.key});

  @override
  State<FacNotificationsScreen> createState() => _FacNotificationsScreenState();
}

class _FacNotificationsScreenState extends State<FacNotificationsScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  List<FacNotification> _items = [];
  bool _loading = true;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _reload();
    // Keeps the list in step with the web portal without a manual
    // refresh (see AutoRefreshMixin) — uses the silent [_refresh] so it
    // never flashes the full-screen spinner over an already-shown list.
    startAutoRefresh(_refresh);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  /// First load / pull-to-refresh — shows the spinner while there's
  /// nothing on screen yet.
  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    await _refresh();
  }

  /// Silent poll — swaps the data in when it arrives, no spinner.
  Future<void> _refresh() async {
    final list = await FacNotificationApi.fetchNotifications();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    if (_marking) return;
    final unseen = _items.where((n) => !n.seen).toList();
    if (unseen.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No unread notifications.')));
      return;
    }
    setState(() => _marking = true);
    try {
      // Batched, not all-at-once: firing hundreds of concurrent requests
      // (accounts here can have 100+ unread) saturates the connection
      // pool, which both feels stuck and can silently leave some items
      // unmarked on the backend — see `runInBatches`.
      await runInBatches(unseen, (n) => FacNotificationApi.markSeen(n.id));
      final list = await FacNotificationApi.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = list;
        _marking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _marking = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not mark notifications as read. Please try again.')));
    }
  }

  void _onTap(FacNotification n) {
    if (!n.seen) {
      FacNotificationApi.markSeen(n.id);
      setState(() {
        _items = [
          for (final item in _items)
            if (item.id == n.id)
              FacNotification(id: item.id, title: item.title, message: item.message, date: item.date, link: item.link, seen: true)
            else
              item,
        ];
      });
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(n.title),
        content: Text(n.message.isEmpty ? 'No further details.' : n.message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            RnPageHeader(
              title: 'Notifications',
              actions: TextButton(
                onPressed: _marking ? null : _markAllAsRead,
                child: _marking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                      )
                    : const Text('Mark all as read', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('No notifications yet', style: TextStyle(color: AppColors.muted))),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final n = _items[i];
                              return NotificationTile(title: n.title, date: n.date, unread: !n.seen, onTap: () => _onTap(n));
                            },
                          ),
              ),
            ),
            const SmartCampusesFooter(),
          ],
        ),
      ),
    );
  }
}
