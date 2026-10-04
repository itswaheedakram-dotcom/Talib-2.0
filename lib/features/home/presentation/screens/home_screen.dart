import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final features = <_HomeFeature>[
      _HomeFeature('Institutes', 'Schools, colleges & universities', Icons.school_rounded, '/institutes'),
      _HomeFeature('Find Now', 'Find the right institute', Icons.location_searching_rounded, '/find'),
      _HomeFeature('Scholarships', 'Funding & opportunities', Icons.workspace_premium_rounded, '/scholarships'),
      _HomeFeature('Courses', 'Programs & learning', Icons.menu_book_rounded, '/courses'),
      _HomeFeature('Seminars', 'Events & seminars', Icons.event_rounded, '/seminars'),
      _HomeFeature('Hostels', 'Student accommodation', Icons.hotel_rounded, '/hostels'),
      _HomeFeature('Internships', 'Gain practical experience', Icons.work_history_rounded, '/internships'),
      _HomeFeature('Jobs', 'Start your career', Icons.business_center_rounded, '/jobs'),
    ];

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.school_rounded, color: colorScheme.onPrimary, size: 25),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome to', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        SizedBox(height: 2),
                        Text('Talib 2.0', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search_rounded),
                    tooltip: 'Search',
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your education,\nall in one place.',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 27,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Discover institutes, opportunities, courses and more.',
                      style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: .86), height: 1.35),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push('/find'),
                      icon: const Icon(Icons.explore_rounded),
                      label: const Text('Find an institute'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Explore', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () => context.push('/institutes'),
                    child: const Text('Institutes'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = features[index];
                  return _FeatureCard(feature: item, onTap: () => context.push(item.route));
                },
                childCount: features.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.16,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Community', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () => context.push('/community'),
                    child: const Text('View all'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push('/community'),
                  child: const Padding(
                    padding: EdgeInsets.all(17),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 25, child: Icon(Icons.forum_rounded)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Educational community', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('Ask questions, share ideas and connect with students.', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _HomeFeature(this.title, this.subtitle, this.icon, this.route);
}

class _FeatureCard extends StatelessWidget {
  final _HomeFeature feature;
  final VoidCallback onTap;

  const _FeatureCard({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(feature.icon, color: colorScheme.primary),
              ),
              const Spacer(),
              Text(feature.title, style: const TextStyle(fontWeight: FontWeight.w750, fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                feature.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
