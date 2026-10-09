import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../data/institute_catalog.dart';
import '../../../models/institute.dart';
import '../../data/institute_repository.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/database_service.dart';

class InstituteDetailScreen extends StatelessWidget {
  final String id;
  const InstituteDetailScreen({super.key, required this.id});

  static const green = AppColors.primaryGreen;
  static const darkGreen = AppColors.darkGreen;
  static const lightGreen = AppColors.softGreen;

  @override Widget build(BuildContext context) {
    final institute = InstituteRepository.instance.byId(id);
    if (institute == null) return const Scaffold(body: Center(child: Text('Institute not found')));
    final typeLabel = InstituteCatalog.instance.labelFor(institute.type);
    final image = institute.imageUrl.isNotEmpty ? institute.imageUrl : institute.type == 'schools'
        ? 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=1200&q=80'
        : institute.type == 'colleges'
            ? 'https://images.unsplash.com/photo-1564981797816-1043664bf78d?auto=format&fit=crop&w=1200&q=80'
            : 'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=1200&q=80';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        title: Text(typeLabel),
        actions: [
          if (ActiveProfileController.instance.isDemo || (FirebaseAuth.instance.currentUser?.uid == institute.ownerId && institute.ownerId.isNotEmpty))
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/institute/${institute.id}/edit')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 185,
              child: Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                color: lightGreen,
                child: const Icon(Icons.account_balance, size: 70, color: green),
              )),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(institute.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: darkGreen)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 17, color: green),
                const SizedBox(width: 3),
                Expanded(child: Text(institute.address, style: const TextStyle(color: Colors.black54))),
              ]),
            ])),
            IconButton(
              tooltip: 'Open location in Maps',
              onPressed: () => _openExternal(
                context,
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent([institute.address, institute.city, institute.province].where((part) => part.trim().isNotEmpty).join(', '))}',
                missingMessage: 'Add an institute address before opening Maps.',
              ),
              icon: const Icon(Icons.location_on_outlined, color: green),
            ),
            if (ActiveProfileController.instance.isDemo &&
                ActiveProfileController.instance.effectiveUid != null)
              StreamBuilder<bool>(
                stream: DatabaseService().instituteBookmarkStream(
                  ActiveProfileController.instance.effectiveUid!,
                  institute.id,
                ),
                builder: (context, snapshot) => IconButton(
                  tooltip: snapshot.data == true ? 'Remove bookmark' : 'Save institute',
                  onPressed: () => DatabaseService().toggleInstituteBookmark(
                    ActiveProfileController.instance.effectiveUid!,
                    institute.id,
                    snapshot.data != true,
                  ),
                  icon: Icon(snapshot.data == true ? Icons.bookmark : Icons.bookmark_border, color: green),
                ),
              )
            else if (FirebaseAuth.instance.currentUser != null)
              StreamBuilder<bool>(
                stream: DatabaseService().instituteBookmarkStream(
                  FirebaseAuth.instance.currentUser!.uid,
                  institute.id,
                ),
                builder: (context, snapshot) => IconButton(
                  tooltip: snapshot.data == true ? 'Remove bookmark' : 'Save institute',
                  onPressed: () async {
                    try {
                      await DatabaseService().toggleInstituteBookmark(
                        FirebaseAuth.instance.currentUser!.uid,
                        institute.id,
                        snapshot.data != true,
                      );
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Bookmark could not be updated: $error')),
                        );
                      }
                    }
                  },
                  icon: Icon(snapshot.data == true ? Icons.bookmark : Icons.bookmark_border, color: green),
                ),
              )
            else
              IconButton(
                tooltip: 'Sign in to save',
                onPressed: () => context.push('/signin'),
                icon: const Icon(Icons.bookmark_border, color: green),
              ),
          ]),
          const SizedBox(height: 10),
          Card(
            color: lightGreen,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.campaign_outlined, color: green),
                const SizedBox(width: 8),
                const Expanded(child: Text('Admissions', style: TextStyle(fontWeight: FontWeight.w700, color: darkGreen))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: institute.admissionStatus.toLowerCase() == 'open' ? green : Colors.orange, borderRadius: BorderRadius.circular(14)),
                  child: Text(institute.admissionStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          _section('Institute Information', Column(children: [
            _info(Icons.info_outline, 'About', institute.description),
            _info(Icons.location_on_outlined, 'City', institute.city),
            _info(Icons.account_balance_outlined, 'Type', typeLabel),
            _info(Icons.location_city_outlined, 'Campus', institute.campus.isEmpty ? 'Not provided' : institute.campus),
            _info(Icons.map_outlined, 'Province', institute.province.isEmpty ? 'Not provided' : institute.province),
            _info(Icons.business_outlined, 'Sector', institute.sector),
            _info(Icons.phone_outlined, 'Contact', institute.contact.isEmpty ? 'Not provided' : institute.contact),
            _info(Icons.language_outlined, 'Website', institute.website.isEmpty ? 'Not provided' : institute.website),
          ])),
          const SizedBox(height: 10),
          _section('Admission', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              _admissionBadge('Status', institute.admissionStatus),
              if (institute.admissionDeadline.isNotEmpty) _admissionBadge('Deadline', institute.admissionDeadline),
              if (institute.feeRange.isNotEmpty) _admissionBadge('Fee', institute.feeRange),
              _admissionBadge('Entry Test', institute.entryTestRequired ? 'Required' : 'Not required'),
              _admissionBadge('Apply', institute.submissionMode),
              if (institute.minScore > 0) _admissionBadge('Minimum Score', institute.minScore.toString()),
              if (institute.eligibility.isNotEmpty) _admissionBadge('Eligibility', institute.eligibility),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 7, runSpacing: 7, children: institute.programs.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(18)),
              child: Text(p, style: const TextStyle(color: darkGreen, fontWeight: FontWeight.w600)),
            )).toList()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => context.push('/institute/' + institute.id + '/programs'),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Programs'),
              )),
              const SizedBox(width: 9),
              Expanded(child: FilledButton(
                onPressed: () {
                  final target = institute.applicationUrl.trim().isNotEmpty
                      ? institute.applicationUrl.trim()
                      : institute.website.trim();
                  if (target.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No official application link is available yet. Please contact the institute.')),
                    );
                  } else {
                    _openExternal(context, target);
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: green),
                child: Text(institute.applicationUrl.trim().isNotEmpty ? 'Apply Now' : 'Website / Details'),
              )),
            ]),
            const SizedBox(height: 9),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () => context.push('/institute/' + institute.id + '/community?name=' + Uri.encodeComponent(institute.name)),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Institute Community'),
            )),
          ])),
          const SizedBox(height: 10),
          _section('Facilities', institute.facilities.isEmpty
              ? const Text('No facilities added yet.')
              : Column(children: institute.facilities.map((f) => _Facility(Icons.check_circle_outline, f)).toList())),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseService.initialized && !ActiveProfileController.instance.isDemo && FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance.collection('instituteClaims').where('instituteId', isEqualTo: institute.id).where('representativeId', isEqualTo: FirebaseAuth.instance.currentUser!.uid).where('status', isEqualTo: 'pending').limit(1).snapshots()
                : const Stream.empty(),
            builder: (context, snap) {
              final pending = snap.data?.docs.isNotEmpty == true;
              final signedIn = FirebaseService.initialized && FirebaseAuth.instance.currentUser != null;
              return Card(child: ListTile(
                leading: Icon(pending ? Icons.hourglass_top : Icons.business_outlined, color: green),
                title: Text(pending ? 'Claim under review' : 'Manage this institute'),
                subtitle: Text(pending ? 'Waiting for admin verification.' : 'Institute representatives can claim this profile.'),
                trailing: pending ? null : FilledButton(
                  onPressed: signedIn
                      ? () async { if (ActiveProfileController.instance.isDemo) { await DatabaseService().claimDemoInstitute(ActiveProfileController.instance.effectiveUid!,institute.id); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Demo claim recorded for the active test profile.'))); } else { context.push('/institute/' + institute.id + '/claim?name=' + Uri.encodeComponent(institute.name)); } }
                      : () => context.push('/signin'),
                  style: FilledButton.styleFrom(backgroundColor: green),
                  child: Text(signedIn ? 'Claim' : 'Sign In'),
                ),
              ));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openExternal(
    BuildContext context,
    String rawUrl, {
    String? missingMessage,
  }) async {
    if (rawUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(missingMessage ?? 'No link is available for this institute yet.')),
      );
      return;
    }
    var uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This link is not valid.')),
      );
      return;
    }
    if (!uri.hasScheme) uri = Uri.tryParse('https://${rawUrl.trim()}');
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link on your device.')),
        );
      }
    }
  }

  static Widget _section(String title, Widget child) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkGreen)),
      const SizedBox(height: 9),
      child,
    ])),
  );

  static Widget _admissionBadge(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(10)),
    child: RichText(text: TextSpan(children: [
      TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: darkGreen)),
      TextSpan(text: value, style: const TextStyle(color: Colors.black87)),
    ])),
  );

  static Widget _info(IconData icon, String title, String value) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: green),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(value),
  );
}

class _Facility extends StatelessWidget {
  final IconData icon;
  final String title;
  const _Facility(this.icon, this.title);
  @override Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: InstituteDetailScreen.green),
    title: Text(title),
  );
}
