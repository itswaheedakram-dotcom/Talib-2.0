import 'package:flutter/material.dart';

import '../../../models/institute_opportunity.dart';
import '../../../models/institute_program_requirements.dart';
import '../../data/institute_opportunity_repository.dart';
import 'institute_detail_components.dart';

/// Shared, expandable listing content for browsing and management.
class InstituteOpportunityCard extends StatelessWidget {
  final InstituteOpportunity item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showLinkedPrograms;

  const InstituteOpportunityCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.showLinkedPrograms = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayedStatus = item.displayStatus;
    final status = displayedStatus.trim().toLowerCase();
    final statusIcon = switch (status) {
      'open' => Icons.check_circle_outline,
      'upcoming' => Icons.schedule_outlined,
      _ => Icons.info_outline,
    };
    final hasMore =
        [
          item.eligibility,
          item.deliveryMode,
          item.provider,
          item.description,
        ].any((value) => value.trim().isNotEmpty) ||
        item.requirements.values.any((value) => value.isNotEmpty) ||
        item.programDetails.values.any((value) => value.isNotEmpty);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'Manage listing',
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      if (onEdit != null)
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (item.kind != 'course' && displayedStatus.trim().isNotEmpty)
                  InstituteDetailBadge(
                    label: displayedStatus,
                    icon: statusIcon,
                  ),
                if (item.academicYear.trim().isNotEmpty)
                  InstituteDetailBadge(
                    label: item.academicYear,
                    icon: Icons.calendar_today_outlined,
                  ),
                if (item.intake.trim().isNotEmpty)
                  InstituteDetailBadge(label: item.intake),
              ],
            ),
            if (item.openingDate.trim().isNotEmpty ||
                item.deadline.trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (item.openingDate.trim().isNotEmpty)
                    InstituteDetailBadge(
                      label:
                          '${item.programKeys.isNotEmpty && item.kind == 'admission' ? 'Common opening' : 'Opens'}: ${item.openingDate}',
                      icon: Icons.event_outlined,
                    ),
                  if (item.deadline.trim().isNotEmpty)
                    InstituteDetailBadge(
                      label:
                          '${item.kind == 'scholarship'
                              ? 'Scholarship deadline'
                              : item.kind == 'admission' && item.programKeys.isNotEmpty
                              ? 'Common deadline'
                              : 'Deadline'}: ${item.deadline}',
                      icon: Icons.event_available_outlined,
                    ),
                ],
              ),
            ],
            if (item.feeDetails.trim().isNotEmpty)
              _summary('Fee', item.feeDetails),
            if (item.coverage.trim().isNotEmpty)
              _summary('Coverage', item.coverage),
            if (hasMore)
              ExpansionTile(
                key: PageStorageKey('listing-details-${item.kind}-${item.id}'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 10),
                title: const Text(
                  'More details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                children: [
                  for (final entry
                      in InstituteProgramRequirements.metadataLabels.entries)
                    if (item.programDetails[entry.key]?.trim().isNotEmpty ??
                        false)
                      _expandedLine(
                        entry.value,
                        item.programDetails[entry.key]!,
                      ),
                  for (final entry
                      in InstituteProgramRequirements.labels.entries)
                    if (item.requirements[entry.key]?.trim().isNotEmpty ??
                        false)
                      _expandedLine(entry.value, item.requirements[entry.key]!),
                  if (item.requirements['minScore']?.isNotEmpty ?? false)
                    const Text(
                      'Meeting minimum eligibility does not guarantee admission.',
                    ),
                  if (item.eligibility.trim().isNotEmpty)
                    _expandedLine('Eligibility', item.eligibility),
                  if (item.deliveryMode.trim().isNotEmpty)
                    _expandedLine('Mode', item.deliveryMode),
                  if (item.provider.trim().isNotEmpty)
                    _expandedLine('Provider', item.provider),
                  if (item.description.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.description,
                          style: const TextStyle(height: 1.45),
                        ),
                      ),
                    ),
                ],
              ),
            if (showLinkedPrograms &&
                item.kind == 'admission' &&
                item.programKeys.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Programs in this intake',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              for (final key in item.programKeys)
                Builder(
                  builder: (_) {
                    final resolved = item.forProgram(
                      key,
                      InstituteOpportunityRepository.instance.baselineFor(
                        item.instituteId,
                        key,
                      ),
                    );
                    return ExpansionTile(
                      key: PageStorageKey('admission-program:${item.id}:$key'),
                      tilePadding: EdgeInsets.zero,
                      title: Text(InstituteProgramRequirements.name(key)),
                      subtitle: Text(
                        '${InstituteProgramRequirements.group(key)} · ${resolved.statusAt()}${resolved.deadline.isEmpty ? '' : ' · Deadline: ${resolved.deadline}'}${item.programOverrides[key]?.isNotEmpty ?? false ? ' · Customized requirements' : ''}',
                      ),
                      children: [
                        InstituteOpportunityCard(
                          item: resolved,
                          showLinkedPrograms: false,
                        ),
                      ],
                    );
                  },
                ),
            ],
            if (item.applicationUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => InstituteDetailActions.openExternal(
                    context,
                    item.applicationUrl,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(
                    item.kind == 'course'
                        ? 'Official program information'
                        : status == 'open'
                        ? 'Apply on official website'
                        : 'Official announcement',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summary(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );
  Widget _expandedLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text('$label: $value'),
    ),
  );
}
