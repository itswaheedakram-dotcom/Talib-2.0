import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../models/institute_opportunity.dart';

/// Shared listing content for institute details and the management screen.
class InstituteOpportunityCard extends StatelessWidget {
  final InstituteOpportunity item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InstituteOpportunityCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = item.status.toLowerCase() == 'open'
        ? AppColors.primaryGreen
        : item.status.toLowerCase() == 'closed' ||
              item.status.toLowerCase() == 'cancelled'
        ? AppColors.mutedText
        : AppColors.darkGreen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
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
            if (item.academicYear.isNotEmpty || item.intake.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                [
                  item.academicYear,
                  item.intake,
                ].where((value) => value.isNotEmpty).join(' • '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (item.openingDate.isNotEmpty || item.deadline.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (item.openingDate.isNotEmpty)
                    _detailPill('Opens', item.openingDate),
                  if (item.deadline.isNotEmpty)
                    _detailPill(
                      item.kind == 'scholarship'
                          ? 'Scholarship deadline'
                          : 'Deadline',
                      item.deadline,
                    ),
                ],
              ),
            ],
            if (item.eligibility.isNotEmpty)
              _detailLine('Eligibility', item.eligibility),
            if (item.feeDetails.isNotEmpty) _detailLine('Fee', item.feeDetails),
            if (item.coverage.isNotEmpty)
              _detailLine('Coverage', item.coverage),
            if (item.deliveryMode.isNotEmpty)
              _detailLine('Mode', item.deliveryMode),
            if (item.provider.isNotEmpty)
              _detailLine('Provider', item.provider),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.description),
            ],
            if (item.applicationUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _openExternal(context, item.applicationUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Apply / View details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Text('$label: $value'),
  );

  Widget _detailPill(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.softGreen,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
    ),
  );

  Future<void> _openExternal(BuildContext context, String rawUrl) async {
    if (rawUrl.trim().isEmpty) return;
    var uri = Uri.tryParse(rawUrl.trim());
    if (uri != null && !uri.hasScheme)
      uri = Uri.tryParse('https://${rawUrl.trim()}');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open this link on your device.'),
          ),
        );
      }
    }
  }
}
