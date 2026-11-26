import 'package:flutter/material.dart';
import '../../services/stu_courses_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auto_refresh_mixin.dart';
import '../../widgets/common.dart';

class StuCoursesScreen extends StatefulWidget {
  const StuCoursesScreen({super.key});

  @override
  State<StuCoursesScreen> createState() => _StuCoursesScreenState();
}

class _StuCoursesScreenState extends State<StuCoursesScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  bool _loading = true;
  bool _unavailable = false;
  List<StuCourse> _courses = [];
  int? _selected;

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
    final loaded = await StuCoursesApi.fetchCourses();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (loaded == null) {
        _unavailable = true;
      } else {
        _courses = loaded;
        // Preserve the user's current selection across a background
        // refresh — only reset it if it's unset or now out of range.
        if (_selected == null || _selected! >= loaded.length) {
          _selected = loaded.isEmpty ? null : 0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = _selected != null && _selected! < _courses.length ? _courses[_selected!] : null;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'My Courses', color: AppColors.blueMid),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.blueMid))
                  : _unavailable
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Unable to load courses — this feature requires an active Student session.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        )
                      : _courses.isEmpty
                          ? const Center(child: Text('No enrolled courses found.'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  DarkPillDropdown<int>(
                                    hint: 'Select Course',
                                    value: _selected,
                                    items: List.generate(_courses.length, (i) => i),
                                    labelOf: (i) => _courses[i].name,
                                    onChanged: (i) => setState(() => _selected = i),
                                  ),
                                  const SizedBox(height: 16),
                                  if (course != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blueMid)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.blueMid)),
                                          const Divider(height: 16),
                                          Row(
                                            children: [
                                              Expanded(child: _field('Code:', course.codeId)),
                                              Expanded(child: _field('Class:', course.className)),
                                            ],
                                          ),
                                          const Divider(height: 16),
                                          Row(
                                            children: [
                                              Expanded(child: _field('Credit Hours:', course.creditHours)),
                                              Expanded(child: _field('Teacher:', course.teacherName)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
            ),
            const FooterUrl(),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
            Text(value, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
        ),
      );
}
