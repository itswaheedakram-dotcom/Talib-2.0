import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_HomeItem>[
      _HomeItem('News Feed', Icons.rss_feed, '/community'),
      _HomeItem('Institutes', Icons.school, '/institutes'),
      _HomeItem('Scholarships', Icons.card_giftcard, '/scholarships'),
      _HomeItem('Courses', Icons.menu_book, '/courses'),
      _HomeItem('Seminars', Icons.event, '/seminars'),
      _HomeItem('Hostels', Icons.hotel, '/hostels'),
      _HomeItem('Internships', Icons.work, '/internships'),
      _HomeItem('Jobs', Icons.business_center, '/jobs'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        const Text(
          'Welcome to Talib 2.0',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 5),
        const Text(
          'Find everything you need for your education and career.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => context.push('/find'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 92,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 38),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finding Institute?',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                      SizedBox(height: 5),
                      Text('Find an institute near you',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Explore',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: EdgeInsets.zero,
              elevation: 1.5,
              child: InkWell(
                onTap: () => context.push(item.route),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(item.icon, color: const Color(0xFF2196F3), size: 27),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Card(
          margin: EdgeInsets.zero,
          elevation: 1.5,
          child: InkWell(
            onTap: () => context.push('/community'),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.people, color: Color(0xFF2196F3)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Community', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        Text('Connect with students and share your ideas.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeItem {
  final String title;
  final IconData icon;
  final String route;

  const _HomeItem(this.title, this.icon, this.route);
}
