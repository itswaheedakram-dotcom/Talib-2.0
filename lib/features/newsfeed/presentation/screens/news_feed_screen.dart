import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../features/models/institute.dart';
import '../../../../features/models/institute_opportunity.dart';
import '../../../institutes/data/institute_opportunity_repository.dart';
import '../../../institutes/data/institute_repository.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final _opportunities = InstituteOpportunityRepository.instance;
  final _institutes = InstituteRepository.instance;

  @override
  void initState() {
    super.initState();
    _opportunities.addListener(_refresh);
    _institutes.addListener(_refresh);
    _institutes.load();
    _opportunities.loadAll();
  }

  @override
  void dispose() {
    _opportunities.removeListener(_refresh);
    _institutes.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allAdmissions = _opportunities.allItems
        .where((item) => item.kind == 'admission')
        .toList();
    final openAdmissions = allAdmissions.where(_isOpen).toList()
      ..sort(_sortByDeadline);
    final upcomingAdmissions = allAdmissions.where(_isUpcoming).toList()
      ..sort(_sortByOpening);

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Feed'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.campaign_outlined, color: AppColors.darkGreen, size: 25),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Education updates from institutes — current and upcoming admissions in one place.',
                style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600),
              )),
            ]),
          ),
          const SizedBox(height: 14),
          _admissionSection(
            title: 'Admissions Open',
            subtitle: 'Apply now to institutes currently accepting applications.',
            icon: Icons.mark_email_read_outlined,
            items: openAdmissions,
            emptyText: 'No institutes have published currently open admissions.',
            accent: AppColors.primaryGreen,
          ),
          const SizedBox(height: 14),
          _admissionSection(
            title: 'Upcoming Admissions',
            subtitle: 'See admissions that are scheduled to open soon.',
            icon: Icons.event_available_outlined,
            items: upcomingAdmissions,
            emptyText: 'No upcoming admissions have been published yet.',
            accent: AppColors.darkGreen,
          ),
          if (_opportunities.loading || _institutes.loading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (_opportunities.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Could not refresh admissions: ${_opportunities.error}',
                style: const TextStyle(color: AppColors.darkGreen),
              ),
            ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => context.push('/community'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.groups_rounded, color: AppColors.white, size: 32),
                SizedBox(width: 12),
                Expanded(child: Text(
                  'Need guidance? Join the Community',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15),
                )),
                Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _admissionSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<InstituteOpportunity> items,
    required String emptyText,
    required Color accent,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
            color: AppColors.softGreen,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(width: 11),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  )),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.35)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('${items.length}', style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: AppColors.mutedText, size: 19),
                const SizedBox(width: 8),
                Expanded(child: Text(emptyText, style: const TextStyle(height: 1.35))),
              ]),
            )
          else
            ...items.map(_admissionTile),
        ],
      ),
    );
  }

  Widget _admissionTile(InstituteOpportunity item) {
    final institute = _institutes.byId(item.instituteId);
    final instituteName = institute?.name ?? 'Institute';
    final details = <String>[
      if (item.academicYear.isNotEmpty) item.academicYear,
      if (item.intake.isNotEmpty) item.intake,
    ].join(' • ');
    final dateLabel = _isOpen(item) ? 'Deadline' : 'Opens';
    final date = _isOpen(item) ? item.deadline : item.openingDate;

    return InkWell(
      onTap: () => context.push('/institute/${item.instituteId}/opportunities'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.darkGreen),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(instituteName, style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.darkGreen,
              )),
              const SizedBox(height: 3),
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(details, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ],
              if (date.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.primaryGreen),
                  const SizedBox(width: 5),
                  Text('$dateLabel: $date', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],
            ],
          )),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.mutedText),
        ]),
      ),
    );
  }

  bool _isOpen(InstituteOpportunity item) {
    final status = item.status.trim().toLowerCase();
    if (status != 'open') return false;
    final deadline = DateTime.tryParse(item.deadline);
    if (deadline == null) return true;
    final today = DateTime.now();
    return !deadline.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool _isUpcoming(InstituteOpportunity item) {
    final status = item.status.trim().toLowerCase();
    if (status == 'closed' || status == 'cancelled' || status == 'awarded') return false;
    final opening = DateTime.tryParse(item.openingDate);
    final today = DateTime.now();
    final hasFutureOpening = opening != null &&
        opening.isAfter(DateTime(today.year, today.month, today.day));
    return status == 'upcoming' || hasFutureOpening;
  }

  int _sortByDeadline(InstituteOpportunity a, InstituteOpportunity b) {
    final aDate = DateTime.tryParse(a.deadline) ?? DateTime(9999);
    final bDate = DateTime.tryParse(b.deadline) ?? DateTime(9999);
    return aDate.compareTo(bDate);
  }

  int _sortByOpening(InstituteOpportunity a, InstituteOpportunity b) {
    final aDate = DateTime.tryParse(a.openingDate) ?? DateTime(9999);
    final bDate = DateTime.tryParse(b.openingDate) ?? DateTime(9999);
    return aDate.compareTo(bDate);
  }
}
