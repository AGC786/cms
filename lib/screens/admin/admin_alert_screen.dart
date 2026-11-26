import 'package:flutter/material.dart';
import '../../services/alert_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class AdminAlertScreen extends StatefulWidget {
  const AdminAlertScreen({super.key});

  @override
  State<AdminAlertScreen> createState() => _AdminAlertScreenState();
}

class _AdminAlertScreenState extends State<AdminAlertScreen> {
  bool _loading = true;
  List<Map<String, String>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final alerts = await AlertApi.fetchAlerts();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _alerts = alerts;
    });
  }

  void _markAllRead() {
    AlertApi.markAllReadLocally(_alerts);
    setState(() {
      _alerts = _alerts.map((a) => {...a, 'status': 'Read'}).toList();
    });
  }

  void _openAlert(Map<String, String> alert) {
    if (alert['status'] == 'Unread') {
      AlertApi.markReadLocally(alert);
      setState(() {
        _alerts = _alerts.map((a) => a == alert ? {...a, 'status': 'Read'} : a).toList();
      });
    }
    final title = alert['subject']?.isNotEmpty == true ? alert['subject']! : 'Alert';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(alert['content']?.isNotEmpty == true ? alert['content']! : 'No further details.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PgHeader(
              title: 'Alerts',
              actions: !_loading && _alerts.isNotEmpty
                  ? TextButton(
                      onPressed: _markAllRead,
                      child: const Text('Mark all as read', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    )
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAlerts,
                child: _loading
                    ? SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildLoadingContent())
                    : _alerts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('No alerts yet', style: TextStyle(color: AppColors.muted))),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: _buildAlertItems(),
                          ),
              ),
            ),
            const FooterUrl(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Column(
      children: [
        _AlertSkeleton(),
        SizedBox(height: 12),
        _AlertSkeleton(),
        SizedBox(height: 12),
        _AlertSkeleton(),
      ],
    );
  }

  List<Widget> _buildAlertItems() {
    return _alerts.map((alert) {
      final title = alert['subject']?.isNotEmpty == true ? alert['subject']! : 'Alert';
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NotificationTile(
          title: title,
          date: alert['date'] ?? '',
          unread: alert['status'] == 'Unread',
          onTap: () => _openAlert(alert),
        ),
      );
    }).toList();
  }
}

class _AlertSkeleton extends StatelessWidget {
  const _AlertSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 14, width: 80, color: Colors.black12),
          const SizedBox(height: 14),
          Container(height: 14, color: Colors.black12),
          const SizedBox(height: 10),
          Container(height: 14, width: double.infinity, color: Colors.black12),
        ],
      ),
    );
  }
}
