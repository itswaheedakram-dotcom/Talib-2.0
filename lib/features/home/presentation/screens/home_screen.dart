import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      color: AppColors.legacyCream,
      child: Column(
        children: [
          _hero(context),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.legacyCream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => expanded = !expanded),
                    child: Container(
                      width: 38,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.homeGreen,
                        size: 20,
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 132,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisExtent: 60,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 2,
                        ),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return InkWell(
                            onTap: () => context.push(item.route),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(13),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.cardShadow,
                                        blurRadius: 7,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(item.icon, color: AppColors.homeGreen, size: 23),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.homeMutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.90,
                        child: _compactBanners(context),
                      ),
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

  Widget _hero(BuildContext context) {
    return Container(
      height: 245,
      decoration: const BoxDecoration(
        color: AppColors.homeGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (drawerContext) => IconButton(
                  onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                  icon: const Icon(Icons.menu_rounded, color: AppColors.white, size: 27),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_rounded, color: AppColors.white, size: 27),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.format_quote_rounded, color: AppColors.homeAccent, size: 34),
          const SizedBox(height: 1),
          const Text(
            'If you cannot do great things, do small things\nin a great way!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontSize: 15, height: 1.25, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('- Napoleon Hill', style: TextStyle(color: AppColors.authorAccent, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 5),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.favorite_border_rounded, color: AppColors.white, size: 23),
              SizedBox(width: 18),
              Icon(Icons.share_rounded, color: AppColors.white, size: 23),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactBanners(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 82, child: _findBanner(context)),
        const SizedBox(height: 7),
        SizedBox(height: 82, child: _guidanceBanner(context)),
      ],
    );
  }

  Widget _findBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/find'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 6, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.homeGreen,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Finding Institute?', style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w500)),
                  SizedBox(height: 3),
                  Text('Find an institute suitable to\nyour needs and eligibility', style: TextStyle(color: AppColors.white70, fontSize: 10, height: 1.15)),
                  SizedBox(height: 5),
                  DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.actionAccent, borderRadius: BorderRadius.all(Radius.circular(18))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Find Now', style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(color: AppColors.findBubble, shape: BoxShape.circle),
              child: const Icon(Icons.person_search_rounded, color: AppColors.white, size: 46),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guidanceBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/community'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: AppColors.homeGreen,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.guidanceBubble,
                borderRadius: BorderRadius.all(Radius.circular(45)),
              ),
              child: const Icon(Icons.groups_rounded, color: AppColors.darkGreen, size: 45),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Need Guidance?', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  SizedBox(height: 3),
                  Text('Ask other people to help you\nin Community', style: TextStyle(color: AppColors.white70, fontSize: 10, height: 1.15)),
                  SizedBox(height: 5),
                  DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.actionAccent, borderRadius: BorderRadius.all(Radius.circular(18))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: AppColors.white, size: 14),
                          SizedBox(width: 3),
                          Text('Join Now', style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
