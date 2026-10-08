import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../models/hostel.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_manager.dart';
import '../../data/hostel_seed_data.dart';

class HostelManagementScreen extends StatefulWidget {
  final String hostelId;

  const HostelManagementScreen({super.key, required this.hostelId});

  @override
  State<HostelManagementScreen> createState() => _HostelManagementScreenState();
}

class _HostelManagementScreenState extends State<HostelManagementScreen> {
  Hostel? _hostel;
  bool _loading = true;
  bool _saving = false;
  HostelManager? _managerAccess;
  HostelManager? _manager;
  final _availability = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _availability.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Hostel? hostel;
    if (FirebaseService.initialized) {
      try {
        hostel = await HostelRepository().getHostel(widget.hostelId);
      } catch (_) {}
    }
    if (hostel == null) {
      for (final item in HostelRepository.demoHostels) {
        if (item.id == widget.hostelId) {
          hostel = item;
          break;
        }
      }
    }
    HostelManager? manager;
    final active = ActiveProfileController.instance.active;
    final user = FirebaseService.initialized ? FirebaseAuth.instance.currentUser : null;
    final uid = active?.id ?? user?.uid;
    if (hostel != null && uid != null && uid != hostel.ownerId) {
      try {
        manager = await HostelRepository().getManager(hostel.id, uid);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _hostel = hostel;
      _manager = manager;
      _availability.text = hostel?.availability ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final hostel = _hostel;
    if (hostel == null) return;
    final active = ActiveProfileController.instance.active;
    final user = FirebaseService.initialized ? FirebaseAuth.instance.currentUser : null;
    final effectiveUid = active?.id ?? user?.uid;
    final isOwner = effectiveUid != null && effectiveUid == hostel.ownerId;
    final canEditAvailability = isOwner || (_manager?.can('availability') == true);
    if (!canEditAvailability) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You do not have permission to update hostel availability.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = Hostel(
        id: hostel.id,
        name: hostel.name,
        city: hostel.city,
        area: hostel.area,
        type: hostel.type,
        gender: hostel.gender,
        distance: hostel.distance,
        price: hostel.price,
        securityFee: hostel.securityFee,
        roomType: hostel.roomType,
        availability: _availability.text.trim(),
        meals: hostel.meals,
        ac: hostel.ac,
        facilities: hostel.facilities,
        imageUrls: hostel.imageUrls,
        description: hostel.description,
        phone: hostel.phone,
        website: hostel.website,
        imageUrl: hostel.imageUrl,
        address: hostel.address,
        ownerId: hostel.ownerId,
        ownerName: hostel.ownerName,
        status: hostel.status,
        isVerified: hostel.isVerified,
        isDemo: hostel.isDemo,
        rating: hostel.rating,
        reviewCount: hostel.reviewCount,
        ratingTotal: hostel.ratingTotal,
        rooms: hostel.rooms,
        rules: hostel.rules,
      );
      await HostelRepository.updateHostelSafe(updated);
      if (!mounted) return;
      setState(() => _hostel = updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hostel availability updated.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hostel could not be updated.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool isOwnerLabel(Hostel hostel) {
    final active = ActiveProfileController.instance.active;
    final user = FirebaseService.initialized ? FirebaseAuth.instance.currentUser : null;
    return (active?.id ?? user?.uid) == hostel.ownerId;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.cream, body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)));
    }
    final hostel = _hostel;
    if (hostel == null) {
      return const Scaffold(backgroundColor: AppColors.cream, body: Center(child: Text('Hostel not found.')));
    }
    final active = ActiveProfileController.instance.active;
    final user = FirebaseService.initialized ? FirebaseAuth.instance.currentUser : null;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Manage Hostel')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(hostel.name, style: const TextStyle(color: AppColors.darkGreen, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(isOwnerLabel(hostel) ? 'Owner management' : 'Manager access', style: const TextStyle(color: AppColors.mutedText)),
          const SizedBox(height: 18),
          TextField(
            controller: _availability,
            decoration: const InputDecoration(labelText: 'Availability', hintText: 'e.g. 6 beds available', prefixIcon: Icon(Icons.event_available_outlined)),
          ),
          const SizedBox(height: 14),
          if (hostel.rooms.isNotEmpty)
            ...hostel.rooms.map((room) => Card(
              color: AppColors.white,
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.bed_outlined, color: AppColors.primaryGreen),
                title: Text(room.type),
                subtitle: Text(room.availableBeds.toString() + '/' + room.totalBeds.toString() + ' beds available'),
              ),
            )),
          const SizedBox(height: 12),
          if ((active?.id ?? user?.uid) == hostel.ownerId)
            OutlinedButton.icon(
              onPressed: () => context.push('/hostel/' + Uri.encodeComponent(hostel.id) + '/managers'),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Manage managers'),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.white),
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.save_outlined),
            label: const Text('Save changes'),
          ),
          const SizedBox(height: 10),
          if (isOwnerLabel(hostel)) ...[
            OutlinedButton.icon(
              onPressed: () => context.push('/hostel/' + Uri.encodeComponent(hostel.id) + '/managers'),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Manage managers'),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () => context.push('/hostel/' + Uri.encodeComponent(hostel.id), extra: hostel),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('View public profile'),
          ),
        ],
      ),
    );
  }
}