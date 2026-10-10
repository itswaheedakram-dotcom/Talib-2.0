import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../models/institute.dart';
import '../../../models/institute_program_requirements.dart';
import '../../../models/institute_opportunity.dart';
import '../../data/institute_opportunity_repository.dart';
import '../../../../core/services/active_profile_controller.dart';
import 'institute_opportunity_card.dart';
import 'institute_program_editor.dart';
import '../../data/institute_access.dart';

/// One selected category expands inline; selecting it again collapses its list.
class InstituteProgramGroups extends StatefulWidget {
  final Institute institute;
  final void Function(String group, String program)? onRemove;
  const InstituteProgramGroups({
    super.key,
    required this.institute,
    this.onRemove,
  });

  @override
  State<InstituteProgramGroups> createState() => _InstituteProgramGroupsState();
}

class _InstituteProgramGroupsState extends State<InstituteProgramGroups> {
  String? _selected;
  final _repository = InstituteOpportunityRepository.instance;
  @override
  void initState() {
    super.initState();
    _repository.addListener(_changed);
    ActiveProfileController.instance.addListener(_modeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _repository.load(widget.institute.id);
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _modeChanged() {
    if (!mounted) return;
    setState(() => _selected = null);
    _repository.load(widget.institute.id);
  }

  @override
  void dispose() {
    _repository.removeListener(_changed);
    ActiveProfileController.instance.removeListener(_modeChanged);
    super.dispose();
  }

  Widget _program(String name) {
    final key = InstituteProgramRequirements.key(_selected!, name);
    final items = _repository.forInstitute(widget.institute.id);
    InstituteOpportunity? details;
    for (final item in items) {
      if (item.kind == 'course' && item.programKeys.contains(key)) {
        details = item;
        break;
      }
    }
    final linked = items
        .where(
          (item) => item.kind == 'admission' && item.programKeys.contains(key),
        )
        .toList();
    linked.sort((a, b) {
      int priority(InstituteOpportunity item) =>
          switch (item.forProgram(key).statusAt()) {
            'Open' => 0,
            'Upcoming' => 1,
            _ => 2,
          };
      final order = priority(a).compareTo(priority(b));
      return order != 0 ? order : b.academicYear.compareTo(a.academicYear);
    });
    final status = linked.isEmpty
        ? 'Not announced'
        : linked.first.forProgram(key).statusAt();
    final deadline = linked.isEmpty
        ? ''
        : linked.first.forProgram(key).deadline;
    final record = details;
    return ExpansionTile(
      key: PageStorageKey('program:${widget.institute.id}:$key'),
      tilePadding: EdgeInsets.zero,
      leading: Icon(
        Icons.school_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(name),
      subtitle: Text(
        '$status${deadline.isEmpty ? '' : ' · Deadline: $deadline'}',
      ),
      children: [
        if (InstituteAccess.canManage(widget.institute))
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => showInstituteProgramEditor(
                  context,
                  widget.institute,
                  'course',
                  existing: record,
                  programKey: key,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit program details'),
              ),
              if (widget.onRemove != null)
                TextButton.icon(
                  onPressed: () => widget.onRemove!(_selected!, name),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Remove program'),
                ),
            ],
          ),
        if (record == null)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Program details / requirements have not been added yet.',
            ),
          )
        else
          InstituteOpportunityCard(item: record, showLinkedPrograms: false),
        if (linked.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Admissions have not been announced for this program.'),
          ),
        for (final intake in linked)
          InstituteOpportunityCard(
            item: intake.forProgram(key, record?.requirements ?? const {}),
            showLinkedPrograms: false,
          ),
      ],
    );
  }

  @override
  void didUpdateWidget(InstituteProgramGroups oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.institute.id != widget.institute.id ||
        !widget.institute.programCategories.contains(_selected))
      _selected = null;
    if (oldWidget.institute.id != widget.institute.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _repository.load(widget.institute.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.institute.programCategories;
    final names = widget.institute.programGroups[_selected] ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Select a category to view its programs.'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: categories.map((group) {
            final selected = group == _selected;
            return ChoiceChip(
              label: Text(group),
              selected: selected,
              showCheckmark: false,
              avatar: Icon(
                selected ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: selected ? AppColors.white : AppColors.darkGreen,
              ),
              selectedColor: AppColors.primaryGreen,
              backgroundColor: AppColors.softGreen,
              labelStyle: TextStyle(
                color: selected ? AppColors.white : AppColors.darkGreen,
              ),
              onSelected: (_) =>
                  setState(() => _selected = selected ? null : group),
            );
          }).toList(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _selected == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$_selected programs',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (names.isEmpty)
                        const Text(
                          'The detailed program list has not been added for this category yet.',
                        )
                      else ...[
                        if (InstituteAccess.isDemo)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Demo sample programs. Confirm actual offerings with the institute.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        for (final name in names) _program(name),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
