import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/institute.dart';
import '../../data/institute_repository.dart';
import '../../data/institute_access.dart';
import '../widgets/institute_detail_components.dart';
import '../widgets/institute_program_groups.dart';

class DisciplineInfoScreen extends StatefulWidget {
  final String instituteId;
  const DisciplineInfoScreen({super.key, required this.instituteId});

  @override
  State<DisciplineInfoScreen> createState() => _DisciplineInfoScreenState();
}

class _DisciplineInfoScreenState extends State<DisciplineInfoScreen> {
  final _group = TextEditingController();
  final _subject = TextEditingController();
  final _repository = InstituteRepository.instance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_onChanged);
    _subject.dispose();
    _group.dispose();
    super.dispose();
  }

  Future<void> _addProgram(Institute institute) async {
    if (_saving) return;
    setState(() => _saving = true);
    final success = await _repository.addProgramToGroup(
      institute.id,
      _group.text,
      _subject.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) _subject.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Program added to this category.'
              : _repository.error ?? 'Could not add program.',
        ),
      ),
    );
  }

  Future<void> _removeProgram(
    Institute institute,
    String group,
    String program,
  ) async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove program?'),
        content: Text('Remove $program from $group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    final success = await _repository.removeProgramFromGroup(
      institute.id,
      group,
      program,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Program removed.'
              : _repository.error ?? 'Could not remove program.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final institute = _repository.byId(widget.instituteId);
    if (institute == null)
      return const Scaffold(body: Center(child: Text('Institute not found.')));
    final canEdit = InstituteAccess.canManage(institute);
    return Scaffold(
      appBar: AppBar(title: const Text('Programs / Courses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(institute.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          InstituteDetailSection(
            title: 'Program categories',
            icon: Icons.school_outlined,
            children: [
              if (institute.programCategories.isEmpty)
                const Text('No programs listed yet.')
              else
                InstituteProgramGroups(
                  institute: institute,
                  onRemove: canEdit && !_saving
                      ? (group, name) => _removeProgram(institute, group, name)
                      : null,
                ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 16),
            InstituteDetailSection(
              title: 'Add a program',
              icon: Icons.add_circle_outline,
              children: [
                if (institute.programCategories.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: institute.programCategories
                        .map(
                          (group) => ActionChip(
                            label: Text(group),
                            onPressed: _saving
                                ? null
                                : () => _group.text = group,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _group,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category / level',
                    hintText: 'e.g. Undergraduate',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subject,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Program name',
                    hintText: 'e.g. BS Computer Science',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  onSubmitted: (_) => _addProgram(institute),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : () => _addProgram(institute),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Add program'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.push(
                '/institute/${institute.id}/opportunities?kind=course',
              ),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Manage published course announcements'),
            ),
          ],
        ],
      ),
    );
  }
}
