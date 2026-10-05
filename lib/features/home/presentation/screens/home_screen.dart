import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const green = Color(0xFF00A878);
  static const darkGreen = Color(0xFF00543D);
  static const cream = Color(0xFFF8F8F2);
  bool expanded = true;

  static const items = [
    _HomeItem('News Feed', Icons.article_outlined, '/newsfeed'),
    _HomeItem('Institutes', Icons.account_balance_outlined, '/institutes'),
    _HomeItem('Scholarships', Icons.school_outlined, '/scholarships'),
    _HomeItem('Courses', Icons.card_membership_outlined, '/courses'),
    _HomeItem('Seminars', Icons.co_present_outlined, '/seminars'),
    _HomeItem('Hostels', Icons.hotel_outlined, '/hostels'),
    _HomeItem('Internships', Icons.badge_outlined, '/internships'),
    _HomeItem('Jobs', Icons.work_outline_rounded, '/jobs'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cream,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _hero(context),
          Transform.translate(
            offset: const Offset(0, -1),
            child: Container(
              decoration: const BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => expanded = !expanded),
                    child: Icon(
                      expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: green,
                      size: 30,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: expanded
                        ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisExtent: 112,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 4,
                            ),
                            itemBuilder: (context, i) {
                              final item = items[i];
                              return InkWell(
                                onTap: () => context.push(item.route),
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 74,
                                      height: 74,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4))],
                                      ),
                                      child: Icon(item.icon, color: green, size: 39),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(item.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF8B8B8B))),
                                  ],
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  _findBanner(context),
                  const SizedBox(height: 16),
                  _guidanceBanner(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      height: 390,
      decoration: const BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (drawerContext) => IconButton(
                  onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 31),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 31),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.format_quote_rounded, color: Color(0xFF22F1A5), size: 48),
          const SizedBox(height: 4),
          const Text(
            'If you cannot do great things, do small things\nin a great way!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 19, height: 1.35, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 22),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('- Napoleon Hill', style: TextStyle(color: Color(0xFF1EF0A1), fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Icon(Icons.favorite_border_rounded, color: Colors.white, size: 29),
              SizedBox(width: 26),
              Icon(Icons.share_rounded, color: Colors.white, size: 29),
            ],
          ),
        ],
      ),
    );
  }

  Widget _findBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/find'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 205,
        padding: const EdgeInsets.fromLTRB(24, 22, 18, 20),
        decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Finding Institute?', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w500)),
                SizedBox(height: 7),
                Text('Find an institute that is most suitable\nto your needs and eligibility', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.25)),
                SizedBox(height: 15),
                DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF13E7A2), borderRadius: BorderRadius.all(Radius.circular(25))),
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_rounded, color: Colors.white, size: 18), SizedBox(width: 6), Text('Find Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))])),
                ),
              ]),
            ),
            Container(width: 110, height: 150, decoration: const BoxDecoration(color: Color(0x2233FFB0), shape: BoxShape.circle), child: const Icon(Icons.person_search_rounded, color: Colors.white, size: 78)),
          ],
        ),
      ),
    );
  }

  Widget _guidanceBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/community'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 190,
        padding: const EdgeInsets.fromLTRB(20, 20, 22, 20),
        decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Container(width: 105, height: 145, decoration: const BoxDecoration(color: Color(0xFFBFECDD), borderRadius: BorderRadius.all(Radius.circular(70))), child: const Icon(Icons.groups_rounded, color: darkGreen, size: 72)),
            const SizedBox(width: 16),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Need Guidance?', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w500)),
              SizedBox(height: 7),
              Text('Ask other people to help you out\nin Community', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
              SizedBox(height: 14),
              DecoratedBox(decoration: BoxDecoration(color: Color(0xFF13E7A2), borderRadius: BorderRadius.all(Radius.circular(25))), child: Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, color: Colors.white, size: 19), SizedBox(width: 5), Text('Join Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]))),
            ])),
          ],
        ),
      ),
    );
  }
}

class _HomeItem {
  final String title;
  final IconData icon;
  final String route;
  const _HomeItem(this.title, this.icon, this.route);
}
