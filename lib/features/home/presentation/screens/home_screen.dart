import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const green = Color(0xFF00A66A);
  static const darkGreen = Color(0xFF00543D);
  static const lightGreen = Color(0xFFEAF8F2);

  @override
  Widget build(BuildContext context) {
    const items = [
      _HomeItem('News Feed', Icons.rss_feed_rounded, '/newsfeed'),
      _HomeItem('Institutes', Icons.school_rounded, '/institutes'),
      _HomeItem('Scholarships', Icons.card_giftcard_rounded, '/scholarships'),
      _HomeItem('Courses', Icons.menu_book_rounded, '/courses'),
      _HomeItem('Seminars', Icons.event_rounded, '/seminars'),
      _HomeItem('Hostels', Icons.hotel_rounded, '/hostels'),
      _HomeItem('Internships', Icons.work_outline_rounded, '/internships'),
      _HomeItem('Jobs', Icons.business_center_outlined, '/jobs'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
      children: [
        Row(children: [
          const Expanded(child: Text('If you cannot greet things, do small things\nin a great way!', style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.35))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: darkGreen)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3))]),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 12, childAspectRatio: .9),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => context.push(item.route),
                borderRadius: BorderRadius.circular(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 45, height: 45, decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(12)), child: Icon(item.icon, color: green, size: 23)),
                  const SizedBox(height: 6),
                  Text(item.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => context.push('/find'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 112,
            padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
            decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Finding institute?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 5),
                Text('Find an institute that suits you\nand get directions easily.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35)),
                SizedBox(height: 8),
                Text('Find Now  →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ])),
              Container(width: 72, height: 72, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.school_rounded, color: Colors.white, size: 42)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => context.push('/community'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              _CommunityIcon(),
              SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Need Guidance?', style: TextStyle(color: darkGreen, fontSize: 17, fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('Ask students and professionals in our community.', style: TextStyle(color: Colors.black54, fontSize: 12))])),
              Icon(Icons.arrow_forward_ios_rounded, size: 17, color: darkGreen),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CommunityIcon extends StatelessWidget {
  const _CommunityIcon();
  @override
  Widget build(BuildContext context) => Container(width: 62, height: 62, decoration: BoxDecoration(color: HomeScreen.green, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.groups_rounded, color: Colors.white, size: 32));
}

class _HomeItem {
  final String title;
  final IconData icon;
  final String route;
  const _HomeItem(this.title, this.icon, this.route);
}
