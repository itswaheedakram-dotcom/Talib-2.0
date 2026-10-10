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
  final _form = GlobalKey<FormState>();
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

  Widget _field(
    String key,
    String label,
    Map<String, String> values, {
    bool date = false,
  }) {
    if (key == 'scoreScale' || key == 'status') {
      final options = key == 'scoreScale'
          ? InstituteProgramRequirements.scales
          : ['Not announced', 'Upcoming', 'Open', 'Closed', 'Cancelled'];
      return DropdownButtonFormField<String>(
        key: ValueKey('${identityHashCode(values)}:$key:${values[key]}'),
        value: options.contains(values[key]) ? values[key] : options.first,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: _saving ? null : (v) => setState(() => values[key] = v!),
      );
    }
    return TextFormField(
      key: ValueKey(
        '${identityHashCode(values)}:$key${date
            ? ':${values[key]}'
            : key == 'title'
            ? ':${_selected.join(',')}'
            : ''}',
      ),
      initialValue: values[key] ?? '',
      enabled: !_saving,
      readOnly: date,
      maxLines: date || key == 'minScore' ? 1 : null,
      keyboardType: key == 'minScore'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: date
            ? IconButton(
                tooltip: 'Clear date',
                onPressed: _saving
                    ? null
                    : () => setState(() => values[key] = ''),
                icon: const Icon(Icons.clear, size: 18),
              )
            : null,
      ),
      onChanged: (v) => setState(() => values[key] = v.trim()),
      onTap: date
          ? () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.tryParse(values[key] ?? '') ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(DateTime.now().year + 30),
              );
              if (chosen != null && mounted)
                setState(
                  () => values[key] = chosen.toIso8601String().split('T').first,
                );
            }
          : null,
    );
  }

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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(_admission ? 'Admission intake' : 'Program details'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select programs from this institute. Shared details are entered once.',
                ),
                for (final group in _groups.entries)
                  ExpansionTile(
                    initiallyExpanded:
                        _groups.length == 1 ||
                        group.value.any(
                          (name) => _selected.contains(
                            InstituteProgramRequirements.key(group.key, name),
                          ),
                        ),
                    tilePadding: EdgeInsets.zero,
                    title: Text(group.key),
                    children: [
                      if (_admission && group.value.isNotEmpty)
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                  final keys = group.value
                                      .map(
                                        (n) => InstituteProgramRequirements.key(
                                          group.key,
                                          n,
                                        ),
                                      )
                                      .toList();
                                  if (keys.every(_selected.contains)) {
                                    _selected.removeAll(keys);
                                  } else {
                                    _selected.addAll(keys);
                                  }
                                }),
                          child: Text(
                            'Select / clear all ${group.key} programs',
                          ),
                        ),
                      for (final name in group.value)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(name),
                          value: _selected.contains(
                            InstituteProgramRequirements.key(group.key, name),
                          ),
                          onChanged: _saving
                              ? null
                              : (v) => setState(() {
                                  final key = InstituteProgramRequirements.key(
                                    group.key,
                                    name,
                                  );
                                  if (v == true) {
                                    if (!_admission) _selected.clear();
                                    _selected.add(key);
                                    if (!_admission) _values['title'] = name;
                                  } else {
                                    _selected.remove(key);
                                  }
                                }),
                        ),
                    ],
                  ),
                for (final key
                    in _selected
                        .where((key) => !_available.contains(key))
                        .toList())
                  ListTile(
                    title: Text(
                      'No longer offered: ${InstituteProgramRequirements.name(key)}',
                    ),
                    trailing: IconButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _selected.remove(key)),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                Text('${_selected.length} programs selected'),
                _field(
                  'title',
                  _admission ? 'Intake title' : 'Program title',
                  _values,
                ),
                if (_admission) ...[
                  _field('academicYear', 'Academic year', _values),
                  _field('intake', 'Session / intake (Fall, Spring)', _values),
                  _field('status', 'Admission status', _values),
                  _field(
                    'openingDate',
                    'Common opening date',
                    _values,
                    date: true,
                  ),
                  _field('deadline', 'Common deadline', _values, date: true),
                ],
                if (!_admission)
                  for (final entry
                      in InstituteProgramRequirements.metadataLabels.entries)
                    _field(entry.key, entry.value, _metadata),
                ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    _admission
                        ? 'Common eligibility & requirements'
                        : 'Program eligibility & requirements',
                  ),
                  subtitle: const Text(
                    'Minimum eligibility and previous closing merit are separate.',
                  ),
                  children: [
                    for (final entry
                        in InstituteProgramRequirements.labels.entries)
                      _field(
                        entry.key,
                        entry.value,
                        _requirements,
                        date: entry.key == 'testDate',
                      ),
                  ],
                ),
                _field(
                  'eligibility',
                  'Other eligibility / legacy requirements',
                  _values,
                ),
                _field('feeDetails', 'Fee details', _values),
                _field(
                  'applicationUrl',
                  'Official ${_admission ? 'apply' : 'program'} URL',
                  _values,
                ),
                _field('description', 'Additional information', _values),
                if (_admission) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Program exceptions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Use common details by default. Customize only fields that differ. Empty common requirements use the saved program criteria.',
                  ),
                  for (final key in _selected)
                    ExpansionTile(
                      key: ValueKey('override:$key'),
                      tilePadding: EdgeInsets.zero,
                      title: Text(InstituteProgramRequirements.name(key)),
                      subtitle: Text(
                        (_overrides[key]?.isNotEmpty ?? false)
                            ? 'Customized details'
                            : 'Uses common details',
                      ),
                      children: [
                        for (final entry in <String, String>{
                          'status': 'Admission status',
                          'openingDate': 'Opening date',
                          'deadline': 'Deadline',
                          ...InstituteProgramRequirements.labels,
                          'applicationUrl': 'Official apply URL',
                          'eligibility': 'Other eligibility',
                        }.entries)
                          Builder(
                            builder: (_) {
                              final values = _overrides.putIfAbsent(
                                key,
                                () => {},
                              );
                              final customized = values.containsKey(entry.key);
                              final shared =
                                  (_requirements[entry.key]?.isNotEmpty ?? false
                                      ? _requirements[entry.key]
                                      : null) ??
                                  _values[entry.key] ??
                                  _baseline(key)[entry.key] ??
                                  '';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(entry.value),
                                    subtitle: Text(
                                      customized
                                          ? 'Customized'
                                          : 'Use common requirement${shared.isEmpty ? '' : ': $shared'}',
                                    ),
                                    value: customized,
                                    onChanged: _saving
                                        ? null
                                        : (v) => setState(() {
                                            if (v) {
                                              values[entry.key] = shared;
                                            } else {
                                              values.remove(entry.key);
                                            }
                                          }),
                                  ),
                                  if (customized)
                                    _field(
                                      entry.key,
                                      entry.value,
                                      values,
                                      date: {
                                        'openingDate',
                                        'deadline',
                                        'testDate',
                                      }.contains(entry.key),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}
