import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/database_service.dart';
import '../../../models/institute.dart';
import '../../data/institute_access.dart';
import '../../data/institute_catalog.dart';
import '../../data/institute_claim_repository.dart';
import '../../data/institute_repository.dart';
import '../../data/institute_score.dart';
import '../widgets/institute_detail_components.dart';
import '../widgets/institute_detail_listings.dart';
import '../widgets/institute_image_preview.dart';

class InstituteDetailScreen extends StatefulWidget {
  final String id;
  const InstituteDetailScreen({super.key, required this.id});

  @override
  State<InstituteDetailScreen> createState() => _InstituteDetailScreenState();
}

class _InstituteDetailScreenState extends State<InstituteDetailScreen> {
  static const _sections = [
    'Overview',
    'Programs',
    'Admissions',
    'Scholarships',
    'Facilities',
    'Contact',
  ];
  final _anchors = {for (final section in _sections) section: GlobalKey()};
  final _navigationKey = GlobalKey();
  final _tabAnchors = {for (final section in _sections) section: GlobalKey()};
  final _scroll = ScrollController();
  String _selected = 'Overview';
  bool _aboutExpanded = false;
  String? _streamIdentity;
  Stream<bool>? _bookmarks;
  Stream<List<Map<String, dynamic>>>? _claims;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackSection);
    InstituteRepository.instance.addListener(_changed);
    ActiveProfileController.instance.addListener(_changed);
  }

  @override
  void didUpdateWidget(InstituteDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _selected = 'Overview';
      _aboutExpanded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _trackSection() {
    final navigation = _navigationKey.currentContext?.findRenderObject();
    if (navigation is! RenderBox) return;
    final top =
        navigation.localToGlobal(Offset.zero).dy + navigation.size.height + 36;
    var selected = 'Overview';
    for (final section in _sections) {
      final box = _anchors[section]?.currentContext?.findRenderObject();
      if (box is RenderBox && box.localToGlobal(Offset.zero).dy <= top)
        selected = section;
    }
    if (_selected != selected && mounted) {
      setState(() => _selected = selected);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tab = _tabAnchors[selected]?.currentContext;
        if (mounted && tab != null) {
          Scrollable.ensureVisible(
            tab,
            duration: const Duration(milliseconds: 180),
          );
        }
      });
    }
  }

  void _jumpTo(String section) {
    final target = _anchors[section]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0,
    );
  }

  void _syncStreams(Institute institute) {
    final uid = InstituteAccess.uid;
    final identity = '${InstituteAccess.isDemo}:$uid:${institute.id}';
    if (_streamIdentity == identity) return;
    _streamIdentity = identity;
    _bookmarks = uid == null
        ? null
        : DatabaseService().instituteBookmarkStream(uid, institute.id);
    _claims = InstituteClaimRepository.instance.watch();
  }

  @override
  void dispose() {
    InstituteRepository.instance.removeListener(_changed);
    ActiveProfileController.instance.removeListener(_changed);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final institute = InstituteRepository.instance.byId(widget.id);
    if (institute == null)
      return const Scaffold(body: Center(child: Text('Institute not found')));
    _syncStreams(institute);
    final catalog = InstituteCatalog.instance;
    final canManage = InstituteAccess.canManage(institute);
    final location = [
      institute.area,
      institute.city,
    ].where((value) => value.trim().isNotEmpty).join(', ');
    final hasLocation =
        institute.address.trim().isNotEmpty || institute.city.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Institute details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          _bookmarkAction(institute),
          IconButton(
            tooltip: 'Copy institute details',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: [
                    institute.name,
                    _address(institute),
                    institute.website,
                  ].where((value) => value.trim().isNotEmpty).join('\n'),
                ),
              );
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Institute details copied.')),
                );
            },
          ),
          if (canManage)
            IconButton(
              tooltip: 'Edit institute',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/institute/${institute.id}/edit'),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            key: _navigationKey,
            height: 54,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final section in _sections)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        key: _tabAnchors[section],
                        label: Text(section),
                        selected: _selected == section,
                        onSelected: (_) => _jumpTo(section),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('institute-detail-scroll'),
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    key: _anchors['Overview'],
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InstituteImagePreview(
                        source: institute.imageUrl,
                        fallbackIcon: catalog.iconFor(institute.type),
                        label: catalog.labelFor(institute.type),
                        height: institute.imageUrl.trim().isEmpty ? 112 : 180,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        institute.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                location,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          InstituteDetailBadge(
                            label: catalog.labelFor(institute.type),
                            icon: catalog.iconFor(institute.type),
                          ),
                          if (institute.sector.trim().isNotEmpty)
                            InstituteDetailBadge(
                              label: institute.sector,
                              icon: Icons.business_outlined,
                            ),
                          if (institute.ownerId.isNotEmpty)
                            const InstituteDetailBadge(
                              label: 'Verified representative',
                              icon: Icons.verified_outlined,
                            ),
                          if (InstituteAccess.isDemo)
                            const InstituteDetailBadge(
                              label: 'Demo',
                              icon: Icons.science_outlined,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (institute.website.trim().isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () =>
                                  InstituteDetailActions.openExternal(
                                    context,
                                    institute.website,
                                  ),
                              icon: const Icon(Icons.language_outlined),
                              label: const Text('Website'),
                            ),
                          if (institute.contact.trim().isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => _contact(institute),
                              icon: Icon(
                                institute.contact.contains('@')
                                    ? Icons.mail_outline
                                    : Icons.call_outlined,
                              ),
                              label: Text(
                                institute.contact.contains('@')
                                    ? 'Email'
                                    : 'Call',
                              ),
                            ),
                          if (hasLocation)
                            OutlinedButton.icon(
                              onPressed: () => _directions(institute),
                              icon: const Icon(Icons.directions_outlined),
                              label: const Text('Directions'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InstituteDetailSection(
                        title: 'About the institute',
                        icon: Icons.info_outline,
                        children: [
                          _about(institute.description),
                          if (institute.subcategory.trim().isNotEmpty)
                            InstituteDetailFact(
                              icon: Icons.category_outlined,
                              label: 'Category',
                              value: institute.subcategory,
                            ),
                          if (institute.campus.trim().isNotEmpty)
                            InstituteDetailFact(
                              icon: Icons.account_balance_outlined,
                              label: 'Campus',
                              value: institute.campus,
                            ),
                          if (institute.board.trim().isNotEmpty)
                            InstituteDetailFact(
                              icon: Icons.school_outlined,
                              label: 'Education board / authority',
                              value: institute.board,
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InstituteDetailListings(
                    institute: institute,
                    sectionKeys: {
                      'course': _anchors['Programs']!,
                      'admission': _anchors['Admissions']!,
                      'scholarship': _anchors['Scholarships']!,
                    },
                    admissionOverview: _admissionRequirements(institute),
                  ),
                  const SizedBox(height: 14),
                  InstituteDetailSection(
                    key: _anchors['Facilities'],
                    title: 'Facilities',
                    icon: Icons.apartment_outlined,
                    children: [
                      if (institute.facilities.isEmpty)
                        const Text('Facilities have not been listed yet.')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: institute.facilities
                              .map(
                                (facility) => InstituteDetailBadge(
                                  label: facility,
                                  icon: Icons.check_circle_outline,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InstituteDetailSection(
                    key: _anchors['Contact'],
                    title: 'Location & contact',
                    icon: Icons.location_on_outlined,
                    children: [
                      if (_address(institute).isNotEmpty)
                        InstituteDetailFact(
                          icon: Icons.place_outlined,
                          label: 'Address',
                          value: _address(institute),
                        ),
                      if (institute.contact.trim().isNotEmpty)
                        InstituteDetailFact(
                          icon: Icons.call_outlined,
                          label: institute.contact.contains('@')
                              ? 'Email'
                              : 'Phone',
                          value: institute.contact,
                        ),
                      if (institute.website.trim().isNotEmpty)
                        InstituteDetailFact(
                          icon: Icons.language_outlined,
                          label: 'Official website',
                          value: institute.website,
                        ),
                      if (institute.contact.trim().isEmpty &&
                          institute.website.trim().isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Direct contact details have not been added yet.',
                          ),
                        ),
                      if (hasLocation)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _directions(institute),
                            icon: const Icon(Icons.directions_outlined),
                            label: const Text('Open in Maps'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InstituteDetailSection(
                    title: 'Institute community',
                    icon: Icons.forum_outlined,
                    children: [
                      const Text(
                        'Connect with students and discuss life at this institute.',
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/institute/${institute.id}/community?name=${Uri.encodeComponent(institute.name)}',
                          ),
                          icon: const Icon(Icons.forum_outlined),
                          label: const Text('Open community'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ownership(institute),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _about(String description) {
    if (description.trim().isEmpty)
      return const Text('An introduction has not been added yet.');
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(height: 1.45);
        final painter = TextPainter(
          text: TextSpan(text: description, style: style),
          maxLines: 4,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final truncated = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: style,
              maxLines: _aboutExpanded ? null : 4,
              overflow: _aboutExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (truncated)
              TextButton(
                onPressed: () =>
                    setState(() => _aboutExpanded = !_aboutExpanded),
                child: Text(_aboutExpanded ? 'Read less' : 'Read more'),
              ),
          ],
        );
      },
    );
  }

  Widget _bookmarkAction(Institute institute) {
    final uid = InstituteAccess.uid;
    if (uid == null)
      return IconButton(
        tooltip: 'Sign in to save institute',
        icon: const Icon(Icons.bookmark_border),
        onPressed: () => context.push('/signin'),
      );
    return StreamBuilder<bool>(
      stream: _bookmarks,
      builder: (context, snapshot) => IconButton(
        tooltip: snapshot.data == true ? 'Remove bookmark' : 'Save institute',
        icon: Icon(
          snapshot.data == true ? Icons.bookmark : Icons.bookmark_border,
        ),
        onPressed: () async {
          try {
            await DatabaseService().toggleInstituteBookmark(
              uid,
              institute.id,
              snapshot.data != true,
            );
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    snapshot.data == true
                        ? 'Institute removed from saved.'
                        : 'Institute saved.',
                  ),
                ),
              );
          } catch (_) {
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not update bookmark. Please retry.'),
                ),
              );
          }
        },
      ),
    );
  }

  Widget _admissionRequirements(Institute institute) => ExpansionTile(
    key: PageStorageKey('requirements-${institute.id}'),
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 12),
    title: const Text(
      'General admission requirements',
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: Text('Check each intake below for its announcement and dates.'),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          if (institute.admissionStatus.trim().isNotEmpty)
            InstituteDetailBadge(
              label: 'General status: ${institute.admissionStatus}',
            ),
          InstituteDetailBadge(
            label:
                'Entry test: ${institute.entryTestRequired ? 'Required' : 'Not required'}',
          ),
          if (institute.submissionMode.trim().isNotEmpty)
            InstituteDetailBadge(label: 'Apply: ${institute.submissionMode}'),
          if (institute.feeRange.trim().isNotEmpty)
            InstituteDetailBadge(label: 'Fee: ${institute.feeRange}'),
          if (institute.minScore > 0)
            InstituteDetailBadge(
              label:
                  'Minimum score: ${InstituteScore.display(institute.minScore, institute.scoreScale)}',
            ),
        ],
      ),
      if (institute.eligibility.trim().isNotEmpty)
        InstituteDetailFact(
          icon: Icons.rule_outlined,
          label: 'Eligibility',
          value: institute.eligibility,
        ),
      if (institute.admissionDeadline.trim().isNotEmpty)
        InstituteDetailFact(
          icon: Icons.event_outlined,
          label: 'General deadline',
          value: institute.admissionDeadline,
        ),
      if (institute.applicationUrl.trim().isNotEmpty)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => InstituteDetailActions.openExternal(
              context,
              institute.applicationUrl,
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Official admissions website'),
          ),
        ),
    ],
  );

  Widget _ownership(
    Institute institute,
  ) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: _claims,
    builder: (context, snapshot) {
      final pending = (snapshot.data ?? const []).any(
        (claim) =>
            claim['instituteId'] == institute.id &&
            claim['status'] == 'pending',
      );
      final owns =
          InstituteAccess.uid != null &&
          InstituteAccess.uid == institute.ownerId;
      final owned = institute.ownerId.isNotEmpty;
      return InstituteDetailSection(
        title: owns
            ? 'Your institute'
            : pending
            ? 'Claim under review'
            : owned
            ? 'Verified representative'
            : 'Represent this institute?',
        icon: pending ? Icons.hourglass_top : Icons.verified_user_outlined,
        children: [
          Text(
            owns
                ? 'Manage your profile, programs and published updates.'
                : pending
                ? 'Your verification details are waiting for admin review.'
                : owned
                ? 'A verified representative manages this institute profile.'
                : 'Submit verification details to manage this institute profile.',
          ),
          if (!pending && (!owned || owns)) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  InstituteAccess.uid == null
                      ? '/signin'
                      : owns
                      ? '/institute/${institute.id}/edit'
                      : '/institute/${institute.id}/claim',
                ),
                icon: Icon(
                  owns ? Icons.edit_outlined : Icons.business_outlined,
                ),
                label: Text(
                  InstituteAccess.uid == null
                      ? 'Sign in to claim'
                      : owns
                      ? 'Manage institute'
                      : 'Claim institute',
                ),
              ),
            ),
          ],
        ],
      );
    },
  );

  String _address(Institute institute) =>
      [
            institute.address,
            institute.area,
            institute.city,
            institute.district,
            institute.province,
            institute.country,
          ]
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .join(', ');
  void _directions(Institute institute) => InstituteDetailActions.openExternal(
    context,
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${institute.name}, ${_address(institute)}')}',
  );
  void _contact(Institute institute) => InstituteDetailActions.openExternal(
    context,
    institute.contact.contains('@')
        ? 'mailto:${institute.contact.trim()}'
        : 'tel:${institute.contact.trim()}',
  );
}
