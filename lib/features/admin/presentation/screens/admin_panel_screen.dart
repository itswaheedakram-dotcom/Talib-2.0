import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/admin_access_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _access = AdminAccessService.instance;

  static const _managerPermissions = <String, String>{
    'view_dashboard': 'View platform dashboard',
    'manage_institutes': 'Manage institute listings',
    'manage_hostels': 'Manage hostel listings',
    'ownership_claim_review': 'Review institute/hostel claims',
    'moderate_posts': 'Moderate community posts',
    'manage_reports': 'Process user reports',
    'view_audit_logs': 'View admin activity logs',
  };

  Future<void> _showCreateManagerDialog() async {
    final uidController = TextEditingController();
    final selected = <String, bool>{
      'view_dashboard': true,
      'manage_institutes': false,
      'manage_hostels': false,
      'ownership_claim_review': false,
      'moderate_posts': false,
      'manage_reports': false,
      'view_audit_logs': false,
    };
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Manager Admin'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter the UID of an existing Firebase user.'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: uidController,
                      decoration: const InputDecoration(
                        labelText: 'Firebase user UID',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'UID is required.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Permissions', style: TextStyle(fontWeight: FontWeight.w700)),
                    ..._managerPermissions.entries.map((entry) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: selected[entry.key] == true,
                      title: Text(entry.value),
                      onChanged: (value) => setDialogState(
                        () => selected[entry.key] = value ?? false,
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Create manager'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) {
      uidController.dispose();
      return;
    }
    try {
      await _access.assignManager(
        uid: uidController.text,
        permissions: selected,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manager Admin access assigned.')),
        );
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create manager: $error')),
        );
      }
    } finally {
      uidController.dispose();
    }
  }

  Future<int> _count(String collection) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).count().get();
    return snapshot.count ?? 0;
  }

  Widget _stat(String label, String collection, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 25),
              const SizedBox(height: 10),
              FutureBuilder<int>(
                future: _count(collection),
                builder: (context, snapshot) => Text(
                  snapshot.hasError ? '—' : snapshot.hasData ? '${snapshot.data}' : '…',
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.softGreen,
          child: Icon(icon, color: AppColors.darkGreen),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _managerSection() {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: _access.managers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ListTile(title: Text('Could not load managers.'));
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!;
        if (docs.isEmpty) return const ListTile(title: Text('No Manager Admins assigned yet.'));
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final status = (data['status'] ?? 'active').toString();
            return ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text(doc.id, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('Status: $status'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  try {
                    await _access.setManagerStatus(doc.id, value);
                    if (mounted) setState(() {});
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not update manager: $error')),
                      );
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'active', child: Text('Activate')),
                  PopupMenuItem(value: 'suspended', child: Text('Suspend')),
                  PopupMenuItem(value: 'revoked', child: Text('Revoke access')),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDemoPanel(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                label: const Text('Demo Super Admin'),
                backgroundColor: AppColors.softGreen,
                labelStyle: const TextStyle(color: AppColors.darkGreen),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Demo administration', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Waheed Akram is Super Admin in Demo Mode. These tools are isolated from Firebase and real user data.',
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined, color: AppColors.darkGreen),
              title: const Text('Demo identity active'),
              subtitle: const Text('Profile ID: demo-user-6 • Profile handle: waheed'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security_outlined, color: AppColors.darkGreen),
              title: const Text('Permission boundary'),
              subtitle: const Text(
                'Demo Super Admin cannot create Firebase Manager Admins, approve real claims, or modify real platform records.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Admin modules', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          _section(
            'Hostel Ownership Claims',
            'Review, approve or reject demo hostel ownership requests',
            Icons.hotel_outlined,
            () => context.push('/admin/hostel-claims'),
          ),
          _section(
            'Institute Claims',
            'Demo-safe ownership review',
            Icons.school_outlined,
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demo institute-claim workflow is not connected yet. No Firebase data was changed.')),
            ),
          ),
          _section(
            'Community Moderation',
            'Demo-safe moderation tools',
            Icons.forum_outlined,
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demo moderation workflow is not connected yet. No Firebase data was changed.')),
            ),
          ),
          _section(
            'Reports & Audit Log',
            'Demo-only administrative history',
            Icons.history_rounded,
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demo reports and audit history are not connected yet. No Firebase data was changed.')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _access,
      builder: (context, _) {
        if (_access.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!_access.canOpenPanel) {
          return const Scaffold(
            body: Center(child: Text('Admin access is not assigned to this account.')),
          );
        }
        if (_access.isDemoSuperAdmin) return _buildDemoPanel(context);
        final canReviewClaims = _access.can('ownership_claim_review');
        final canManageInstitutes = _access.can('manage_institutes');
        final canManageHostels = _access.can('manage_hostels');
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Chip(
                    label: Text(_access.isSuperAdmin ? 'Super Admin' : 'Manager Admin'),
                    backgroundColor: AppColors.softGreen,
                    labelStyle: const TextStyle(color: AppColors.darkGreen),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _access.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _access.isSuperAdmin ? 'Platform overview' : 'Manager workspace',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text('Administrative tools and platform activity.'),
                const SizedBox(height: 12),
                if (_access.isSuperAdmin || _access.can('view_dashboard'))
                  Row(
                    children: [
                      _stat('Users', 'users', Icons.people_alt_outlined),
                      _stat('Institutes', 'institutes', Icons.school_outlined),
                    ],
                  ),
                if (_access.isSuperAdmin || _access.can('view_dashboard'))
                  Row(
                    children: [
                      _stat('Hostels', 'hostels', Icons.hotel_outlined),
                      _stat('Reports', 'reports', Icons.flag_outlined),
                    ],
                  ),
                const SizedBox(height: 12),
                if (_access.isSuperAdmin) ...[
                  const Text('Platform administration', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _section('Manager Admins', 'Create, suspend or revoke manager access', Icons.admin_panel_settings_outlined, _showCreateManagerDialog),
                  _managerSection(),
                ],
                if (canReviewClaims || _access.isSuperAdmin)
                  _section('Institute Claims', 'Review institute ownership requests', Icons.school_outlined, () => context.push('/admin/institute-claims')),
                if (canReviewClaims || _access.isSuperAdmin)
                  _section('Hostel Ownership Claims', 'Review hostel ownership requests', Icons.hotel_outlined, () => context.push('/admin/hostel-claims')),
                if (_access.isSuperAdmin || _access.can('moderate_posts'))
                  _section('Community Moderation', 'Review reported community content', Icons.forum_outlined, () => context.push('/admin/reports')),
                if (_access.isSuperAdmin || _access.can('manage_reports'))
                  _section('User Reports', 'Process platform reports', Icons.flag_outlined, () => context.push('/admin/reports')),
                if (_access.isSuperAdmin || _access.can('view_audit_logs'))
                  _section('Audit Log', 'Review administrative activity', Icons.history_rounded, () => context.push('/admin/audit-logs')),
              ],
            ),
          ),
        );
      },
    );
  }
}
