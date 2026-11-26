import 'package:flutter/material.dart';
import '../../services/academic_calendar_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  bool _loading = true;
  List<Map<String, String>> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await AcademicCalendarApi.fetchEvents();
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Academic Calendar'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.maroonBtn))
                  : _events.isEmpty
                      ? const Center(child: Text('No academic calendar events found.'))
                      : ListView(
                          padding: const EdgeInsets.all(14),
                          children: _events.map((event) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF981D5C)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    event['title'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF981D5C)),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Start Date:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      Text(event['start_date'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('End Date:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      Text(event['end_date'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const FooterUrl(),
          ],
        ),
      ),
    );
  }
}
