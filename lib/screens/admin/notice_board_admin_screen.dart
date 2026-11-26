import 'package:flutter/material.dart';
import '../../services/notice_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/common_widgets.dart' show NoticeCard;

class NoticeBoardAdminScreen extends StatefulWidget {
  const NoticeBoardAdminScreen({super.key});

  @override
  State<NoticeBoardAdminScreen> createState() => _NoticeBoardAdminScreenState();
}

class _NoticeBoardAdminScreenState extends State<NoticeBoardAdminScreen> {
  late Future<List<Map<String, String>>> _future;

  @override
  void initState() {
    super.initState();
    _future = NoticeApi.fetchAdminNotices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Notice Board'),
            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.maroonBtn));
                  }
                  final notices = snapshot.data ?? [];
                  if (notices.isEmpty) {
                    return const Center(child: Text('No notices found.', style: TextStyle(color: AppColors.muted)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: notices.length,
                    itemBuilder: (ctx, i) => NoticeCard(
                      date: notices[i]['date'] ?? '',
                      label: notices[i]['title'] ?? '',
                      body: notices[i]['body'] ?? '',
                    ),
                  );
                },
              ),
            ),
            const FooterUrl(),
          ],
        ),
      ),
    );
  }
}
