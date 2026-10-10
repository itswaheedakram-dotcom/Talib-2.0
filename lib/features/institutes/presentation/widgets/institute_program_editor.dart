import 'package:flutter/material.dart';

import '../../../models/institute.dart';
import '../../../models/institute_opportunity.dart';
import '../../../models/institute_program_requirements.dart';
import '../../data/institute_access.dart';
import '../../data/institute_opportunity_repository.dart';

Future<void> showInstituteProgramEditor(
  BuildContext context,
  Institute institute,
  String kind, {
  InstituteOpportunity? existing,
  String? programKey,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _ProgramEditor(
    institute: institute,
    kind: kind,
    existing: existing,
    programKey: programKey,
  ),
);

class _ProgramEditor extends StatefulWidget {
  final Institute institute;
  final String kind;
  final InstituteOpportunity? existing;
  final String? programKey;
  const _ProgramEditor({
    required this.institute,
    required this.kind,
    this.existing,
    this.programKey,
  });
  @override
  State<_ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<_ProgramEditor> {
  final _scroll = ScrollController();
  int _step = 0;
  final _values = <String, String>{};
  final _requirements = <String, String>{};
  final _metadata = <String, String>{};
  final _selected = <String>{};
  final _overrides = <String, Map<String, String>>{};
  bool _saving = false;
  String? _error;
  bool get _admission => widget.kind == 'admission';
  Map<String, List<String>> get _groups => widget.institute.programGroups;
  List<String> get _available => [
    for (final group in _groups.entries)
      for (final name in group.value)
        InstituteProgramRequirements.key(group.key, name),
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _values.addAll({
      'title': item?.title ?? '',
      'academicYear': item?.academicYear ?? DateTime.now().year.toString(),
      'intake': item?.intake ?? '',
      'status': item?.status ?? 'Not announced',
      'openingDate': item?.openingDate ?? '',
      'deadline': item?.deadline ?? '',
      'eligibility': item?.eligibility ?? '',
      'feeDetails': item?.feeDetails ?? '',
      'applicationUrl': item?.applicationUrl ?? '',
      'description': item?.description ?? '',
      'deliveryMode': item?.deliveryMode ?? '',
    });
    _requirements.addAll(item?.requirements ?? {});
    _metadata.addAll(item?.programDetails ?? {});
    _selected.addAll(item?.programKeys ?? []);
    if (widget.programKey != null) _selected.add(widget.programKey!);
    for (final entry
        in (item?.programOverrides ?? <String, Map<String, String>>{})
            .entries) {
      _overrides[entry.key] = Map.of(entry.value);
    }
    if (!_admission && _values['title']!.isEmpty && _selected.length == 1) {
      _values['title'] = InstituteProgramRequirements.name(_selected.single);
    }
  }

  static const _examples = <String, String>{
    'title': 'e.g. BS Computer Science or Fall admissions',
    'duration': 'e.g. 4 years / 8 semesters',
    'campus': 'e.g. Main campus, Lahore',
    'studyMode': 'e.g. On campus, morning',
    'tuitionFee': 'e.g. PKR 45,000 per semester',
    'academicYear': 'e.g. 2027',
    'intake': 'e.g. Fall or Spring',
    'qualification': 'e.g. Intermediate or a relevant bachelor’s degree',
    'minScore': 'e.g. 50 for percentage, or 2.5 for CGPA',
    'subjects': 'e.g. Mathematics, or a degree in Computer Science',
    'testName': 'e.g. University test, GAT, or no test required',
    'testScore': 'e.g. 50 out of 100',
    'testValidity': 'e.g. Result valid for 2 years',
    'interview': 'e.g. Interview required after the entry test',
    'research': 'e.g. Research proposal required for PhD',
    'documents': 'e.g. CNIC, photograph and academic certificates',
    'experience': 'e.g. 2 years of relevant work experience',
    'restrictions': 'e.g. Domicile or age requirement, if any',
    'applicationFee': 'e.g. PKR 2,000',
    'closingMerit': 'e.g. 82% in Fall 2025 (reference only)',
    'feeDetails': 'e.g. Admission fee and payment instructions',
    'applicationUrl': 'https://example.edu.pk/admissions',
    'notes': 'Any other requirement students should know',
    'eligibility': 'Any requirement not covered above',
    'description': 'Any extra information for students',
  };

  Widget _field(String key, String label, Map<String, String> values,
      {bool date = false, bool isRequired = false}) {
    final multiline = {'qualification', 'subjects', 'documents', 'notes', 'eligibility',
      'description', 'research', 'restrictions', 'interview', 'feeDetails'}.contains(key);
    final decoration = InputDecoration(
      hintText: date ? 'Choose a date' : _examples[key],
      // Labels live above the control, so long labels cannot collide with values.
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: date ? IconButton(tooltip: 'Clear date',
        onPressed: _saving ? null : () => setState(() => values[key] = ''),
        icon: const Icon(Icons.clear, size: 18)) : null,
    );
    Widget input;
    if (key == 'scoreScale' || key == 'status') {
      final options = key == 'scoreScale' ? InstituteProgramRequirements.scales
          : ['Not announced', 'Upcoming', 'Open', 'Closed', 'Cancelled'];
      input = DropdownButtonFormField<String>(
        key: ValueKey('input-$key-${identityHashCode(values)}:${values[key]}'),
        value: options.contains(values[key]) ? values[key] : options.first,
        isExpanded: true, decoration: decoration,
        items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: _saving ? null : (v) => setState(() { values[key] = v!; _error = null; }),
      );
    } else {
      input = TextFormField(
        key: ValueKey('input-$key-${identityHashCode(values)}:${date ? values[key] : key == 'title' ? _selected.join(',') : ''}'),
        initialValue: values[key] ?? '', enabled: !_saving, readOnly: date,
        minLines: multiline ? 2 : 1, maxLines: multiline ? 4 : 1,
        keyboardType: key == 'minScore' ? const TextInputType.numberWithOptions(decimal: true)
            : key == 'academicYear' ? TextInputType.number
            : key == 'applicationUrl' ? TextInputType.url : multiline ? TextInputType.multiline : TextInputType.text,
        textInputAction: multiline ? TextInputAction.newline : TextInputAction.next,
        decoration: decoration,
        onChanged: (v) => setState(() { values[key] = v.trim(); _error = null; }),
        onTap: date ? () async {
          final first = DateTime(2000), last = DateTime(DateTime.now().year + 30);
          final previous = DateTime.tryParse(values[key] ?? '') ?? DateTime.now();
          final chosen = await showDatePicker(context: context,
            initialDate: previous.isBefore(first) || previous.isAfter(last) ? DateTime.now() : previous,
            firstDate: first, lastDate: last);
          if (chosen != null && mounted) setState(() { values[key] = chosen.toIso8601String().split('T').first; _error = null; });
        } : null,
      );
    }
    return Padding(
      key: ValueKey('editor-field-$key'),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$label${isRequired ? ' *' : ''}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8), input,
      ]),
    );
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Map<String, String> _baseline(String key) {
    for (final item in InstituteOpportunityRepository.instance.forInstitute(
      widget.institute.id,
    )) {
      if (item.kind == 'course' && item.programKeys.contains(key))
        return item.requirements;
    }
    return {};
  }

  Future<void> _save() async {
    if (_saving) return;
    String? error;
    if (_values['title']!.trim().isEmpty) error = 'Enter a title.';
    if (_selected.isEmpty)
      error =
          'Select at least one program. Add programs in Program categories first.';
    if (!_admission && _selected.length != 1)
      error = 'Select one program for permanent details.';
    if (_selected.any((key) => !_available.contains(key)))
      error = 'Remove programs no longer offered before saving.';
    final scoreError = InstituteProgramRequirements.validate(_requirements);
    if (scoreError != null) error = scoreError;
    final draft = InstituteOpportunity.fromMap(widget.existing?.id ?? '', {
      ...?widget.existing?.toMap(),
      ..._values,
      'instituteId': widget.institute.id,
      'kind': widget.kind,
      'programKeys': _selected.toList(),
      'requirements': _requirements,
      'programDetails': _metadata,
      'programOverrides': {
        for (final key in _selected)
          if (_overrides[key]?.isNotEmpty ?? false) key: _overrides[key],
      },
      'createdBy': widget.existing?.createdBy ?? InstituteAccess.uid ?? '',
    });
    for (final key in _selected) {
      final resolved = draft.forProgram(key, _baseline(key));
      final validation = InstituteProgramRequirements.validate(
        resolved.requirements,
      );
      if (validation != null)
        error = '${InstituteProgramRequirements.name(key)}: $validation';
      final start = DateTime.tryParse(resolved.openingDate);
      final end = DateTime.tryParse(resolved.deadline);
      if (start != null && end != null && end.isBefore(start))
        error = 'Deadline cannot be before the opening date.';
      final url = resolved.applicationUrl;
      if (url.isNotEmpty) {
        final parsed = Uri.tryParse(url);
        if (parsed == null ||
            !{'https', 'http'}.contains(parsed.scheme) ||
            parsed.host.isEmpty)
          error = 'Use a full official URL starting with https:// or http://.';
      }
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = InstituteOpportunityRepository.instance;
    final success = widget.existing == null
        ? await repository.add(draft) != null
        : await repository.update(draft);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = false;
      _error = repository.error ?? 'Could not save. Please retry.';
    });
  }

  List<String> get _steps => _admission
      ? ['Choose programs', 'Admission dates', 'Who can apply?', 'Extra details', 'Review & save']
      : ['Program basics', 'Who can apply?', 'Extra details', 'Review & save'];

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() { _step = step; _error = null; });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    String? error;
    if (_step == 0) {
      if (_selected.isEmpty) error = 'Choose at least one program to continue.';
      else if (!_admission && _selected.length != 1) error = 'Choose one program to continue.';
      else if (_selected.any((key) => !_available.contains(key))) error = 'Remove programs that are no longer offered.';
      else if (_values['title']!.isEmpty) error = _admission ? 'Enter a name for this admission intake.' : 'Enter the program name.';
    }
    if (_admission && _step == 1) {
      final start = DateTime.tryParse(_values['openingDate'] ?? '');
      final end = DateTime.tryParse(_values['deadline'] ?? '');
      if (start != null && end != null && end.isBefore(start)) error = 'The deadline must be on or after the opening date.';
    }
    if (_step == (_admission ? 2 : 1)) error = InstituteProgramRequirements.validate(_requirements);
    if (error != null) { setState(() => _error = error); return; }
    _go(_step + 1);
  }

  Widget _intro(String title, String help) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8), Text(help),
    ]),
  );

  Widget _optional(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(margin: EdgeInsets.zero, child: ExpansionTile(
      key: PageStorageKey('editor-section:$title'),
      title: Text(title), subtitle: const Text('Optional — add only what applies'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4), children: children,
    )),
  );

  List<Widget> _programSelection() => [
    if (!_admission && _selected.length == 1 && _available.contains(_selected.single))
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(InstituteProgramRequirements.name(_selected.single), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6), Text(InstituteProgramRequirements.group(_selected.single)),
        ])))
    else for (final group in _groups.entries) Card(margin: const EdgeInsets.only(bottom: 12), child: ExpansionTile(
      initiallyExpanded: _groups.length == 1 || group.value.any((n) => _selected.contains(InstituteProgramRequirements.key(group.key, n))),
      title: Text(group.key), children: [
        if (_admission && group.value.isNotEmpty) TextButton(
          onPressed: _saving ? null : () => setState(() {
            final keys = group.value.map((n) => InstituteProgramRequirements.key(group.key, n)).toList();
            if (keys.every(_selected.contains)) { _selected.removeAll(keys); } else { _selected.addAll(keys); }
            _error = null;
          }), child: Text('Select / clear all ${group.key} programs')),
        for (final name in group.value) CheckboxListTile(title: Text(name),
          value: _selected.contains(InstituteProgramRequirements.key(group.key, name)),
          onChanged: _saving ? null : (v) => setState(() {
            final key = InstituteProgramRequirements.key(group.key, name);
            if (v == true) { if (!_admission) _selected.clear(); _selected.add(key); if (!_admission) _values['title'] = name; }
            else { _selected.remove(key); } _error = null;
          })),
      ])),
    if (_groups.isEmpty) const Text('Add the institute’s programs first, then return here.'),
    for (final key in _selected.where((key) => !_available.contains(key)).toList()) ListTile(
      title: Text('No longer offered: ${InstituteProgramRequirements.name(key)}'),
      trailing: IconButton(onPressed: _saving ? null : () => setState(() => _selected.remove(key)), icon: const Icon(Icons.close))),
    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${_selected.length} ${_selected.length == 1 ? 'program' : 'programs'} selected')),
  ];

  List<Widget> _eligibility() => [
    _intro('Who can apply?', _admission
      ? 'These requirements apply to all selected programs. Leave a field empty to use that program’s saved requirement.'
      : 'Add the minimum education and marks a student needs. Leave anything you do not know empty.'),
    _field('qualification', 'Required education', _requirements),
    _field('scoreScale', 'Marks or CGPA?', _requirements),
    _field('minScore', 'Minimum marks / CGPA', _requirements),
    _field('subjects', 'Required subjects or previous degree', _requirements),
    const Text('Minimum eligibility is not the same as the closing merit, and does not guarantee admission.'),
  ];

  List<Widget> _extraDetails() => [
    _intro('Extra details', 'This step is optional. Open only the sections you need, or tap Next to continue.'),
    _optional('Entry test & interview', [
      for (final key in ['testName', 'testScore', 'testValidity', 'testDate', 'interview'])
        _field(key, InstituteProgramRequirements.labels[key]!, _requirements, date: key == 'testDate'),
    ]),
    _optional('Documents & other requirements', [
      for (final key in ['documents', 'research', 'experience', 'restrictions', 'closingMerit', 'notes'])
        _field(key, InstituteProgramRequirements.labels[key]!, _requirements),
      _field('eligibility', 'Other eligibility information', _values),
    ]),
    _optional('Fees & official link', [
      _field('applicationFee', 'Application fee', _requirements),
      _field('feeDetails', 'Other fees or payment instructions', _values),
      _field('applicationUrl', 'Official website link', _values),
      _field('description', 'Other information for students', _values),
    ]),
    if (_admission) _optional('Different details for a program', [
      const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('All programs use the common details. Open a program below only if something is different. Turn off a change to use the common value again.')),
      for (final key in _selected) ExpansionTile(
        key: ValueKey('override:$key'), tilePadding: EdgeInsets.zero,
        title: Text(InstituteProgramRequirements.name(key)),
        subtitle: Text((_overrides[key]?.isNotEmpty ?? false) ? 'Has different details' : 'Uses common details'),
        children: [for (final entry in <String, String>{
          'status': 'Admission status', 'openingDate': 'Opening date', 'deadline': 'Deadline',
          ...InstituteProgramRequirements.labels, 'applicationUrl': 'Official website link', 'eligibility': 'Other eligibility',
        }.entries) Builder(builder: (_) {
          final values = _overrides.putIfAbsent(key, () => {});
          final customized = values.containsKey(entry.key);
          final shared = (_requirements[entry.key]?.isNotEmpty ?? false ? _requirements[entry.key] : null)
              ?? _values[entry.key] ?? _baseline(key)[entry.key] ?? '';
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(entry.value),
                subtitle: Text(customized ? 'Different for this program' : 'Same as common details${shared.isEmpty ? '' : ': $shared'}'),
                value: customized, onChanged: _saving ? null : (v) => setState(() {
                  if (v) { values[entry.key] = shared; } else { values.remove(entry.key); } _error = null;
                })),
              if (customized) _field(entry.key, entry.value, values, date: {'openingDate','deadline','testDate'}.contains(entry.key)),
            ]));
        })],
      ),
    ]),
  ];

  Widget _reviewBlock(String title, Map<String, String> values, Map<String, String> labels) => Card(
    margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (!values.values.any((v) => v.isNotEmpty)) const Text('No details added.'),
        for (final entry in labels.entries) if (values[entry.key]?.isNotEmpty ?? false)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('${entry.value}: ${values[entry.key]}')),
      ])),
  );

  List<Widget> _review() => [
    _intro('Check before saving', 'Use Back to change anything. Save will publish these details to this institute.'),
    _reviewBlock(_admission ? 'Admission intake' : 'Program', _values, {
      'title': 'Name', if (_admission) ...{'academicYear': 'Year', 'intake': 'Session', 'status': 'Status', 'openingDate': 'Opens', 'deadline': 'Common deadline'},
      'feeDetails': 'Fees', 'applicationUrl': 'Official link', 'eligibility': 'Other eligibility', 'description': 'Other information',
    }),
    if (!_admission) _reviewBlock('Program information', _metadata, InstituteProgramRequirements.metadataLabels),
    for (final key in _selected) ...[
      _reviewBlock(InstituteProgramRequirements.name(key), {
        ...(_admission ? _baseline(key) : <String, String>{}), for (final entry in _requirements.entries) if (entry.value.isNotEmpty) entry.key: entry.value,
        ...?_overrides[key],
      }, {
        ...InstituteProgramRequirements.labels,
        if (_admission) ...{'openingDate': 'Different opening date', 'deadline': 'Different deadline', 'status': 'Different status', 'applicationUrl': 'Different apply link'},
      }),
    ],
  ];

  List<Widget> _page() {
    if (_step == 0) return [
      _intro(_admission ? 'Which programs are accepting applications?' : 'Program basics',
        _admission ? 'Select one or more programs. You will enter the shared dates and requirements once.' : 'Start with the program name and basic information. Fields marked * are required.'),
      ..._programSelection(),
      _field('title', _admission ? 'Admission intake name' : 'Program name', _values, isRequired: true),
      if (!_admission) for (final entry in InstituteProgramRequirements.metadataLabels.entries) _field(entry.key, entry.value, _metadata),
    ];
    if (_step == _steps.length - 1) return _review();
    if (_admission && _step == 1) return [
      _intro('Admission dates', 'These dates apply to every selected program. Different dates can be added in Extra details.'),
      _field('academicYear', 'Academic year', _values), _field('intake', 'Session (Fall / Spring)', _values),
      _field('status', 'Are admissions open?', _values),
      _field('openingDate', 'Applications open on', _values, date: true),
      _field('deadline', 'Last date to apply', _values, date: true),
    ];
    if (_step == (_admission ? 2 : 1)) return _eligibility();
    return _extraDetails();
  }

  @override
  Widget build(BuildContext context) => PopScope(canPop: !_saving, child: Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(title: Text(_admission ? 'Admission intake' : 'Program details', maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(tooltip: 'Cancel', icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => Navigator.pop(context))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Step ${_step + 1} of ${_steps.length} · ${_steps[_step]}', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10), LinearProgressIndicator(value: (_step + 1) / _steps.length),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error))),
          ])),
        Expanded(child: SingleChildScrollView(controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640),
            child: Column(key: ValueKey('step-$_step'), crossAxisAlignment: CrossAxisAlignment.stretch, children: _page()))))),
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 16), child: Row(children: [
        if (_step > 0) OutlinedButton(onPressed: _saving ? null : () => _go(_step - 1), child: const Text('Back')),
        const Spacer(), FilledButton(onPressed: _saving ? null : _step == _steps.length - 1 ? _save : _next,
          child: Text(_saving ? 'Saving…' : _step == _steps.length - 1 ? 'Save' : 'Next')),
        ]))),
      ]),
    ),
  ));
}
