import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/hostel_manager.dart';
import '../../data/hostel_repository.dart';

class HostelManagersScreen extends StatefulWidget {
  final String hostelId;
  const HostelManagersScreen({super.key, required this.hostelId});

  @override
  State<HostelManagersScreen> createState() => _HostelManagersScreenState();
}

class _HostelManagersScreenState extends State<HostelManagersScreen> {
  final _uidController = TextEditingController();
  final _nameController = TextEditingController();
  final _repository = HostelRepository();
  final Map<String, bool> _permissions = {
    'basicInfo': true,
    'photos': false,
    'roomsPricing': true,
    'facilitiesMeals': false,
    'rules': false,
    'availability': true,
    'contact': false,
  };
  bool _saving = false;

  static const _labels = <String, String>{
    'basicInfo': 'Basic information',
    'photos': 'Photos',
    'roomsPricing': 'Rooms & pricing',
    'facilitiesMeals': 'Facilities & meals',
    'rules': 'Rules',
    'availability': 'Availability',
    'contact': 'Contact information',
  };

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<String?> _currentUid() async {
    final active = ActiveProfileController.instance.active;
    if (active != null) return active.id;
    return FirebaseService.initialized ? FirebaseAuth.instance.currentUser?.uid : null;
  }

  Future<void> _addManager() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager user ID is required.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.addManager(
        hostelId: widget.hostelId,
        userId: uid,
        userName: _nameController.text.trim(),
        permissions: _permissions,
      );
      if (!mounted) return;
      _uidController.clear();
      _nameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager access added.')));
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager could not be added.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(String userId) async {
    try {
      await _repository.removeManager(widget.hostelId, userId);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager access could not be removed.')));
      }
    }
  }

  Future<void> _editPermissions(HostelManager manager) async {
    final values = Map<String, bool>.from(manager.permissions);
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(manager.userName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _labels.entries.map((entry) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value),
                value: values[entry.key] == true,
                onChanged: (value) => setDialogState(() => values[entry.key] = value),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (changed != true) return;
    try {
      await _repository.updateManagerPermissions(
        hostelId: widget.hostelId,
        userId: manager.userId,
        permissions: values,
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions could not be updated.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ActiveProfileController.instance.active;
    final authUid = FirebaseService.initialized ? FirebaseAuth.instance.currentUser?.uid : null;
    final currentUid = active?.id ?? authUid;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Hostel Managers')),
      body: StreamBuilder<List<HostelManager>>(
        stream: _repository.watchManagers(widget.hostelId),
        builder: (context, snapshot) {
          final managers = snapshot.data ?? const <HostelManager>[];
          final isDemoOwner = active != null;
          final isRealUser = authUid != null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text('Manager access', style: TextStyle(color: AppColors.darkGreen, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Owner remains the only person who controls ownership and manager access.', style: TextStyle(color: AppColors.mutedText)),
              const SizedBox(height: 18),
              TextField(controller: _uidController, decoration: const InputDecoration(labelText: 'Manager user ID', hintText: 'Firebase UID', prefixIcon: Icon(Icons.person_search_outlined))),
              const SizedBox(height: 10),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Manager name', hintText: 'Optional display name', prefixIcon: Icon(Icons.badge_outlined))),
              const SizedBox(height: 12),
              ..._labels.entries.map((entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value),
                value: _permissions[entry.key] == true,
                onChanged: (value) => setState(() => _permissions[entry.key] = value == true),
              )),
              FilledButton.icon(
                onPressed: _saving || (!isDemoOwner && !isRealUser) ? null : _addManager,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.person_add_alt_1),
                label: const Text('Add manager'),
              ),
              const SizedBox(height: 24),
              const Text('Current managers', style: TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (managers.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No managers have been added yet.')))
              else
                ...managers.map((manager) => Card(
                  color: AppColors.white,
                  elevation: 0,
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(manager.userName),
                    subtitle: Text(manager.userId),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'permissions') _editPermissions(manager);
                        if (value == 'remove') _remove(manager.userId);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'permissions', child: Text('Edit permissions')),
                        PopupMenuItem(value: 'remove', child: Text('Remove access')),
                      ],
                    ),
                  ),
                )),
              if (currentUid == null)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Sign in is required for real manager access.', style: TextStyle(color: AppColors.mutedText)),
                ),
            ],
          );
        },
      ),
    );
  }
}
