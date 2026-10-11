import '../../../../core/models/education_record.dart';
import '../../data/education_repository.dart';
import '../../../../core/widgets/user_identity.dart';
import 'package:flutter/material.dart';
import '../../data/institute_access.dart';
import '../../data/institute_repository.dart';
import '../../data/student_affiliation_repository.dart';
import '../../../models/institute.dart';

class StudentVerificationsScreen extends StatefulWidget {
  final String instituteId;
  const StudentVerificationsScreen({super.key, required this.instituteId});
  @override
  State<StudentVerificationsScreen> createState() =>
      _StudentVerificationsScreenState();
}

class _StudentVerificationsScreenState
    extends State<StudentVerificationsScreen> {
  late Future<Institute?> _institute;
  @override
  void initState() {
    super.initState();
    _institute = InstituteRepository.instance.loadById(widget.instituteId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student verification requests')),
    body: FutureBuilder<Institute?>(
      future: _institute,
      builder: (context, instituteSnapshot) {
        if (instituteSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final institute = instituteSnapshot.data;
        if (institute == null || !InstituteAccess.canManage(institute)) {
          return const Center(
            child: Text(
              'Only this institute’s authorized representative can review requests.',
            ),
          );
        }
        return Column(
          children: [
            _historyRequests(institute),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: StudentAffiliationRepository.instance.requests(
                  institute,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load student requests.'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final requests = snapshot.data!;
                  if (requests.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'No pending requests from previous app versions.',
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        institute.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Approve only students whose enrollment you have confirmed. Their profile will show the current verified student badge.',
                      ),
                      const SizedBox(height: 12),
                      for (final request in requests)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UserIdentity(
                                  uid:
                                      (request['studentId'] ??
                                              request['id'] ??
                                              '')
                                          .toString(),
                                  name: (request['studentName'] ?? 'Student')
                                      .toString(),
                                ),
                                Text(
                                  (request['program'] ?? 'Program not provided')
                                      .toString(),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _review(
                                        institute,
                                        request,
                                        EducationVerification.rejected,
                                      ),
                                      child: const Text('Decline'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () => _review(
                                        institute,
                                        request,
                                        EducationVerification.approved,
                                      ),
                                      icon: const Icon(Icons.school_outlined),
                                      label: const Text('Approve student'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _historyRequests(Institute institute) =>
      StreamBuilder<List<EducationRecord>>(
        stream: EducationRepository.instance.instituteRecords(
          institute.id,
          includePending: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Could not load education requests.'),
            );
          }
          final records = (snapshot.data ?? [])
              .where(
                (r) =>
                    r.status == EducationStatus.current &&
                    r.verification == EducationVerification.pending,
              )
              .toList();
          if (records.isEmpty) return const SizedBox.shrink();
          return Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Current enrollment requests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final record in records)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserIdentity(uid: record.userId, name: 'Student'),
                          Text(record.program),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final status in [
                                EducationVerification.rejected,
                                EducationVerification.approved,
                              ])
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await EducationRepository.instance.review(
                                        institute,
                                        record,
                                        status,
                                      );
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                  child: Text(
                                    status == EducationVerification.approved
                                        ? 'Approve current student'
                                        : 'Decline',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Future<void> _review(
    Institute institute,
    Map<String, dynamic> request,
    String status,
  ) async {
    try {
      await StudentAffiliationRepository.instance.review(
        institute,
        (request['studentId'] ?? request['id']).toString(),
        status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == EducationVerification.approved
                  ? 'Student affiliation verified.'
                  : 'Request declined.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }
}
