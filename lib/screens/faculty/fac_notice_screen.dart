import 'package:flutter/material.dart';
import '../../services/fac_notice_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common_widgets.dart';

/// Faculty Notice Board, fetched from the AIT SmartCampuses API. Gated
/// by a real, server-side login session rather than any request
/// parameter, so it only returns data once the user has logged in
/// through this app with genuine, valid Faculty credentials (see
/// [FacNoticeApi]).
class FacNoticeScreen extends StatefulWidget {
  const FacNoticeScreen({super.key});

  @override
  State<FacNoticeScreen> createState() => _FacNoticeScreenState();
}

class _FacNoticeScreenState extends State<FacNoticeScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  bool _unavailable = false;
  List<FacNotice> _notices = [];

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps the board in step with new notices posted on the web portal
    // without the faculty member having to re-open the screen (see
    // AutoRefreshMixin).
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    disposeAutoRefresh();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await FacNoticeApi.fetchNotices();
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
                            'Unable to load notices — this feature requires an active Faculty session, which isn\'t available yet.',
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
