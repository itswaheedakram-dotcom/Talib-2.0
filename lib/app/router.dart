import '../features/institutes/presentation/widgets/institute_record_scope.dart';
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
import '../features/institutes/presentation/screens/admin_institute_submissions_screen.dart';
import '../features/institutes/presentation/screens/admin_institute_types_screen.dart';
import '../features/institutes/presentation/screens/add_institute_screen.dart';
import '../features/institutes/presentation/screens/edit_institute_screen.dart';
import '../features/institutes/presentation/screens/institute_opportunities_screen.dart';
import '../features/institutes/presentation/screens/admin_location_catalog_screen.dart';
import '../features/institutes/presentation/screens/discipline_info_screen.dart';
import '../features/scholarships/presentation/screens/scholarships_screen.dart';
import '../features/courses/presentation/screens/courses_screen.dart';
import '../features/search/presentation/screens/smart_global_search_screen.dart';
import '../features/community/presentation/screens/community_screen.dart';
import '../features/community/presentation/screens/create_post_screen.dart';
import '../features/community/presentation/screens/add_to_timeline_screen.dart';
import '../features/community/presentation/screens/post_comments_screen.dart';
import '../features/models/post.dart';
import '../features/models/hostel.dart';
import '../features/community/presentation/screens/notifications_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/common/presentation/screens/bookmarks_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/public_profile_screen.dart';
import '../features/seminars/presentation/screens/seminars_screen.dart';
import '../features/hostels/presentation/screens/hostels_screen.dart';
import '../features/hostels/presentation/screens/list_hostel_screen.dart';
import '../features/hostels/presentation/screens/hostel_detail_screen.dart';
import '../features/hostels/presentation/screens/hostel_claim_screen.dart';
import '../features/hostels/presentation/screens/hostel_management_screen.dart';
import '../features/hostels/presentation/screens/hostel_managers_screen.dart';
import '../features/internships/presentation/screens/internships_screen.dart';
import '../features/jobs/presentation/screens/jobs_screen.dart';
import '../features/groups/presentation/screens/groups_screen.dart';
import '../features/resources/presentation/screens/resources_screen.dart';
import '../features/messages/presentation/screens/messages_screen.dart';
import '../features/messages/presentation/screens/chat_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/blocked_users_screen.dart';
import '../features/settings/presentation/screens/temporary_profiles_screen.dart';
import '../features/admin/presentation/screens/admin_panel_screen.dart';
import '../features/admin/presentation/screens/admin_hostel_claims_screen.dart';
import '../features/admin/presentation/screens/admin_hostel_submissions_screen.dart';
import '../features/admin/presentation/screens/admin_placeholder_screen.dart';
import '../features/support/presentation/screens/report_issue_screen.dart';
import '../features/support/presentation/screens/help_faqs_screen.dart';
import '../features/support/presentation/screens/admin_issue_reports_screen.dart';

