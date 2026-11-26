import 'package:flutter/material.dart';
import '../../services/fee_collection_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class FeeCollectionScreen extends StatefulWidget {
  const FeeCollectionScreen({super.key});

  @override
  State<FeeCollectionScreen> createState() => _FeeCollectionScreenState();
}

class _FeeCollectionScreenState extends State<FeeCollectionScreen> {
  FeeDefaulterSummary? _defaulterSummary;
  FeeCollectedSummary? _collectedSummary;

  bool _loadingCampuses = true;
  List<IdName> _campuses = [];
  String? campusId;

  bool _loadingPrograms = false;
  List<IdName> _programs = [];
  String? programId;

  bool _loadingShifts = false;
  List<IdName> _shifts = [];
  String? shiftId;

  bool _loadingYears = false;
  List<FeeYear> _years = [];
  String? classId;
  String? sectionId;

  bool showError = false;
  bool _loading = false;
  bool searched = false;
  FeeCollectionResult? _result;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
    _loadSummaries();
  }

  /// Re-fetches the Fee Paid + Fee Defaulter summary panel, scoped to the
  /// current cascade selection: institute-wide with nothing picked,
  /// program-wide once a Program is chosen, and down to the single Batch
  /// once a Batch is chosen.
  Future<void> _loadSummaries() async {
    final program = programId, batch = shiftId, cls = classId, section = sectionId;
    final results = await Future.wait([
      // Defaulter endpoint only drills to batch level.
      FeeCollectionApi.fetchDefaulterBalance(programId: program, batchId: batch),
      // Collection endpoint drills all the way to Year/Section.
      FeeCollectionApi.fetchCollectionSummary(
        programId: program,
        batchId: batch,
        classId: cls,
        classSectionId: section,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _defaulterSummary = results[0] as FeeDefaulterSummary?;
      _collectedSummary = results[1] as FeeCollectedSummary?;
    });
  }

  Future<void> _loadCampuses() async {
    final campuses = await FeeCollectionApi.fetchCampuses();
    if (!mounted) return;
    setState(() {
      _campuses = campuses;
      _loadingCampuses = false;
    });
  }

  Future<void> _selectCampus(String? id) async {
    setState(() {
      campusId = id;
      programId = shiftId = classId = sectionId = null;
      _programs = _shifts = [];
      _years = [];
      searched = false;
      _loadingPrograms = id != null;
    });
    _loadSummaries(); // campus change clears program → back to global
    if (id == null) return;
    final programs = await FeeCollectionApi.fetchPrograms(id);
    if (!mounted) return;
    setState(() {
      _programs = programs;
      _loadingPrograms = false;
    });
  }

  Future<void> _selectProgram(String? id) async {
    setState(() {
      programId = id;
      shiftId = classId = sectionId = null;
      _shifts = [];
      _years = [];
      searched = false;
      _loadingShifts = id != null;
    });
    _loadSummaries(); // scope the banner to the chosen program
    if (id == null) return;
    final shifts = await FeeCollectionApi.fetchShifts(id);
    if (!mounted) return;
    setState(() {
      _shifts = shifts;
      _loadingShifts = false;
    });
  }

  Future<void> _selectShift(String? id) async {
    setState(() {
      shiftId = id;
      classId = sectionId = null;
      _years = [];
      searched = false;
      _loadingYears = id != null;
    });
    _loadSummaries(); // scope the banner down to the chosen batch
    if (id == null || campusId == null) return;
    final years = await FeeCollectionApi.fetchYears(campusId!, id);
    if (!mounted) return;
    setState(() {
      _years = years;
      _loadingYears = false;
    });
  }

  Future<void> _view() async {
    if (campusId == null || programId == null || shiftId == null || classId == null || sectionId == null) {
      setState(() {
        showError = true;
        searched = false;
      });
      return;
    }
    setState(() {
      showError = false;
      _loading = true;
    });
    final result = await FeeCollectionApi.fetchFeeCollection(
      branchId: campusId!,
      programId: programId!,
      batchId: shiftId!,
      classId: classId!,
      classSectionId: sectionId!,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      searched = true;
      _loading = false;
    });
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  String get _scopeLabel {
    if (programId == null) return 'Institute-wide';
    final program = _programs.firstWhere((p) => p.id == programId, orElse: () => IdName(programId!, programId!)).name;
    if (shiftId == null) return 'Program: $program';
    final batch = _shifts.firstWhere((s) => s.id == shiftId, orElse: () => IdName(shiftId!, shiftId!)).name;
    if (classId == null) return 'Program: $program  •  Batch: $batch';
    final year = _years.firstWhere((y) => y.classId == classId, orElse: () => FeeYear(classId!, classId!, classId!)).name;
    return 'Program: $program  •  Batch: $batch  •  $year';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PgHeader(title: 'Fee Collection'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DarkPillDropdown<String>(
                      hint: _loadingCampuses ? 'Loading...' : 'Select Campus',
                      value: campusId,
                      items: _campuses.map((c) => c.id).toList(),
                      labelOf: (id) => _campuses.firstWhere((c) => c.id == id, orElse: () => IdName(id, id)).name,
                      onChanged: _loadingCampuses ? null : _selectCampus,
                    ),
                    const SizedBox(height: 10),
                    DarkPillDropdown<String>(
                      hint: _loadingPrograms ? 'Loading...' : 'Select Program',
                      value: programId,
                      items: _programs.map((p) => p.id).toList(),
                      labelOf: (id) => _programs.firstWhere((p) => p.id == id, orElse: () => IdName(id, id)).name,
                      onChanged: campusId == null || _loadingPrograms ? null : _selectProgram,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DarkPillDropdown<String>(
                            hint: _loadingShifts ? 'Loading...' : 'Batch',
                            value: shiftId,
                            items: _shifts.map((s) => s.id).toList(),
                            labelOf: (id) => _shifts.firstWhere((s) => s.id == id, orElse: () => IdName(id, id)).name,
                            onChanged: programId == null || _loadingShifts ? null : _selectShift,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DarkPillDropdown<String>(
                            hint: _loadingYears ? 'Loading...' : 'Year',
                            value: classId,
                            items: _years.map((y) => y.classId).toList(),
                            labelOf: (id) => _years.firstWhere((y) => y.classId == id, orElse: () => FeeYear(id, id, id)).name,
                            onChanged: shiftId == null || _loadingYears
                                ? null
                                : (id) {
                                    setState(() {
                                      classId = id;
                                      sectionId = id == null ? null : _years.firstWhere((y) => y.classId == id).sectionId;
                                    });
                                    _loadSummaries(); // scope the Fee Paid banner down to the year
                                  },
                          ),
                        ),
                      ],
                    ),
                    FieldError(message: 'Please select all fields.', show: showError),
                    const SizedBox(height: 14),
                    Center(child: MaroonPillButton(label: _loading ? 'Loading...' : 'View', onPressed: _loading ? () {} : _view)),
                    if (_collectedSummary != null || _defaulterSummary != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        _scopeLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                label: 'Fee Paid',
                                value: _collectedSummary != null ? 'Rs: ${_fmt(_collectedSummary!.totalPaid)}' : '—',
                                sub: _collectedSummary != null
                                    ? '${_fmt(_collectedSummary!.paidStudentCount)} students • ${_fmt(_collectedSummary!.invoiceCount)} invoices'
                                    : null,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryTile(
                                label: 'Fee Defaulter',
                                value: _defaulterSummary != null ? 'Rs: ${_fmt(_defaulterSummary!.balance)}' : '—',
                                sub: _defaulterSummary?.studentCount != null && _defaulterSummary!.studentCount! > 0
                                    ? '${_fmt(_defaulterSummary!.studentCount!)} defaulter students'
                                    : null,
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (searched) ...[
                      const SizedBox(height: 18),
                      if (_result == null)
                        const Text('No fee data found for this selection.', style: TextStyle(color: AppColors.muted))
                      else ...[
                        Row(
                          children: [
                            Expanded(child: StatBlock(label: 'Amount Collected', value: 'Rs: ${_fmt(_result!.amount)}', color: AppColors.orange)),
                            const SizedBox(width: 8),
                            Expanded(child: StatBlock(label: 'Total Students', value: _result!.hasTotalStudents ? '${_result!.totalStudents}' : '—', color: AppColors.green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: StatBlock(label: 'Fee Paid', value: '${_result!.feePaid}', color: AppColors.red)),
                            const SizedBox(width: 8),
                            Expanded(child: StatBlock(label: 'Paid Students', value: _collectedSummary != null ? '${_collectedSummary!.paidStudentCount}' : '—', color: AppColors.blueMid)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        StatBlock(
                          label: 'Defaulter Students',
                          value: _defaulterSummary?.studentCount != null ? '${_defaulterSummary!.studentCount}' : '—',
                          color: AppColors.gold,
                        ),
                      ],
                    ],
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
}

/// A stat tile with an optional third line, matching [StatBlock]'s
/// look — used for the Fee Paid / Fee Defaulter summary tiles which
/// also show a student/invoice count under the amount.
class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;
  const _SummaryTile({required this.label, required this.value, this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
