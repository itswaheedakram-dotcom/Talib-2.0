import 'package:go_router/go_router.dart';
import '../features/home/presentation/screens/main_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/institutes/presentation/screens/all_institutes_screen.dart';
import '../features/institutes/presentation/screens/institute_list_screen.dart';
import '../features/institutes/presentation/screens/institute_detail_screen.dart';
import '../features/institutes/presentation/screens/find_institute_screen.dart';
import '../features/scholarships/presentation/screens/scholarships_screen.dart';
import '../features/courses/presentation/screens/courses_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/community/presentation/screens/community_screen.dart';
import '../features/community/presentation/screens/create_post_screen.dart';
import '../features/community/presentation/screens/post_comments_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/common/presentation/screens/bookmarks_screen.dart';
import '../features/common/presentation/screens/empty_feature_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/seminars/presentation/screens/seminars_screen.dart';
import '../features/hostels/presentation/screens/hostels_screen.dart';
import '../features/internships/presentation/screens/internships_screen.dart';
import '../features/jobs/presentation/screens/jobs_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const MainScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/institutes', builder: (_, __) => const AllInstitutesScreen()),
    GoRoute(path: '/institutes/:type', builder: (_, s) => InstituteListScreen(type: s.pathParameters['type']!)),
    GoRoute(path: '/institute/:id', builder: (_, s) => InstituteDetailScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/find', builder: (_, __) => const FindInstituteScreen()),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(path: '/community', builder: (_, __) => const CommunityScreen()),
    GoRoute(path: '/community/create', builder: (_, __) => const CreatePostScreen()),
    GoRoute(path: '/community/post/:id', builder: (_, s) => PostCommentsScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/bookmarks', builder: (_, __) => const BookmarksScreen()),
    GoRoute(path: '/scholarships', builder: (_, __) => const ScholarshipsScreen()),
    GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
        GoRoute(path: '/seminars', builder: (_, __) => const SeminarsScreen()),
        GoRoute(path: '/hostels', builder: (_, __) => const HostelsScreen()),
    GoRoute(path: '/internships', builder: (_, __) => const InternshipsScreen()),
    GoRoute(path: '/jobs', builder: (_, __) => const JobsScreen()),
  ],
);
