import 'package:flutter/material.dart';
import '../../services/notice_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

/// Employee Notice Board — identical UI to the Faculty/Student portals'
/// Notice Board screens.
class EmpNoticeScreen extends StatefulWidget {
  const EmpNoticeScreen({super.key});

  @override
  State<EmpNoticeScreen> createState() => _EmpNoticeScreenState();
}

class _EmpNoticeScreenState extends State<EmpNoticeScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  List<Map<String, String>> _notices = [];

  @override
  void initState() {
    super.initState();
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await NoticeApi.fetchEmployeeNotices();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _notices = loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
        children: [
          const RnPageHeader(title: 'Notice Board'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.blueMid))
                : _notices.isEmpty
                    ? const Center(child: Text('No notices found.', style: TextStyle(color: Colors.black54)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: _notices
                              .map((n) => NoticeCard(date: n['date'] ?? '', label: n['title'] ?? '', body: n['body'] ?? ''))
                              .toList(),
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
