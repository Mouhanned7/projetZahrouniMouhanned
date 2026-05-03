import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/resources/resource_list_screen.dart';
import '../screens/resources/resource_detail_screen.dart';
import '../screens/resources/resource_upload_screen.dart';
import '../screens/videos/video_list_screen.dart';
import '../screens/videos/video_detail_screen.dart';
import '../screens/videos/video_upload_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/social/social_feed_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/admin_resources_screen.dart';
import '../screens/accuil.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/accueil',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    final isAccueilRoute = state.matchedLocation == '/accueil';

    if (session == null && !isAuthRoute && !isAccueilRoute) {
      return '/accueil';
    }
    if (session != null && (isAuthRoute || isAccueilRoute)) {
      return '/resources';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/accueil',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/acceuil',
      redirect: (context, state) => '/accueil',
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/resources',
          builder: (context, state) => const ResourceListScreen(),
        ),
        GoRoute(
          path: '/resources/upload',
          builder: (context, state) => const ResourceUploadScreen(),
        ),
        GoRoute(
          path: '/resources/:id',
          builder: (context, state) => ResourceDetailScreen(
            resourceId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/videos',
          builder: (context, state) => const VideoListScreen(),
        ),
        GoRoute(
          path: '/videos/upload',
          builder: (context, state) => const VideoUploadScreen(),
        ),
        GoRoute(
          path: '/videos/:id',
          builder: (context, state) => VideoDetailScreen(
            videoId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/social',
          builder: (context, state) => const SocialFeedScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) => const AdminSettingsScreen(),
        ),
        GoRoute(
          path: '/admin/resources',
          builder: (context, state) => const AdminResourcesScreen(),
        ),
      ],
    ),
  ],
);