final appRouter=GoRouter(initialLocation:'/',routes:[
  GoRoute(path:'/',builder:(_,__)=>const MainScreen()),
  GoRoute(path:'/home',builder:(_,__)=>const HomeScreen()),
  GoRoute(path:'/newsfeed',builder:(_,__)=>const NewsFeedScreen()),
  GoRoute(path:'/institutes',builder:(_,__)=>InstituteModeScope(builder:()=>const AllInstitutesScreen())),
  GoRoute(path:'/institutes/:type',builder:(_,s)=>InstituteModeScope(builder:()=>InstituteListScreen(type:s.pathParameters['type']!))),
  GoRoute(path:'/institute/:id',builder:(_,s)=>InstituteRecordScope(id:s.pathParameters['id']!,builder:()=>InstituteDetailScreen(id:s.pathParameters['id']!))),
  GoRoute(path:'/institute/:id/edit',builder:(_,s)=>InstituteRecordScope(id:s.pathParameters['id']!,builder:()=>EditInstituteScreen(id:s.pathParameters['id']!))),
  GoRoute(path:'/institute/:id/claim',builder:(_,s)=>InstituteRecordScope(id:s.pathParameters['id']!,builder:()=>ClaimInstituteScreen(instituteId:s.pathParameters['id']!,instituteName:s.uri.queryParameters['name']??'Institute'))),
  GoRoute(path:'/find',builder:(_,__)=>InstituteModeScope(builder:()=>const FindInstituteScreen())),
  GoRoute(path:'/add-institute/:type',builder:(_,s)=>InstituteModeScope(builder:()=>AddInstituteScreen(type:s.pathParameters['type']!))),
  GoRoute(path:'/institute/:id/programs',builder:(_,s)=>InstituteRecordScope(id:s.pathParameters['id']!,builder:()=>DisciplineInfoScreen(instituteId:s.pathParameters['id']!))),
  GoRoute(path:'/institute/:id/opportunities',builder:(_,s)=>InstituteRecordScope(id:s.pathParameters['id']!,builder:()=>InstituteOpportunitiesScreen(instituteId:s.pathParameters['id']!,initialKind:s.uri.queryParameters['kind'] ?? 'admission'))),
  GoRoute(path:'/institute-dashboard',builder:(_,__)=>InstituteModeScope(builder:()=>const InstituteDashboardScreen())),
  GoRoute(path:'/institute-admin/:claimId',builder:(_,s)=>InstituteModeScope(builder:()=>InstituteAdminScreen(claimId:s.pathParameters['claimId']!))),
  GoRoute(path:'/admin',builder:(_,__)=>const AdminPanelScreen()),
  GoRoute(path:'/admin/institute-claims',builder:(_,__)=>InstituteModeScope(builder:()=>const AdminInstituteClaimsScreen())),
  GoRoute(path:'/admin/institute-submissions',builder:(_,__)=>InstituteModeScope(builder:()=>const AdminInstituteSubmissionsScreen())),
  GoRoute(path:'/admin/institute-types',builder:(_,__)=>InstituteModeScope(builder:()=>const AdminInstituteTypesScreen())),
  GoRoute(path:'/admin/locations',builder:(_,__)=>InstituteModeScope(builder:()=>const AdminLocationCatalogScreen())),
  GoRoute(path:'/admin/hostel-claims',builder:(_,__)=>const AdminHostelClaimsScreen()),
  GoRoute(path:'/admin/hostel-submissions',builder:(_,__)=>const AdminHostelSubmissionsScreen()),
  GoRoute(path:'/admin/reports',builder:(_,__)=>const AdminPlaceholderScreen(title:'Reports',description:'Community content moderation tools.')),
  GoRoute(path:'/admin/issue-tickets',builder:(_,__)=>const AdminIssueReportsScreen()),
  GoRoute(path:'/admin/issue-tickets/:id',builder:(_,s)=>IssueTicketDetailScreen(ticketId:s.pathParameters['id']!,adminMode:true)),
  GoRoute(path:'/admin/faqs',builder:(_,__)=>const AdminFaqManagementScreen()),
  GoRoute(path:'/report-issue',builder:(_,__)=>const ReportIssueScreen()),
  GoRoute(path:'/my-reports',builder:(_,__)=>const MyReportsScreen()),
  GoRoute(path:'/my-reports/:id',builder:(_,s)=>IssueTicketDetailScreen(ticketId:s.pathParameters['id']!)),
  GoRoute(path:'/help-faqs',builder:(_,__)=>const HelpFaqsScreen()),
  GoRoute(path:'/admin/audit-logs',builder:(_,__)=>const AdminPlaceholderScreen(title:'Audit Log',description:'A secure, append-only history of administrative actions will be added in the next admin phase.')),
  GoRoute(path:'/search',builder:(_,__)=>const SmartGlobalSearchScreen()),
  GoRoute(path:'/community',builder:(_,s)=>CommunityScreen(instituteId:s.uri.queryParameters['instituteId'],instituteName:s.uri.queryParameters['instituteName'])),
  GoRoute(path:'/community/add-to-timeline',builder:(_,__)=>const AddToTimelineScreen()),
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
  GoRoute(path:'/hostel/:id',builder:(_,s)=>s.extra is Hostel ? HostelDetailScreen(hostel:s.extra as Hostel) : HostelDetailLoaderScreen(hostelId:s.pathParameters['id']!)),
  GoRoute(path:'/hostels/list',builder:(_,__)=>const ListHostelScreen()),
  GoRoute(path:'/hostel/:id/claim',builder:(_,s)=>HostelClaimScreen(hostelId:s.pathParameters['id']!,hostelName:s.uri.queryParameters['name']??'Hostel',isDemo:s.pathParameters['id']!.startsWith('example_'))),
  GoRoute(path:'/hostel/:id/manage',builder:(_,s)=>HostelManagementScreen(hostelId:s.pathParameters['id']!,initialHostel:s.extra is Hostel ? s.extra as Hostel : null)),
  GoRoute(path:'/hostel/:id/managers',builder:(_,s)=>HostelManagersScreen(hostelId:s.pathParameters['id']!)),
  GoRoute(path:'/internships',builder:(_,__)=>const InternshipsScreen()),
  GoRoute(path:'/jobs',builder:(_,__)=>const JobsScreen()),
  GoRoute(path:'/groups',builder:(_,__)=>const GroupsScreen()),
  GoRoute(path:'/resources',builder:(_,__)=>const ResourcesScreen()),
  GoRoute(path:'/messages',builder:(_,__)=>const MessagesScreen()),
  GoRoute(path:'/settings',builder:(_,__)=>const SettingsScreen()),
  GoRoute(path:'/blocked-users',builder:(_,__)=>const BlockedUsersScreen()),
  GoRoute(path:'/temporary-profiles',builder:(_,__)=>const TemporaryProfilesScreen()),
  GoRoute(path:'/chat/:id',builder:(_,s)=>ChatScreen(conversationId:s.pathParameters['id']!,otherUid:s.uri.queryParameters['uid']!,otherName:s.uri.queryParameters['name']??'Student')),
]);