import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/institute.dart';
import '../../data/institute_catalog.dart';
import '../../data/institute_repository.dart';

class AdminInstituteSubmissionsScreen extends StatefulWidget {
  const AdminInstituteSubmissionsScreen({super.key});

  @override
  State<AdminInstituteSubmissionsScreen> createState() => _AdminInstituteSubmissionsScreenState();
}

class _AdminInstituteSubmissionsScreenState extends State<AdminInstituteSubmissionsScreen> {
  final _repository = InstituteRepository.instance;
  final _catalog = InstituteCatalog.instance;
  bool get _demoMode => ActiveProfileController.instance.isDemo || !FirebaseService.initialized;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onChanged);
    _catalog.addListener(_onChanged);
    _catalog.load();
    _repository.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_onChanged);
    _catalog.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _review(String id, String status) async {
    try {
      final success = await _repository.setSubmissionStatus(id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? (status == 'approved' ? 'Institute approved and published.' : 'Institute submission rejected.')
            : (_repository.error ?? 'Could not update institute status.')),
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not review submission: $error')),
        );
      }
    }
  }

  Widget _card(Institute institute) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            backgroundColor: AppColors.softGreen,
            child: Icon(_catalog.iconFor(institute.type), color: AppColors.darkGreen),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(institute.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 3),
            Text([
              _catalog.labelFor(institute.type),
              if (institute.subcategory.isNotEmpty) institute.subcategory,
              if (institute.city.isNotEmpty) institute.city,
            ].join(' • ')),
          ])),
          const SizedBox(width: 6),
          const Chip(label: Text('Pending')),
        ]),
        if (institute.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(institute.description, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
        if (institute.programs.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text('Programs: ${institute.programs.take(4).join(', ')}'),
        ],
        if (institute.createdBy.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text('Submitted by: ${institute.createdBy}', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _review(institute.id, 'rejected'),
            child: const Text('Reject'),
          )),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(
            onPressed: () => _review(institute.id, 'approved'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Approve & Publish'),
          )),
        ]),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_demoMode) {
      final pending = _repository.moderationItems
          .where((item) => item.status.toLowerCase() == 'pending')
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Institute Submissions')),
        body: pending.isEmpty
            ? const _EmptySubmissions()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Demo submissions are isolated from Firebase.', style: TextStyle(color: AppColors.darkGreen)),
                  const SizedBox(height: 12),
                  ...pending.map(_card),
                ],
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Institute Submissions')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('institutes')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load submissions. Check admin permissions and try again.'),
            ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const _EmptySubmissions();
          final items = docs.map((doc) => Institute.fromMap(doc.id, doc.data())).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items.map(_card).toList(),
          );
        },
      ),
    );
  }
}

class _EmptySubmissions extends StatelessWidget {
  const _EmptySubmissions();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.fact_check_outlined, size: 58, color: AppColors.primaryGreen),
        SizedBox(height: 12),
        Text('No pending institute submissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('New institute suggestions will appear here for review.', textAlign: TextAlign.center),
      ]),
    ),
  );
}
