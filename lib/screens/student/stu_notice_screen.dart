import 'package:flutter/material.dart';
import '../../services/stu_notice_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

/// Student Notice Board — identical UI to the Faculty/Employee portals'
/// Notice Board screens.
class StuNoticeScreen extends StatefulWidget {
  const StuNoticeScreen({super.key});

  @override
  State<StuNoticeScreen> createState() => _StuNoticeScreenState();
}

class _StuNoticeScreenState extends State<StuNoticeScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  bool _unavailable = false;
  List<StuNotice> _notices = [];

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
    final loaded = await StuNoticeApi.fetchNotices();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (loaded == null) {
        _unavailable = true;
      } else {
        _notices = loaded;
      }
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
                : _unavailable
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Unable to load notices. Please try again later.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 15),
                          ),
                        ),
                      )
                    : _notices.isEmpty
                        ? const Center(child: Text('No notices found.', style: TextStyle(color: Colors.black54)))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: _notices.map((n) => NoticeCard(date: n.date, label: n.title, body: n.body)).toList(),
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
