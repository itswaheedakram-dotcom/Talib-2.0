import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/models/education_record.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/widgets/searchable_choice.dart';
import '../../../institutes/data/education_repository.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../../institutes/data/student_affiliation_repository.dart';
import '../../../models/institute.dart';
import 'student_affiliation_card.dart';

class EducationBadge extends StatelessWidget {
  final EducationRecord record;
  const EducationBadge({super.key, required this.record});
  @override
  Widget build(BuildContext context) {
    final alumni = record.isAlumni;
    if (!alumni && !record.isVerifiedCurrent) return const SizedBox.shrink();
    return Tooltip(
      message: alumni
          ? 'Completed education, declared by the student'
          : 'Current enrollment approved by this institute',
      child: Chip(
        avatar: Icon(
          alumni ? Icons.workspace_premium : Icons.school_outlined,
          color: alumni
              ? AppColors.alumniGold
              : Theme.of(context).colorScheme.primary,
        ),
        label: Text(alumni ? 'Alumni' : 'Current verified student'),
        backgroundColor: alumni
            ? AppColors.alumniGold.withValues(alpha: .12)
            : Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      ),
    );
  }
}

class StudentAffiliationCard extends StatelessWidget {
  final String uid;
  final bool editable;
  const StudentAffiliationCard({
    super.key,
    required this.uid,
    this.editable = false,
  });
  @override
  Widget build(BuildContext context) => StreamBuilder<List<EducationRecord>>(
    stream: EducationRepository.instance.watch(uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          children: [
            LegacyStudentAffiliationCard(uid: uid),
            if (editable)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Education history is temporarily unavailable. Try again later.',
                  ),
                ),
              ),
          ],
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final records = snapshot.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Education history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Add your past degrees or current studies. A current institute is optional.',
                      ),
                    ),
                  for (final record in records)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => context.push(
                              '/institute/${record.instituteId}',
                            ),
                            child: Text(
                              record.instituteName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            record.program.isEmpty
                                ? record.levelId
                                : record.program,
                          ),
                          Text(
                            '${switch (record.status) {
                              EducationStatus.completed => 'Completed',
                              EducationStatus.left => 'Left / incomplete',
                              _ => 'Currently studying',
                            }}${record.primary ? ' • Primary' : ''}',
                          ),
                          if (record.startDate != null ||
                              record.completionDate != null)
                            Text(
                              '${record.startDate?.year ?? '—'} – ${record.completionDate?.year ?? (record.status == EducationStatus.current ? 'Present' : 'End date not added')}',
                            ),
                          EducationBadge(record: record),
                          if (editable &&
                              record.status == EducationStatus.current &&
                              !record.isVerifiedCurrent)
                            Text(switch (record.verification) {
                              EducationVerification.pending =>
                                'Waiting for institute approval.',
                              EducationVerification.rejected =>
                                'Request declined. Edit and submit again.',
                              _ =>
                                'Choose a listed program to request approval.',
                            }),
                          if (editable)
                            TextButton.icon(
                              onPressed: () => _edit(context, record),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit education'),
                            ),
                          const Divider(),
                        ],
                      ),
                    ),
                  if (editable)
                    OutlinedButton.icon(
                      onPressed: () => _edit(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add education'),
                    ),
                ],
              ),
            ),
          ),
          if (!records.any((r) => r.id == 'legacy-$uid')) ...[
            LegacyStudentAffiliationCard(uid: uid, editable: false),
            if (editable)
              FutureBuilder<Map<String, dynamic>>(
                future: StudentAffiliationRepository.instance.profile(uid),
                builder: (context, legacy) {
                  if ((legacy.data?[ProfileFields.instituteId] ?? '')
                      .toString()
                      .isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return TextButton(
                    onPressed: () => _edit(
                      context,
                      EducationRecord(
                        id: 'legacy-$uid',
                        userId: uid,
                        instituteId: legacy.data![ProfileFields.instituteId]
                            .toString(),
                        instituteName: legacy.data![ProfileFields.instituteName]
                            .toString(),
                        program: (legacy.data![ProfileFields.course] ?? '')
                            .toString(),
                      ),
                    ),
                    child: const Text(
                      'Move existing institute into education history',
                    ),
                  );
                },
              ),
          ],
        ],
      );
    },
  );
  Future<void> _edit(BuildContext context, EducationRecord? previous) async {
    try {
      await InstituteRepository.instance.load();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load institutes. Try again.'),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final institutes = InstituteRepository.instance.items;
    Institute? selected;
    for (final institute in institutes) {
      if (institute.id == previous?.instituteId) selected = institute;
    }
    String program = previous?.program ?? '',
        level = (previous?.levelId ?? '').isEmpty
            ? 'bachelors'
            : previous!.levelId,
        status = previous?.status ?? EducationStatus.current;
    bool primary = previous?.primary ?? false, saving = false;
    DateTime? start = previous?.startDate, end = previous?.completionDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) {
          final programs = selected == null
              ? <String>{}
              : {
                  ...selected!.programs,
                  ...selected!.programGroups.values.expand((v) => v),
                };
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    previous == null ? 'Add education' : 'Edit education',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey(selected?.id),
                    initialValue: selected?.name ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Institute',
                      suffixIcon: Icon(Icons.search),
                    ),
                    onTap: saving
                        ? null
                        : () async {
                            final id = await searchChoice(
                              context,
                              'Search all institutes',
                              {
                                for (final i in institutes)
                                  i.id: '${i.name} • ${i.type}',
                              },
                            );
                            if (id != null &&
                                id.isNotEmpty &&
                                context.mounted) {
                              update(() {
                                selected = institutes.firstWhere(
                                  (i) => i.id == id,
                                );
                                program = '';
                                if (previous == null) {
                                  level = switch (selected!.type) {
                                    'schools' => 'school',
                                    'colleges' => 'college',
                                    'universities' => 'bachelors',
                                    _ => 'other',
                                  };
                                }
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('${selected?.id}-$program'),
                    initialValue: program,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Program / qualification',
                      suffixIcon: Icon(Icons.search),
                    ),
                    onTap: saving || programs.isEmpty
                        ? null
                        : () async {
                            final choice = await searchChoice(
                              context,
                              'Choose listed program',
                              {for (final p in programs) p: p},
                            );
                            if (choice != null &&
                                choice.isNotEmpty &&
                                context.mounted) {
                              update(() => program = choice);
                            }
                          },
                  ),
                  if (selected != null && programs.isEmpty)
                    const Text(
                      'This institute has not listed programs yet. You can save the institute without requesting verification.',
                    ),
                  DropdownButtonFormField<String>(
                    key: ValueKey('education-level-$level'),
                    initialValue: level,
                    decoration: const InputDecoration(
                      labelText: 'Education level',
                    ),
                    items: EducationLevels.labels.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: saving ? null : (v) => update(() => level = v!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: EducationStatus.current,
                        child: Text('Currently studying'),
                      ),
                      DropdownMenuItem(
                        value: EducationStatus.completed,
                        child: Text('Completed / Alumni'),
                      ),
                      DropdownMenuItem(
                        value: EducationStatus.left,
                        child: Text('Left / incomplete'),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) => update(() {
                            status = v!;
                            if (status != EducationStatus.current) {
                              primary = false;
                            }
                            if (status == EducationStatus.current) end = null;
                          }),
                  ),
                  if (status == EducationStatus.current)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Primary current institute'),
                      value: primary,
                      onChanged: saving
                          ? null
                          : (v) => update(() => primary = v),
                    ),
                  TextButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: start ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (date != null && context.mounted) {
                              update(() {
                                start = date;
                                if (end != null && end!.isBefore(date)) {
                                  end = null;
                                }
                              });
                            }
                          },
                    child: Text(
                      'Start date: ${start == null ? 'Choose (optional)' : '${start!.day}/${start!.month}/${start!.year}'}',
                    ),
                  ),
                  if (status != EducationStatus.current)
                    TextButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    end != null &&
                                        (start == null ||
                                            !end!.isBefore(start!))
                                    ? end!
                                    : start ?? DateTime.now(),
                                firstDate: start ?? DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (date != null && context.mounted) {
                                update(() => end = date);
                              }
                            },
                      child: Text(
                        'End date: ${end == null ? 'Choose (optional)' : '${end!.day}/${end!.month}/${end!.year}'}',
                      ),
                    ),
                  const Text(
                    'Alumni is self-declared. Current verified student badges require institute approval. Changing institute or program sends a fresh request.',
                  ),
                  FilledButton(
                    onPressed: saving || selected == null
                        ? null
                        : () async {
                            update(() => saving = true);
                            try {
                              await EducationRepository.instance.save(
                                EducationRecord(
                                  id:
                                      previous?.id ??
                                      EducationRepository.instance.newId(),
                                  userId: uid,
                                  instituteId: selected!.id,
                                  instituteName: selected!.name,
                                  programId: EducationFields.programKey(
                                    selected!.id,
                                    program,
                                  ),
                                  program: program,
                                  levelId: level,
                                  status: status,
                                  primary: primary,
                                  startDate: start,
                                  completionDate: end,
                                ),
                                selected!,
                              );
                              if (sheet.mounted) Navigator.pop(sheet);
                            } catch (error) {
                              if (context.mounted) {
                                update(() => saving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error.toString().replaceFirst(
                                        'Bad state: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: Text(saving ? 'Saving…' : 'Save education'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class VerifiedStudentCount extends StatefulWidget {
  final String instituteId;
  const VerifiedStudentCount({super.key, required this.instituteId});
  @override
  State<VerifiedStudentCount> createState() => _VerifiedStudentCountState();
}

class _VerifiedStudentCountState extends State<VerifiedStudentCount> {
  late Stream<List<EducationRecord>> _records;
  late Future<Set<String>> _legacy;
  @override
  void initState() {
    super.initState();
    _reload();
    StudentAffiliationRepository.instance.addListener(_legacyChanged);
  }

  @override
  void didUpdateWidget(VerifiedStudentCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instituteId != widget.instituteId) _reload();
  }

  @override
  void dispose() {
    StudentAffiliationRepository.instance.removeListener(_legacyChanged);
    super.dispose();
  }

  void _reload() {
    _records = EducationRepository.instance.instituteRecords(
      widget.instituteId,
    );
    _legacy = StudentAffiliationRepository.instance.verifiedStudentIds(
      widget.instituteId,
    );
  }

  void _legacyChanged() {
    if (mounted) {
      setState(
        () => _legacy = StudentAffiliationRepository.instance
            .verifiedStudentIds(widget.instituteId),
      );
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<EducationRecord>>(
    stream: _records,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text('Could not load student counts.');
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final records = snapshot.data!;
      return FutureBuilder<Set<String>>(
        future: _legacy,
        builder: (context, legacy) {
          if (legacy.hasError) {
            return const Text('Could not load student counts.');
          }
          if (!legacy.hasData) return const LinearProgressIndicator();
          final migrated = records
              .where((r) => r.id == 'legacy-${r.userId}')
              .map((r) => r.userId)
              .toSet();
          final current = {
            ...legacy.data!.difference(migrated),
            ...records.where((r) => r.isVerifiedCurrent).map((r) => r.userId),
          };
          final alumni = records
              .where((r) => r.isAlumni)
              .map((r) => r.userId)
              .toSet();
          return Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('${current.length} current verified students'),
              Text('${alumni.length} alumni'),
            ],
          );
        },
      );
    },
  );
}
