import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../../institutes/data/student_affiliation_repository.dart';
import '../../../models/institute.dart';

class StudentAffiliationCard extends StatefulWidget {
  final String uid;
  final bool editable;
  const StudentAffiliationCard({super.key, required this.uid, this.editable = false});

  @override State<StudentAffiliationCard> createState() => _StudentAffiliationCardState();
}

class _StudentAffiliationCardState extends State<StudentAffiliationCard> {
  final _repository = StudentAffiliationRepository.instance;
  Map<String, dynamic> _profile = const {};
  bool _busy = true;
  StreamSubscription<Map<String, dynamic>>? _profileSubscription;

  @override void initState() { super.initState(); _watch(); }
  @override void didUpdateWidget(StudentAffiliationCard oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.uid != widget.uid) _watch(); }
  @override void dispose() { _profileSubscription?.cancel(); super.dispose(); }

  void _watch() {
    _profileSubscription?.cancel();
    if (widget.uid.isEmpty) { setState(() { _profile = const {}; _busy = false; }); return; }
    setState(() => _busy = true);
    _profileSubscription = _repository.watchProfile(widget.uid).listen((profile) {
      if (mounted) setState(() { _profile = profile; _busy = false; });
    }, onError: (_) { if (mounted) setState(() => _busy = false); });
  }

  Future<void> _choose() async {
    await InstituteRepository.instance.load();
    if (!mounted) return;
    final universities = InstituteRepository.instance.items.where((item) => item.type == 'universities').toList();
    if (universities.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No universities are available right now.'))); return; }
    Institute? selected;
    for (final university in universities) {
      if (university.id == _profile['studentInstituteId']) selected = university;
    }
    String? program = (_profile['studentProgram'] ?? '').toString().isEmpty ? null : _profile['studentProgram'].toString();
    bool saving = false;
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        final programs = selected == null ? <MapEntry<String, String>>[] : selected!.programGroups.isNotEmpty
            ? selected!.programGroups.entries.expand((entry) => entry.value.map((name) => MapEntry(name, '${entry.key} • $name'))).toList()
            : selected!.programs.map((name) => MapEntry(name, name)).toList();
        final distinct = <String, String>{for (final item in programs) item.key: item.value}.entries.toList();
        final selectedProgram = distinct.any((item) => item.key == program) ? program : null;
        final selectedInstitute = selected;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Add your university', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
            const SizedBox(height: 8),
            const Text('Your chosen university appears on your profile now. Its representative can review your request for a student verification badge.'),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              key: ValueKey('student-university-${selected?.id ?? 'none'}'),
              initialValue: selected?.id,
              decoration: const InputDecoration(labelText: 'University', border: OutlineInputBorder()),
              isExpanded: true,
              items: universities.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: saving ? null : (id) => setSheetState(() { selected = universities.firstWhere((i) => i.id == id); program = null; }),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey('student-program-${selected?.id ?? 'none'}'),
              initialValue: selectedProgram,
              decoration: const InputDecoration(labelText: 'Program / degree', border: OutlineInputBorder()),
              isExpanded: true,
              items: distinct.map((item) => DropdownMenuItem(value: item.key, child: Text(item.value, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: saving || selectedInstitute == null ? null : (value) => setSheetState(() => program = value),
            ),
            if (distinct.isEmpty && selected != null) const Padding(padding: EdgeInsets.only(top: 8), child: Text('This university has not listed its programs yet.')),
            const SizedBox(height: 18),
            if (_profile['studentVerificationStatus'] == 'approved')
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Saving your university or course sends a new request. The university student badge returns after approval.')),
            FilledButton(
            onPressed: saving || selectedInstitute == null || selectedProgram == null ? null : () async {
                setSheetState(() => saving = true);
                try {
                  await _repository.select(selectedInstitute, selectedProgram);
                  if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                } catch (error) {
                  setSheetState(() => saving = false);
                  if (sheetContext.mounted) ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
                }
              },
              child: Text(saving ? 'Sending request…' : 'Save university'),
            ),
          ])),
        );
      }),
    );
    if (result == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('University added. Verification request sent.')));
  }

  @override Widget build(BuildContext context) {
    if (_busy) return const Card(child: Padding(padding: EdgeInsets.all(18), child: LinearProgressIndicator()));
    final institute = (_profile['studentInstituteName'] ?? '').toString();
    final program = (_profile['studentProgram'] ?? '').toString();
    final status = (_profile['studentVerificationStatus'] ?? 'not_requested').toString();
    final selected = institute.isNotEmpty;
    if (!selected && !widget.editable) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen), const SizedBox(width: 9), Text(widget.editable ? 'My university' : 'University', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen))]), ]),
      if (selected) ...[
        const SizedBox(height: 7),
        Text(institute, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (status == 'approved') const Padding(padding: EdgeInsets.only(top: 6), child: Tooltip(message: 'Student affiliation verified by this university', child: Chip(backgroundColor: AppColors.softGreen, avatar: Text('🎓', style: TextStyle(fontSize: 18)), label: Text('University student')))),
        if (program.isNotEmpty) Text(program, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 5),
        if (widget.editable) Text(switch (status) { 'approved' => 'This university confirmed your student affiliation.', 'pending' => 'Verification request sent. Waiting for the university.', 'rejected' => 'The university could not verify this request. You can update your details and send it again.', _ => 'University selected; verification has not been requested.' }, style: Theme.of(context).textTheme.bodySmall),
      ] else ...[
        const SizedBox(height: 5),
        const Text('Choose your university and program. The university name will show on your profile immediately.'),
      ],
      if (widget.editable) ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: _choose, icon: const Icon(Icons.edit_outlined), label: Text(selected ? 'Choose or update university' : 'Add my university')),
      ],
    ])));
  }
}

class VerifiedStudentCount extends StatefulWidget {
  final String instituteId;
  const VerifiedStudentCount({super.key, required this.instituteId});
  @override State<VerifiedStudentCount> createState() => _VerifiedStudentCountState();
}

class _VerifiedStudentCountState extends State<VerifiedStudentCount> {
  late Future<int> _count;
  @override void initState() { super.initState(); _count = StudentAffiliationRepository.instance.verifiedStudentCount(widget.instituteId); StudentAffiliationRepository.instance.addListener(_changed); }
  @override void didUpdateWidget(VerifiedStudentCount oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.instituteId != widget.instituteId) _reload(); }
  @override void dispose() { StudentAffiliationRepository.instance.removeListener(_changed); super.dispose(); }
  void _changed() => _reload();
  void _reload() { if (mounted) setState(() => _count = StudentAffiliationRepository.instance.verifiedStudentCount(widget.instituteId)); }
  @override Widget build(BuildContext context) => FutureBuilder<int>(
      future: _count,
      builder: (context, snapshot) => Row(children: [
        const Icon(Icons.groups_outlined, color: AppColors.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(snapshot.hasError ? 'Sign in to view verified student count' : '${snapshot.data ?? 0} university-verified students')),
      ]),
    );
}
