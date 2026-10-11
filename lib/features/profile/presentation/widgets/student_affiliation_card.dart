import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
import '../../../institutes/data/student_affiliation_repository.dart';

export 'education_history_card.dart'
    show StudentAffiliationCard, VerifiedStudentCount;

/// Read-only compatibility view. New edits use canonical education history.
class LegacyStudentAffiliationCard extends StatelessWidget {
  final String uid;
  final bool editable;
  const LegacyStudentAffiliationCard({
    super.key,
    required this.uid,
    this.editable = false,
  });
  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
    stream: StudentAffiliationRepository.instance.watchProfile(uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Could not load the previous institute.'),
          ),
        );
      }
      if (!snapshot.hasData) return const SizedBox.shrink();
      final profile = snapshot.data!;
      final name = (profile[ProfileFields.instituteName] ?? '').toString();
      if (name.isEmpty) return const SizedBox.shrink();
      final program = (profile[ProfileFields.course] ?? '').toString();
      final approved = profile[ProfileFields.affiliationStatus] == 'approved';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current institute',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              InkWell(
                onTap: () => context.push(
                  '/institute/${profile[ProfileFields.instituteId]}',
                ),
                child: Text(name),
              ),
              if (program.isNotEmpty) Text(program),
              if (approved)
                Chip(
                  avatar: Icon(
                    Icons.school_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: const Text('Current verified student'),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .12),
                ),
            ],
          ),
        ),
      );
    },
  );
}
