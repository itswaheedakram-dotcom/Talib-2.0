import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/hostel.dart';
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
    HostelManagerPermissions.basicInfo: true,
    HostelManagerPermissions.location: true,
    HostelManagerPermissions.pricing: true,
    HostelManagerPermissions.rooms: true,
    HostelManagerPermissions.availability: true,
    HostelManagerPermissions.photos: false,
    HostelManagerPermissions.facilities: false,
    HostelManagerPermissions.rules: false,
    HostelManagerPermissions.contact: false,
  };
  bool _saving = false;
  Hostel? _hostel;

  @override
  void initState() {
    super.initState();
    _loadHostel();
  }

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadHostel() async {
    Hostel? hostel;
    if (FirebaseService.initialized) {
      try {
        hostel = await _repository.getHostel(widget.hostelId);
      } catch (_) {}
    }
    hostel ??= HostelRepository.demoHostels.where((item) => item.id == widget.hostelId).firstOrNull;
    if (!mounted) return;
    setState(() => _hostel = hostel);
  }

  String? get _currentUid {
    final active = ActiveProfileController.instance.active;
    if (active != null) return active.id;
    return FirebaseService.initialized ? FirebaseAuth.instance.currentUser?.uid : null;
  }

  bool get _isOwner => _hostel != null && _currentUid != null && _hostel!.ownerId == _currentUid;

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager could not be added.')));
      }
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
              children: HostelManagerPermissions.labels.entries.map((entry) {
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  value: values[entry.key] == true,
                  onChanged: (value) => setDialogState(() => values[entry.key] = value),
                );
              }).toList(),
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
    if (_hostel == null) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    if (!_isOwner) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Only the hostel owner can manage manager access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Hostel Managers')),
      body: StreamBuilder<List<HostelManager>>(
        stream: _repository.watchManagers(widget.hostelId),
        builder: (context, snapshot) {
          final managers = snapshot.data ?? const <HostelManager>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text(
                'Manager access',
                style: TextStyle(color: AppColors.darkGreen, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Owner remains the only person who controls ownership and manager access.',
                style: TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _uidController,
                decoration: const InputDecoration(
                  labelText: 'Manager user ID',
                  hintText: 'Firebase UID or demo profile ID',
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Manager name',
                  hintText: 'Optional display name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              ...HostelManagerPermissions.labels.entries.map((entry) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  value: _permissions[entry.key] == true,
                  onChanged: (value) => setState(() => _permissions[entry.key] = value == true),
                );
              }),
              FilledButton.icon(
                onPressed: _saving ? null : _addManager,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: const Text('Add manager'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Current managers',
                style: TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (managers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No managers have been added yet.'),
                  ),
                )
              else
                ...managers.map((manager) {
                  return Card(
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
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
