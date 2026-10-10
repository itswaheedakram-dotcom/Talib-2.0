import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/institute_access.dart';
import '../../data/institute_claim_repository.dart';

class InstituteDashboardScreen extends StatelessWidget {
  const InstituteDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    if (InstituteAccess.uid == null) return const Scaffold(body: Center(child: Text('Activate a demo profile or sign in.')));
    return Scaffold(appBar: AppBar(title: const Text('Institute Dashboard')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: InstituteClaimRepository.instance.watch(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not load your institutes.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final claims = snapshot.data!.where((claim) => claim['status'] == 'approved').toList();
          if (claims.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No approved institute claims yet.'),
            TextButton(onPressed: () => context.go('/institutes'), child: const Text('Browse Institutes')),
          ]));
          return ListView(padding: const EdgeInsets.all(16), children: claims.map((claim) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
            title: Text((claim['instituteName'] ?? 'Institute').toString()),
            subtitle: Text(InstituteAccess.isDemo ? 'Demo ownership approved' : 'Verified representative'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/institute-admin/${claim['id']}'),
          ))).toList());
        },
      ),
    );
  }
}
