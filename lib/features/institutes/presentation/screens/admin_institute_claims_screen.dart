import '../../../../core/widgets/user_identity.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../data/institute_access.dart';
import '../../data/institute_claim_repository.dart';

class AdminInstituteClaimsScreen extends StatelessWidget {
  const AdminInstituteClaimsScreen({super.key});

  Future<void> _review(BuildContext context, String id, String status) async {
    try {
      await InstituteClaimRepository.instance.review(id, status);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim $status.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not review claim: $error')));
    }
  }

  Widget _claimCard(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
    Future<void> Function(String status) onReview,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((data['instituteName'] ?? 'Institute').toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        UserIdentity(uid: (data['representativeId'] ?? '').toString(), name: (data['representativeName'] ?? 'Representative').toString()),
        if ((data['designation'] ?? '').toString().isNotEmpty)
          Text('Designation: ${data['designation']}'),
        if ((data['representativeEmail'] ?? '').toString().isNotEmpty)
          Text('Email: ${data['representativeEmail']}'),
        if ((data['verificationMethod'] ?? '').toString().isNotEmpty)
          Text('Method: ${data['verificationMethod']}'),
        if ((data['verificationDetails'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text((data['verificationDetails'] ?? '').toString()),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => onReview('rejected'),
            child: const Text('Reject'),
          )),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(
            onPressed: () => onReview('approved'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Approve'),
          )),
        ]),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!InstituteAccess.canReviewClaims) return const Scaffold(body: Center(child: Text('Claim review access required.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Institute Claims')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: InstituteClaimRepository.instance.watch(pendingOnly: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not load claims. Please retry.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final claims = snapshot.data!;
          if (claims.isEmpty) return const Center(child: Text('No pending institute claims.'));
          return ListView(padding: const EdgeInsets.all(12), children: [
            if (InstituteAccess.isDemo) const Text('Demo claim reviews never write to Firebase.'),
            ...claims.map((claim) => _claimCard(context, claim, claim['id'].toString(),
              (status) => _review(context, claim['id'].toString(), status))),
          ]);
        },
      ),
    );
  }
}
