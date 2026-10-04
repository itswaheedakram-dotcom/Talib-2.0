import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/section_card.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final features = [
      ('Institutes','Explore schools, colleges and universities',Icons.school_outlined,'/institutes'),
      ('Find Now','Find an institute by your needs',Icons.location_searching,'/find'),
      ('Scholarships','Discover scholarship opportunities',Icons.workspace_premium_outlined,'/scholarships'),
      ('Courses','Explore courses and programs',Icons.menu_book_outlined,'/courses'),
      ('Seminars','Upcoming educational seminars',Icons.event_outlined,'/seminars'),
      ('Hostels','Find student accommodation',Icons.hotel_outlined,'/hostels'),
      ('Internships','Start your professional journey',Icons.work_outline,'/internships'),
      ('Jobs','Explore student and graduate jobs',Icons.business_center_outlined,'/jobs'),
    ];
    return SafeArea(child: CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20,24,20,12),
        sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Talib 2.0', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Your education companion'),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.newspaper_outlined)),
            const SizedBox(width: 14),
            const Expanded(child: Text('Stay updated with educational news and opportunities.')),
            IconButton(onPressed: () => context.push('/community'), icon: const Icon(Icons.arrow_forward)),
          ]))),
          const SizedBox(height: 18),
          Text('Explore', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
        ])),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: features.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => SectionCard(
            title: features[i].$1, subtitle: features[i].$2, icon: features[i].$3,
            onTap: () => context.push(features[i].$4),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]));
  }
}
