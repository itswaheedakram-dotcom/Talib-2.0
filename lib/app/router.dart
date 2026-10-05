import 'package:go_router/go_router.dart';
import '../features/home/presentation/screens/main_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/newsfeed/presentation/screens/news_feed_screen.dart';
import '../features/institutes/presentation/screens/all_institutes_screen.dart';
import '../features/institutes/presentation/screens/institute_list_screen.dart';
import '../features/institutes/presentation/screens/institute_detail_screen.dart';
import '../features/institutes/presentation/screens/find_institute_screen.dart';
import '../features/institutes/presentation/screens/claim_institute_screen.dart';
import '../features/institutes/presentation/screens/institute_dashboard_screen.dart';
import '../features/institutes/presentation/screens/institute_admin_screen.dart';
import '../features/institutes/presentation/screens/admin_institute_claims_screen.dart';
import '../features/institutes/presentation/screens/add_institute_screen.dart';
import '../features/institutes/presentation/screens/edit_institute_screen.dart';
import '../features/institutes/presentation/screens/discipline_info_screen.dart';
import '../features/scholarships/presentation/screens/scholarships_screen.dart';
import '../features/courses/presentation/screens/courses_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/community/presentation/screens/community_screen.dart';
import '../features/community/presentation/screens/create_post_screen.dart';
import '../features/community/presentation/screens/post_comments_screen.dart';
import '../features/models/post.dart';
import '../features/community/presentation/screens/notifications_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/common/presentation/screens/bookmarks_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/public_profile_screen.dart';
import '../features/seminars/presentation/screens/seminars_screen.dart';
import '../features/hostels/presentation/screens/hostels_screen.dart';
import '../features/hostels/presentation/screens/list_hostel_screen.dart';
import '../features/internships/presentation/screens/internships_screen.dart';
import '../features/jobs/presentation/screens/jobs_screen.dart';
import '../features/groups/presentation/screens/groups_screen.dart';
import '../features/resources/presentation/screens/resources_screen.dart';
import '../features/messages/presentation/screens/messages_screen.dart';

final appRouter=GoRouter(initialLocation:'/',routes:[
  GoRoute(path:'/',builder:(_,__)=>const MainScreen()),
  GoRoute(path:'/home',builder:(_,__)=>const HomeScreen()),
  GoRoute(path:'/newsfeed',builder:(_,__)=>const NewsFeedScreen()),
  GoRoute(path:'/institutes',builder:(_,__)=>const AllInstitutesScreen()),
  GoRoute(path:'/institutes/:type',builder:(_,s)=>InstituteListScreen(type:s.pathParameters['type']!)),
  GoRoute(path:'/institute/:id',builder:(_,s)=>InstituteDetailScreen(id:s.pathParameters['id']!)),
  GoRoute(path:'/institute/:id/edit',builder:(_,s)=>EditInstituteScreen(id:s.pathParameters['id']!)),
  GoRoute(path:'/institute/:id/claim',builder:(_,s)=>ClaimInstituteScreen(instituteId:s.pathParameters['id']!,instituteName:s.uri.queryParameters['name']??'Institute')),
  GoRoute(path:'/find',builder:(_,__)=>const FindInstituteScreen()),
  GoRoute(path:'/add-institute/:type',builder:(_,s)=>AddInstituteScreen(type:s.pathParameters['type']!)),
  GoRoute(path:'/institute/:id/programs',builder:(_,s)=>DisciplineInfoScreen(instituteId:s.pathParameters['id']!)),
  GoRoute(path:'/institute-dashboard',builder:(_,__)=>const InstituteDashboardScreen()),
  GoRoute(path:'/institute-admin/:claimId',builder:(_,s)=>InstituteAdminScreen(claimId:s.pathParameters['claimId']!)),
  GoRoute(path:'/admin/institute-claims',builder:(_,__)=>const AdminInstituteClaimsScreen()),
  GoRoute(path:'/search',builder:(_,__)=>const SearchScreen()),
  GoRoute(path:'/community',builder:(_,s)=>CommunityScreen(instituteId:s.uri.queryParameters['instituteId'],instituteName:s.uri.queryParameters['instituteName'])),
  GoRoute(path:'/community/create',builder:(_,s)=>CreatePostScreen(post:s.extra is Post?s.extra as Post:null,instituteId:s.uri.queryParameters['instituteId'],instituteName:s.uri.queryParameters['instituteName'])),
  GoRoute(path:'/notifications',builder:(_,__)=>const NotificationsScreen()),
  GoRoute(path:'/community/post/:id',builder:(_,s)=>PostCommentsScreen(id:s.pathParameters['id']!)),
  GoRoute(path:'/institute/:id/community',builder:(_,s)=>CommunityScreen(instituteId:s.pathParameters['id'],instituteName:s.uri.queryParameters['name'])),
  GoRoute(path:'/signin',builder:(_,__)=>const SignInScreen()),
  GoRoute(path:'/profile',builder:(_,__)=>const ProfileScreen()),
  GoRoute(path:'/profile/:id',builder:(_,s)=>PublicProfileScreen(id:s.pathParameters['id']!)),
  GoRoute(path:'/register',builder:(_,__)=>const RegisterScreen()),
  GoRoute(path:'/bookmarks',builder:(_,__)=>const BookmarksScreen()),
  GoRoute(path:'/scholarships',builder:(_,__)=>const ScholarshipsScreen()),
  GoRoute(path:'/courses',builder:(_,__)=>const CoursesScreen()),
  GoRoute(path:'/seminars',builder:(_,__)=>const SeminarsScreen()),
  GoRoute(path:'/hostels',builder:(_,__)=>const HostelsScreen()),
  GoRoute(path:'/hostels/list',builder:(_,__)=>const ListHostelScreen()),
  GoRoute(path:'/internships',builder:(_,__)=>const InternshipsScreen()),
  GoRoute(path:'/jobs',builder:(_,__)=>const JobsScreen()),
  GoRoute(path:'/groups',builder:(_,__)=>const GroupsScreen()),
  GoRoute(path:'/resources',builder:(_,__)=>const ResourcesScreen()),
  GoRoute(path:'/messages',builder:(_,__)=>const MessagesScreen()),
]);