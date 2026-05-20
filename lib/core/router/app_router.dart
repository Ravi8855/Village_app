import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../admin/admin_dashboard.dart';
import '../../admin/dept_admin_dashboard.dart';
import '../../admin/dept_admin_pending_page.dart';
import '../../auth/auth_gate_page.dart';
import '../../auth/settings_screen.dart';
import '../../auth/admin_login_screen.dart';
import '../../auth/dept_admin_activate_screen.dart';
import '../../auth/signup_screen.dart';
import '../../features/annabhagya/presentation/pages/angadi_distribution_page.dart';
import '../../features/annabhagya/presentation/pages/annabhagya_page.dart';
import '../../features/health/presentation/pages/health_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/panchayat/presentation/pages/panchayat_page.dart';
import '../../features/panchayat/domain/panchayat_models.dart';
import '../../features/temples/presentation/pages/temple_detail_page.dart';
import '../../features/temples/presentation/pages/temples_list_page.dart';
import '../../features/village_services/presentation/pages/bank_page.dart';
import '../../features/village_services/presentation/pages/postman_page.dart';
import '../../features/water_supply/presentation/pages/water_supply_notices_page.dart';
import '../../features/weather/presentation/pages/weather_page.dart';
import '../../providers/auth_provider.dart';
import 'auth_route_redirect.dart';
import '../shell/scaffold_with_bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.listen<AuthState>(authProvider, (_, __) {});

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutePaths.splash,
    redirect: (context, state) => authRouteRedirect(state, ref),
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Navigation error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(state.error?.toString() ?? 'Unknown route error'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutePaths.splash),
                child: const Text('Back to start'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const AuthGatePage(),
      ),
      GoRoute(
        path: AppRoutePaths.signup,
        name: AppRouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.adminLogin,
        name: AppRouteNames.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.adminActivate,
        name: AppRouteNames.adminActivate,
        builder: (context, state) => const DeptAdminActivateScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.settings,
        name: AppRouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.superAdminHome,
        name: AppRouteNames.superAdminHome,
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: AppRoutePaths.deptAdminHome,
        name: AppRouteNames.deptAdminHome,
        builder: (context, state) => const DeptAdminDashboard(),
      ),
      GoRoute(
        path: AppRoutePaths.deptAdminPending,
        name: AppRouteNames.deptAdminPending,
        builder: (context, state) => const DeptAdminPendingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.home,
                name: AppRouteNames.home,
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'water-supply',
                    name: AppRouteNames.waterSupply,
                    builder: (context, state) => const WaterSupplyNoticesPage(),
                  ),
                  GoRoute(
                    path: 'panchayat',
                    name: AppRouteNames.panchayat,
                    builder: (context, state) => const PanchayatPage(),
                    routes: [
                      GoRoute(
                        path: 'electricity',
                        name: AppRouteNames.electricity,
                        builder: (context, state) => const PanchayatPage(
                          sectionFilter: PanchayatSectionType.electricity,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'bank',
                    name: AppRouteNames.bank,
                    builder: (context, state) => const BankPage(),
                  ),
                  GoRoute(
                    path: 'postman',
                    name: AppRouteNames.postman,
                    builder: (context, state) => const PostmanPage(),
                  ),
                  GoRoute(
                    path: 'temples',
                    name: AppRouteNames.temples,
                    builder: (context, state) => const TemplesListPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        name: AppRouteNames.templeDetail,
                        builder: (context, state) => TempleDetailPage(
                          templeId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'annabhagya',
                    name: AppRouteNames.annabhagya,
                    builder: (context, state) => const AnnabhagyaPage(),
                    routes: [
                      GoRoute(
                        path: ':angadiId',
                        name: AppRouteNames.angadiDistribution,
                        builder: (context, state) => AngadiDistributionPage(
                          angadiId: state.pathParameters['angadiId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.news,
                name: AppRouteNames.news,
                builder: (context, state) => const NewsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.weather,
                name: AppRouteNames.weather,
                builder: (context, state) => const WeatherPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.health,
                name: AppRouteNames.health,
                builder: (context, state) => const HealthPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class AppRoutePaths {
  static const splash = '/';
  static const signup = '/signup';
  static const adminLogin = '/admin/login';
  static const adminActivate = '/admin/activate';
  static const settings = '/settings';
  static const superAdminHome = '/admin/super';
  static const deptAdminHome = '/admin/dept';
  static const deptAdminPending = '/admin/pending';
  static const home = '/home';
  static const news = '/news';
  static const weather = '/weather';
  static const health = '/health';
  static const waterSupply = '/home/water-supply';
  static const panchayat = '/home/panchayat';
  static const electricity = '/home/panchayat/electricity';
  static const bank = '/home/bank';
  static const postman = '/home/postman';
  static const temples = '/home/temples';
  static const annabhagya = '/home/annabhagya';

  static String templeDetail(String id) => '/home/temples/$id';
  static String angadiDistribution(String angadiId) =>
      '/home/annabhagya/$angadiId';
}

class AppRouteNames {
  static const splash = 'splash';
  static const signup = 'signup';
  static const adminLogin = 'adminLogin';
  static const adminActivate = 'adminActivate';
  static const settings = 'settings';
  static const superAdminHome = 'superAdminHome';
  static const deptAdminHome = 'deptAdminHome';
  static const deptAdminPending = 'deptAdminPending';
  static const home = 'home';
  static const news = 'news';
  static const weather = 'weather';
  static const health = 'health';
  static const waterSupply = 'waterSupply';
  static const panchayat = 'panchayat';
  static const electricity = 'electricity';
  static const bank = 'bank';
  static const postman = 'postman';
  static const temples = 'temples';
  static const templeDetail = 'templeDetail';
  static const annabhagya = 'annabhagya';
  static const angadiDistribution = 'angadiDistribution';
}
