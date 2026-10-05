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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _hero(context),
          Transform.translate(
            offset: const Offset(0, -1),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.legacyCream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => expanded = !expanded),
                    child: Container(
                      width: 44,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.homeGreen,
                        size: 24,
                      ),
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
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: AppColors.cardShadow,
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(item.icon, color: AppColors.homeGreen, size: 36),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        item.title,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.homeMutedText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
      height: 370,
      decoration: const BoxDecoration(
        color: AppColors.homeGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (drawerContext) => IconButton(
                  onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                  icon: const Icon(Icons.menu_rounded, color: AppColors.white, size: 30),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_rounded, color: AppColors.white, size: 30),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.format_quote_rounded, color: AppColors.homeAccent, size: 46),
          const SizedBox(height: 4),
          const Text(
            'If you cannot do great things, do small things
in a great way!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontSize: 18, height: 1.35, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('- Napoleon Hill', style: TextStyle(color: AppColors.authorAccent, fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.favorite_border_rounded, color: AppColors.white, size: 28),
              SizedBox(width: 24),
              Icon(Icons.share_rounded, color: AppColors.white, size: 28),
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
        height: 195,
        padding: const EdgeInsets.fromLTRB(22, 20, 16, 18),
        decoration: BoxDecoration(
          color: AppColors.homeGreen,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Finding Institute?', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w500)),
                  SizedBox(height: 7),
                  Text('Find an institute that is most suitable
to your needs and eligibility', style: TextStyle(color: AppColors.white70, fontSize: 13, height: 1.25)),
                  SizedBox(height: 15),
                  DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.actionAccent, borderRadius: BorderRadius.all(Radius.circular(25))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Find Now', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 108,
              height: 146,
              decoration: const BoxDecoration(color: AppColors.findBubble, shape: BoxShape.circle),
              child: const Icon(Icons.person_search_rounded, color: AppColors.white, size: 76),
            ),
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
        height: 180,
        padding: const EdgeInsets.fromLTRB(18, 18, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.homeGreen,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 102,
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.guidanceBubble,
                borderRadius: BorderRadius.all(Radius.circular(70)),
              ),
              child: const Icon(Icons.groups_rounded, color: AppColors.darkGreen, size: 70),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Need Guidance?', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                  SizedBox(height: 7),
                  Text('Ask other people to help you out
in Community', style: TextStyle(color: AppColors.white70, fontSize: 13, height: 1.3)),
                  SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.actionAccent, borderRadius: BorderRadius.all(Radius.circular(25))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: AppColors.white, size: 19),
                          SizedBox(width: 5),
                          Text('Join Now', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
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
