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
      color: AppPalette.of(context).background,
      child: Column(
        children: [
          _hero(context),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.of(context).background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => expanded = !expanded),
                    child: Container(
                      width: 76,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppPalette.of(context).surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppPalette.of(context).accent,
                        size: 20,
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    SizedBox(height: 3),
                    SizedBox(
                      height: 190,
                      child: GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisExtent: 78,
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
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppPalette.of(context).surface,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cardShadow,
                                        blurRadius: 7,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(item.icon, color: AppPalette.of(context).accent, size: 27),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppPalette.of(context).muted,
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
                  SizedBox(height: 24),
                  FractionallySizedBox(
                    widthFactor: 0.94,
                    child: _compactBanners(context),
                  ),
                  Spacer(),
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
      height: 218,
      decoration: BoxDecoration(
        color: AppPalette.of(context).brandSurface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          SafeArea(
            top: true,
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (drawerContext) => IconButton(
                    onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                    icon: Icon(Icons.menu_rounded, color: AppColors.white, size: 27),
                  ),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                  icon: Icon(Icons.notifications_rounded, color: AppColors.white, size: 27),
                ),
              ],
            ),
          ),
          Spacer(),
          Icon(Icons.format_quote_rounded, color: AppColors.homeAccent, size: 34),
          SizedBox(height: 1),
          Text(
            'If you cannot do great things, do small things\nin a great way!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontSize: 15, height: 1.25, fontWeight: FontWeight.w400),
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('- Napoleon Hill', style: TextStyle(color: AppColors.authorAccent, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: 5),
          SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _compactBanners(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 92, child: _findBanner(context)),
        SizedBox(height: 9),
        SizedBox(height: 92, child: _guidanceBanner(context)),
      ],
    );
  }

  Widget _findBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/find'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.fromLTRB(13, 6, 8, 6),
        decoration: BoxDecoration(
          color: AppPalette.of(context).brandSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Finding Institute?', style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w500)),
                  SizedBox(height: 3),
                  Text('Find an institute suitable to\nyour needs and eligibility', style: TextStyle(color: AppColors.white70, fontSize: 11, height: 1.2)),
                  SizedBox(height: 5),
                  DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.actionAccent, borderRadius: BorderRadius.all(Radius.circular(18))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Find Now', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
              decoration: BoxDecoration(color: AppColors.findBubble, shape: BoxShape.circle),
              child: Icon(Icons.person_search_rounded, color: AppColors.white, size: 46),
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
        padding: EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: AppPalette.of(context).brandSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppPalette.of(context).border,
                borderRadius: BorderRadius.all(Radius.circular(45)),
              ),
              child: Icon(Icons.groups_rounded, color: AppPalette.of(context).ink, size: 45),
            ),
            SizedBox(width: 11),
            Expanded(
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