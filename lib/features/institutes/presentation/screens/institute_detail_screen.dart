import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../data/institute_catalog.dart';
import '../widgets/institute_image_preview.dart';
import '../widgets/institute_detail_listings.dart';
import '../../../models/institute.dart';
import '../../data/institute_repository.dart';
import '../../data/institute_access.dart';
import '../../data/institute_claim_repository.dart';
import '../../data/institute_score.dart';
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
    final image = institute.imageUrl.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        title: Text(typeLabel),
        actions: [
          if (InstituteAccess.canManage(institute))
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/institute/${institute.id}/edit')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        children: [
          InstituteImagePreview(
            source: image,
            fallbackIcon: InstituteCatalog.instance.iconFor(institute.type),
            label: typeLabel,
            height: 185,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(institute.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 17, color: green),
                const SizedBox(width: 3),
                Expanded(child: Text(institute.address, style: const TextStyle(color: AppColors.mutedText))),
              ]),
            ])),
            IconButton(
              tooltip: 'Open location in Maps',
              onPressed: () => _openExternal(
                context,
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent([institute.address, institute.area, institute.city, institute.district, institute.province, institute.country].where((part) => part.trim().isNotEmpty).join(', '))}',
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
            else if (FirebaseService.initialized && FirebaseAuth.instance.currentUser != null)
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
                  decoration: BoxDecoration(color: institute.admissionStatus.toLowerCase() == 'open' ? green : AppColors.statusWarning, borderRadius: BorderRadius.circular(14)),
                  child: Text(institute.admissionStatus.toUpperCase(), style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          _section('Institute Information', Column(children: [
            _info(Icons.info_outline, 'About', institute.description),
            _info(Icons.public_outlined, 'Country', institute.country.isEmpty ? 'Not provided' : institute.country),
            _info(Icons.map_outlined, 'Province / State / Region', institute.province.isEmpty ? 'Not provided' : institute.province),
            if (institute.district.isNotEmpty) _info(Icons.location_city_outlined, 'District / County', institute.district),
            _info(Icons.location_on_outlined, 'City / Town', institute.city),
            if (institute.area.isNotEmpty) _info(Icons.place_outlined, 'Area / Locality', institute.area),
            if (institute.board.isNotEmpty) _info(Icons.account_balance_outlined, 'Education Board / Authority', institute.board),
            _info(Icons.account_balance_outlined, 'Type', typeLabel),
            if (institute.subcategory.isNotEmpty) _info(Icons.category_outlined, 'Subcategory', institute.subcategory),
            _info(Icons.location_city_outlined, 'Campus', institute.campus.isEmpty ? 'Not provided' : institute.campus),
            _info(Icons.business_outlined, 'Sector', institute.sector),
            _info(Icons.phone_outlined, 'Contact', institute.contact.isEmpty ? 'Not provided' : institute.contact),
            _info(Icons.language_outlined, 'Website', institute.website.isEmpty ? 'Not provided' : institute.website),
            if (institute.applicationUrl.isNotEmpty) _info(Icons.open_in_new_outlined, 'Application URL', institute.applicationUrl),
          ])),
          if (institute.website.trim().isNotEmpty || institute.contact.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                if (institute.website.trim().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openExternal(context, institute.website),
                    icon: const Icon(Icons.language_outlined),
                    label: const Text('Open Website'),
                  ),
                if (institute.contact.trim().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openExternal(
                      context,
                      institute.contact.contains('@')
                          ? 'mailto:${institute.contact.trim()}'
                          : 'tel:${institute.contact.trim()}',
                    ),
                    icon: const Icon(Icons.call_outlined),
                    label: Text(institute.contact.contains('@') ? 'Email Institute' : 'Call Institute'),
                  ),
              ]),
            ),
          const SizedBox(height: 10),
          _section('Admission Information', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              _admissionBadge('Status', institute.admissionStatus),
              if (institute.admissionDeadline.isNotEmpty) _admissionBadge('Deadline', institute.admissionDeadline),
              if (institute.feeRange.isNotEmpty) _admissionBadge('Fee', institute.feeRange),
              _admissionBadge('Entry Test', institute.entryTestRequired ? 'Required' : 'Not required'),
              _admissionBadge('Apply', institute.submissionMode),
              if (institute.minScore > 0) _admissionBadge('Minimum Score', InstituteScore.display(institute.minScore, institute.scoreScale)),
              if (institute.eligibility.isNotEmpty) _admissionBadge('Eligibility', institute.eligibility),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(
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
            const SizedBox(height: 9),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () => context.push('/institute/' + institute.id + '/community?name=' + Uri.encodeComponent(institute.name)),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Institute Community'),
            )),
          ])),
          const SizedBox(height: 10),
          InstituteDetailListings(institute: institute),
          const SizedBox(height: 10),
          _section('Facilities', institute.facilities.isEmpty
              ? const Text('No facilities added yet.')
              : Column(children: institute.facilities.map((f) => _Facility(Icons.check_circle_outline, f)).toList())),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: InstituteClaimRepository.instance.watch(),
            builder: (context, snapshot) {
              final pending = (snapshot.data ?? const []).any((claim) => claim['instituteId'] == institute.id && claim['status'] == 'pending');
              final owns = InstituteAccess.uid != null && InstituteAccess.uid == institute.ownerId;
              final owned = institute.ownerId.isNotEmpty;
              return Card(child: ListTile(
                leading: Icon(pending ? Icons.hourglass_top : Icons.business_outlined, color: green),
                title: Text(owns ? 'You manage this institute' : pending ? 'Claim under review' : owned ? 'Institute ownership verified' : 'Claim this institute'),
                subtitle: Text(pending ? 'Waiting for admin verification.' : owns ? 'Manage your institute details and programs.' : owned ? 'This institute has a verified representative.' : 'Submit verification details for admin review.'),
                trailing: pending || (owned && !owns) ? null : FilledButton(
                  onPressed: InstituteAccess.uid == null
                    ? () => context.push('/signin')
                    : owns
                      ? () => context.push('/institute/${institute.id}/edit')
                      : () => context.push('/institute/${institute.id}/claim'),
                  child: Text(InstituteAccess.uid == null ? 'Sign In' : owns ? 'Manage' : 'Claim'),
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

  static Widget _section(String title, Widget child) => Builder(builder: (context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 9),
      child,
    ])),
  ));

  static Widget _admissionBadge(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(10)),
    child: RichText(text: TextSpan(children: [
      TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: darkGreen)),
      TextSpan(text: value, style: const TextStyle(color: AppColors.darkGreen)),
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
