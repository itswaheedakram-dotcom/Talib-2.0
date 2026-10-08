import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_review.dart';
import '../../data/hostel_manager.dart';
import '../../data/hostel_seed_data.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../models/hostel.dart';

class HostelDetailScreen extends StatefulWidget {
  final Hostel hostel;

  const HostelDetailScreen({super.key, required this.hostel});

  @override
  State<HostelDetailScreen> createState() => _HostelDetailScreenState();
}

class _HostelDetailScreenState extends State<HostelDetailScreen> {
  int _galleryIndex = 0;
  double _myRating = 0;
  HostelReview? _myReview;
  bool _loadingReview = false;
  bool _savingReview = false;
  HostelManager? _managerAccess;
  final TextEditingController _commentController = TextEditingController();

  Hostel get hostel => widget.hostel;

  List<String> get images {
    final values = <String>[];
    for (final value in hostel.imageUrls) {
      if (value.trim().isNotEmpty && !values.contains(value.trim())) {
        values.add(value.trim());
      }
    }
    if (hostel.imageUrl.trim().isNotEmpty &&
        !values.contains(hostel.imageUrl.trim())) {
      values.insert(0, hostel.imageUrl.trim());
    }
    return values;
  }

  ActiveProfileController get _identity => ActiveProfileController.instance;
  bool get _demoIdentity => _identity.isDemoActive;
  String? get _effectiveUid {
    if (_demoIdentity) return _identity.effectiveUid;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
  String get _effectiveName {
    if (_demoIdentity) return _identity.effectiveName ?? 'Demo Member';
    try {
      final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
      return name == null || name.isEmpty ? 'Member' : name;
    } catch (_) {
      return 'Member';
    }
  }

  bool get _isOwner {
    if (hostel.ownerId.isEmpty) return false;
    final uid = _effectiveUid;
    return uid != null && uid == hostel.ownerId;
  }

  bool get _canManage => _isOwner || _managerAccess != null;


  bool get signedIn {
    if (_demoIdentity || hostel.isDemo) return _effectiveUid != null;
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMyReview();
    _loadManagementAccess();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadManagementAccess() async {
    final uid = _effectiveUid;
    if (uid == null || hostel.id.isEmpty || uid == hostel.ownerId) return;
    try {
      final manager = await HostelRepository().managerAccess(hostel.id, uid);
      if (!mounted) return;
      setState(() => _managerAccess = manager);
    } catch (_) {
      // Management access is optional; keep the public hostel view available.
    }
  }

  Future<void> _loadMyReview() async {
    if ((!signedIn && !hostel.isDemo) || hostel.id.isEmpty) return;
    setState(() => _loadingReview = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = _effectiveUid ?? '';
      if (userId.isEmpty) return;
      final review = (_demoIdentity || hostel.isDemo || !FirebaseService.initialized)
          ? await HostelRepository.demoMyReview(hostel.id, userId)
          : await HostelRepository().getMyReview(hostel.id, userId);
      if (!mounted) return;
      setState(() {
        _myReview = review;
        _myRating = review?.rating ?? 0;
        _commentController.text = review?.comment ?? '';
      });
    } catch (_) {
      // Review data is optional. Never block hostel details.
    } finally {
      if (mounted) setState(() => _loadingReview = false);
    }
  }

  Stream<List<HostelReview>> _reviewStream() {
    if (hostel.id.isEmpty) return const Stream<List<HostelReview>>.empty();
    try {
      return hostel.isDemo
          ? HostelRepository.demoReviewStream(hostel.id)
          : HostelRepository().watchReviews(hostel.id);
    } catch (_) {
      return const Stream<List<HostelReview>>.empty();
    }
  }

  Future<void> _saveReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_effectiveUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to review this hostel.')),
      );
      return;
    }
    if (_myRating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating.')),
      );
      return;
    }

    setState(() => _savingReview = true);
    try {
      if (_demoIdentity || hostel.isDemo || !FirebaseService.initialized) {
        await HostelRepository.submitDemoReview(
          hostelId: hostel.id,
          userId: _effectiveUid!,
          userName: _effectiveName,
          rating: _myRating,
          comment: _commentController.text.trim(),
        );
      } else {
        await HostelRepository().submitReview(
          hostelId: hostel.id,
          userId: user!.uid,
          userName: _effectiveName,
          rating: _myRating,
          comment: _commentController.text.trim(),
        );
      }
      await _loadMyReview();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your review has been saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review could not be saved.')),
      );
    } finally {
      if (mounted) setState(() => _savingReview = false);
    }
  }

  Future<void> _openWebsite() async {
    var value = hostel.website.trim();
    if (value.isEmpty) return;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps() async {
    final query = hostel.address.trim().isNotEmpty
        ? hostel.address.trim()
        : <String>[hostel.area, hostel.city].where((e) => e.trim().isNotEmpty).join(', ');
    if (query.isEmpty) return;
    final uri = Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': query,
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone() async {
    final value = hostel.phone.trim();
    final uri = Uri(scheme: 'tel', path: value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await _copyPhone();
    }
  }

  Future<void> _copyPhone() async {
    await Clipboard.setData(ClipboardData(text: hostel.phone));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gallery = images;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Hostel Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Text(
            hostel.name,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (hostel.reviewCount > 0) ...[
            const SizedBox(height: 6),
            _ratingSummary(hostel.rating, hostel.reviewCount),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (hostel.isDemo || hostel.ownerId.isEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/hostel/' + Uri.encodeComponent(hostel.id) + '/claim?name=' + Uri.encodeComponent(hostel.name)),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Claim Hostel'),
                  ),
                ),
              if (_canManage) ...[
                if (hostel.isDemo || hostel.ownerId.isEmpty) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/hostel/' + Uri.encodeComponent(hostel.id) + '/manage'),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Manage'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _quickHighlights(),
          const SizedBox(height: 14),
          _gallery(gallery),
          const SizedBox(height: 4),
          _sectionTitle('Location'),
          _infoCard([
            if (hostel.address.isNotEmpty)
              _infoRow(Icons.location_on_outlined, 'Address', hostel.address),
            if (hostel.area.isNotEmpty || hostel.city.isNotEmpty)
              _infoRow(
                Icons.place_outlined,
                'Area',
                [hostel.area, hostel.city]
                    .where((e) => e.isNotEmpty)
                    .join(', '),
              ),
            if (hostel.distance.isNotEmpty)
              _infoRow(
                Icons.near_me_outlined,
                'Distance',
                hostel.distance,
              ),
            if (hostel.address.isNotEmpty || hostel.area.isNotEmpty || hostel.city.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
                ),
              ),
          ]),
          _sectionTitle('Complete Details'),
          _infoCard([
            if (hostel.type.isNotEmpty)
              _infoRow(Icons.apartment_outlined, 'Hostel Type', hostel.type),
            if (hostel.gender.isNotEmpty)
              _infoRow(Icons.people_outline, 'For', hostel.gender),
            if (hostel.roomType.isNotEmpty)
              _infoRow(Icons.bed_outlined, 'Room Type', hostel.roomType),
            if (hostel.availability.isNotEmpty)
              _infoRow(
                Icons.event_available_outlined,
                'Availability',
                hostel.availability,
              ),
            if (hostel.price.isNotEmpty)
              _infoRow(Icons.payments_outlined, 'Monthly Rent', hostel.price),
            if (hostel.securityFee.isNotEmpty)
              _infoRow(
                Icons.account_balance_wallet_outlined,
                'Security Fee',
                hostel.securityFee,
              ),
            _infoRow(
              Icons.ac_unit_outlined,
              'Air Conditioning',
              hostel.ac ? 'Available' : 'Not available',
            ),
            if (hostel.meals.isNotEmpty)
              _infoRow(Icons.restaurant_outlined, 'Meals / Mess', hostel.meals),
          ]),
          if (hostel.rooms.isNotEmpty) ...[
            _sectionTitle('Rooms & Pricing'),
            _roomsCard(),
          ],
          if (hostel.facilities.isNotEmpty) ...[
            _sectionTitle('Facilities'),
            _infoCard([
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: hostel.facilities
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]),
          ],
          if (hostel.rules.isNotEmpty) ...[
            _sectionTitle('Hostel Rules'),
            _rulesCard(),
          ],
          if (hostel.description.isNotEmpty) ...[
            _sectionTitle('About Hostel'),
            _infoCard([
              Text(
                hostel.description,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ]),
          ],
          if (hostel.ownerName.isNotEmpty && !hostel.isDemo) ...[
            _sectionTitle('Listed By'),
            _infoCard([
              _infoRow(Icons.person_outline, 'Owner', hostel.ownerName),
            ]),
          ],
          _sectionTitle('Reviews'),
          _reviewsCard(),
          if (hostel.phone.isNotEmpty || hostel.website.isNotEmpty) ...[
            _sectionTitle('Contact'),
            _infoCard([
              if (hostel.phone.isNotEmpty)
                _contactButton(
                  Icons.phone_outlined,
                  hostel.phone,
                  _callPhone,
                ),
              if (hostel.phone.isNotEmpty && hostel.website.isNotEmpty)
                const SizedBox(height: 8),
              if (hostel.website.isNotEmpty)
                _contactButton(
                  Icons.language_outlined,
                  hostel.website,
                  _openWebsite,
                ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _gallery(List<String> values) {
    return Container(
      height: 235,
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: values.isEmpty
          ? const Center(
              child: Icon(
                Icons.hotel_rounded,
                color: AppColors.primaryGreen,
                size: 72,
              ),
            )
          : Stack(
              children: [
                PageView.builder(
                  itemCount: values.length,
                  onPageChanged: (index) {
                    if (mounted) setState(() => _galleryIndex = index);
                  },
                  itemBuilder: (_, index) {
                    return Image.network(
                      values[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.primaryGreen,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
                if (values.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        values.length,
                        (dot) => Container(
                          width: dot == _galleryIndex ? 18 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: dot == _galleryIndex
                                ? AppColors.white
                                : AppColors.white70,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
  Widget _quickHighlights() {
    final highlights = <Widget>[
      if (hostel.price.isNotEmpty) _highlight(Icons.payments_outlined, hostel.price, 'Monthly'),
      if (hostel.roomType.isNotEmpty) _highlight(Icons.bed_outlined, hostel.roomType, 'Room'),
      if (hostel.gender.isNotEmpty) _highlight(Icons.people_outline, hostel.gender, 'For'),
      if (hostel.availability.isNotEmpty) _highlight(Icons.event_available_outlined, hostel.availability, 'Available'),
      if (hostel.ac) _highlight(Icons.ac_unit_outlined, 'AC', 'Room'),
    ];
    if (highlights.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: highlights);
  }

  Widget _highlight(IconData icon, String value, String label) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.primaryGreen, size: 19),
        const SizedBox(width: 7),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 10)),
          const SizedBox(height: 2),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.darkGreen, fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      ]),
    );
  }

  Widget _roomsCard() {
    return _infoCard([
      ...hostel.rooms.map((room) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(room.type.isEmpty ? 'Room' : room.type, style: const TextStyle(color: AppColors.darkGreen, fontSize: 15, fontWeight: FontWeight.w700))), if (room.ac) _tagPill('AC')]),
            const SizedBox(height: 8),
            Wrap(spacing: 14, runSpacing: 7, children: [
              if (room.rent.isNotEmpty) _roomMeta('Rent', room.rent),
              if (room.securityFee.isNotEmpty) _roomMeta('Security', room.securityFee),
              if (room.totalBeds > 0) _roomMeta('Beds', '${room.availableBeds}/${room.totalBeds} available'),
            ]),
            if (room.notes.isNotEmpty) ...[const SizedBox(height: 8), Text(room.notes, style: const TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.35))],
          ]),
        ),
      )),
    ]);
  }

  Widget _roomMeta(String label, String value) => RichText(text: TextSpan(children: [TextSpan(text: '$label\n', style: const TextStyle(color: AppColors.mutedText, fontSize: 10)), TextSpan(text: value, style: const TextStyle(color: AppColors.darkGreen, fontSize: 12, fontWeight: FontWeight.w700))]));

  Widget _tagPill(String value) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(8)), child: Text(value, style: const TextStyle(color: AppColors.darkGreen, fontSize: 10, fontWeight: FontWeight.w700)));

  Widget _rulesCard() => _infoCard(hostel.rules.map((rule) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 18), const SizedBox(width: 9), Expanded(child: Text(rule, style: const TextStyle(color: AppColors.mutedText, fontSize: 13, height: 1.35)))]))).toList());
  Widget _reviewsCard() {
    return StreamBuilder<List<HostelReview>>(
      stream: _reviewStream(),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <HostelReview>[];

        return _infoCard([
          Row(
            children: [
              _ratingSummary(hostel.rating, hostel.reviewCount),
              const Spacer(),
              if (signedIn)
                TextButton(
                  onPressed: _loadingReview ? null : _showReviewEditor,
                  child: Text(
                    _myReview == null ? 'Write review' : 'Edit review',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (snapshot.hasError)
            const Text(
              'Reviews are temporarily unavailable.',
              style: TextStyle(color: AppColors.mutedText),
            )
          else if (reviews.isEmpty)
            const Text(
              'No reviews yet. Be the first member to review this hostel.',
              style: TextStyle(
                color: AppColors.mutedText,
                height: 1.4,
              ),
            )
          else
            ...reviews.take(8).map(
              (review) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.userName,
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _stars(review.rating),
                      ],
                    ),
                    if (review.comment.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          review.comment,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ]);
      },
    );
  }

  Future<void> _showReviewEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Review',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          onPressed: () {
                            setSheetState(() => _myRating = index + 1.0);
                          },
                          icon: Icon(
                            index < _myRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.primaryGreen,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Review',
                      hintText: 'Share your experience',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: _savingReview ? null : _saveReview,
                      child: Text(
                        _savingReview ? 'Saving...' : 'Submit review',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label\n',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingSummary(double rating, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          color: AppColors.primaryGreen,
          size: 19,
        ),
        const SizedBox(width: 3),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : 'New',
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        if (count > 0)
          Text(
            ' ($count)',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _stars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating.round()
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          color: AppColors.primaryGreen,
          size: 16,
        ),
      ),
    );
  }

  Widget _contactButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class HostelDetailLoaderScreen extends StatelessWidget {
  final String hostelId;

  const HostelDetailLoaderScreen({
    super.key,
    required this.hostelId,
  });

  Future<Hostel?> _load() async {
    try {
      final remote = await HostelRepository().getHostel(hostelId);
      if (remote != null) return remote;
    } catch (_) {
      // Use local demo data when Firebase is unavailable.
    }

    for (final hostel in exampleHostels) {
      if (hostel.id == hostelId) return hostel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Hostel?>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
          );
        }

        final hostel = snapshot.data;
        if (hostel == null) {
          return Scaffold(
            backgroundColor: AppColors.cream,
            appBar: AppBar(title: const Text('Hostel Details')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Hostel details could not be loaded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ),
            ),
          );
        }

        return HostelDetailScreen(hostel: hostel);
      },
    );
  }
}
