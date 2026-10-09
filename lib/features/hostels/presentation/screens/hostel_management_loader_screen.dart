import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../models/hostel.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_seed_data.dart';
import 'hostel_managers_screen.dart';
import 'manage_hostel_screen.dart';

/// Resolves a hostel before opening a management screen. This also supports
/// deep links that do not carry a GoRouter [extra] object.
class HostelManagementLoaderScreen extends StatelessWidget {
  final String hostelId;
  final bool showManagers;

  const HostelManagementLoaderScreen({
    super.key,
    required this.hostelId,
    this.showManagers = false,
  });

  Future<Hostel?> _loadHostel() async {
    try {
      final hostel = await HostelRepository().getHostel(hostelId);
      if (hostel != null) return hostel;
    } catch (_) {
      // Local sample hostels remain available if Firebase is not initialized.
    }

    for (final hostel in exampleHostels) {
      if (hostel.id == hostelId) return hostel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Hostel?>(
      future: _loadHostel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        final hostel = snapshot.data;
        if (hostel == null) {
          return Scaffold(
            backgroundColor: AppColors.cream,
            appBar: AppBar(title: Text(showManagers ? 'Managers' : 'Manage Hostel')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hotel_outlined, size: 44, color: AppColors.primaryGreen),
                    const SizedBox(height: 12),
                    const Text(
                      'Hostel details could not be loaded.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Go back and open the hostel again, or check your connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return showManagers
            ? HostelManagersScreen(hostel: hostel)
            : ManageHostelScreen(hostel: hostel);
      },
    );
  }
}
