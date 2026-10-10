import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/searchable_choice.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
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
  bool _failed = false;
  StreamSubscription<Map<String, dynamic>>? _profileSubscription;

  @override void initState() { super.initState(); _watch(); }
  @override void didUpdateWidget(StudentAffiliationCard oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.uid != widget.uid) _watch(); }
  @override void dispose() { _profileSubscription?.cancel(); super.dispose(); }

  void _watch() {
    _profileSubscription?.cancel();
    if (widget.uid.isEmpty) { setState(() { _profile = const {}; _busy = false; }); return; }
    setState(() { _busy = true; _failed = false; });
    _profileSubscription = _repository.watchProfile(widget.uid).listen((profile) {
      if (mounted) setState(() { _profile = profile; _busy = false; _failed = false; });
    }, onError: (_) { if (mounted) setState(() { _busy = false; _failed = true; }); });
  }

  Future<void> _choose() async {
    try { await InstituteRepository.instance.load(); } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load universities. Please retry.')));
      return;
    }
    if (!mounted) return;
    final universities = InstituteRepository.instance.items.where((item) => item.type == 'universities').toList();
    if (universities.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No universities are available right now.'))); return; }
    Institute? selected;
    for (final university in universities) {
      if (university.id == _profile[ProfileFields.instituteId]) selected = university;
    }
    String? program = (_profile[ProfileFields.course] ?? '').toString().isEmpty ? null : _profile[ProfileFields.course].toString();
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
            Text(_profile[ProfileFields.instituteId] == null ? 'Add your university' : 'Edit university & course', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
            const SizedBox(height: 8),
            const Text('Your university appears on your profile immediately. Its representative approves your student badge after reviewing your course.'),
            const SizedBox(height: 18),
            TextFormField(
              key: ValueKey('student-university-${selected?.id ?? 'none'}'),
              initialValue: selected?.name ?? '', readOnly: true,
              decoration: const InputDecoration(labelText: 'University', border: OutlineInputBorder(), suffixIcon: Icon(Icons.search)),
              onTap: saving ? null : () async {
                final id = await searchChoice(context, 'Search universities', {for (final u in universities) u.id: u.name});
                if (!context.mounted || id == null || id.isEmpty) return;
                setSheetState(() { selected = universities.firstWhere((u) => u.id == id); program = null; });
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: ValueKey('student-program-${selected?.id ?? 'none'}-${selectedProgram ?? ''}'),
              initialValue: selectedProgram ?? '', readOnly: true,
              decoration: const InputDecoration(labelText: 'Course / degree', border: OutlineInputBorder(), suffixIcon: Icon(Icons.search)),
              onTap: saving || selectedInstitute == null || distinct.isEmpty ? null : () async {
                final value = await searchChoice(context, 'Search courses', {for (final item in distinct) item.key: item.value});
                if (!context.mounted || value == null || value.isEmpty) return;
                setSheetState(() => program = value);
              },
            ),
            if (distinct.isEmpty && selected != null) const Padding(padding: EdgeInsets.only(top: 8), child: Text('This university has not listed courses yet. You can save the university now; approval can be requested after choosing a listed course.')),
            const SizedBox(height: 18),
            if (_profile[ProfileFields.affiliationStatus] == 'approved')
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Saving your university or course sends a new request. The university student badge returns after approval.')),
            FilledButton(
            onPressed: saving || selectedInstitute == null
                || (selectedInstitute.id == _profile[ProfileFields.instituteId] && (selectedProgram ?? '') == (_profile[ProfileFields.course] ?? ''))
                || (distinct.isNotEmpty && selectedProgram == null) ? null : () async {
                setSheetState(() => saving = true);
                try {
                  await _repository.select(selectedInstitute, selectedProgram ?? '');
                  if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                } catch (error) {
                  if (sheetContext.mounted) setSheetState(() => saving = false);
                  if (sheetContext.mounted) ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
                }
              },
              child: Text(saving ? 'Sending request…' : 'Save university'),
            ),
          ])),
        );
      }),
    );
    if (result == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('University details saved.')));
  }

  @override Widget build(BuildContext context) {
    if (_failed) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      const Text('Could not load university details.'),
      TextButton(onPressed: _watch, child: const Text('Retry')),
    ])));
    if (_busy) return const Card(child: Padding(padding: EdgeInsets.all(18), child: LinearProgressIndicator()));
    final institute = (_profile[ProfileFields.instituteName] ?? '').toString();
    final program = (_profile[ProfileFields.course] ?? '').toString();
    final status = (_profile[ProfileFields.affiliationStatus] ?? 'not_requested').toString();
    final selected = institute.isNotEmpty;
    final rawDate = _profile[ProfileFields.affiliationRequestedAt];
    final requestedAt = rawDate is Timestamp ? rawDate.toDate() : rawDate is DateTime ? rawDate : null;
    if (!selected && !widget.editable) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen), const SizedBox(width: 9), Text(widget.editable ? 'My university' : 'University', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen))]), ]),
      if (selected) ...[
        const SizedBox(height: 7),
        InkWell(onTap: () => context.push('/institute/${_profile[ProfileFields.instituteId]}'), child: Text(institute, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
        if (status == 'approved') const Padding(padding: EdgeInsets.only(top: 6), child: Tooltip(message: 'Student affiliation verified by this university', child: Chip(backgroundColor: AppColors.softGreen, avatar: Text('🎓', style: TextStyle(fontSize: 18)), label: Text('University student')))),
        if (program.isNotEmpty) Text(program, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 5),
        if (widget.editable) Text(switch (status) { 'approved' => 'This university confirmed your student affiliation.', 'pending' => 'Verification request sent. Waiting for the university.', 'rejected' => 'The university could not verify this request. You can update your details and send it again.', _ => 'University selected; verification has not been requested.' }, style: Theme.of(context).textTheme.bodySmall),
        if (widget.editable && status == 'pending' && requestedAt != null)
          Text('Requested: ${requestedAt.day}/${requestedAt.month}/${requestedAt.year}', style: Theme.of(context).textTheme.bodySmall),
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
