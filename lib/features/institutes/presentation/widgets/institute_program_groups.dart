import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../models/institute.dart';
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

  @override
  void didUpdateWidget(InstituteProgramGroups oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.institute.id != widget.institute.id ||
        !widget.institute.programCategories.contains(_selected))
      _selected = null;
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
                        for (final name in names)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.school_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(name),
                            trailing: widget.onRemove == null
                                ? null
                                : IconButton(
                                    tooltip: 'Remove $name',
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () =>
                                        widget.onRemove!(_selected!, name),
                                  ),
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
