import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/annabhagya/presentation/pages/angadi_distribution_page.dart';
import '../../features/annabhagya/presentation/pages/annabhagya_page.dart';
import '../../features/health/presentation/pages/health_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/panchayat/presentation/pages/panchayat_page.dart';
import '../../features/temples/presentation/pages/temple_detail_page.dart';
import '../../features/temples/presentation/pages/temples_list_page.dart';
import '../../features/weather/presentation/pages/weather_page.dart';
import '../shell/scaffold_with_bottom_nav.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutePaths.home,
    routes: [
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
                    path: 'panchayat',
                    name: AppRouteNames.panchayat,
                    builder: (context, state) => const PanchayatPage(),
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
  static const home = '/home';
  static const news = '/news';
  static const weather = '/weather';
  static const health = '/health';
  static const panchayat = '/home/panchayat';
  static const temples = '/home/temples';
  static const annabhagya = '/home/annabhagya';
  static String templeDetail(String id) => '/home/temples/$id';
  static String angadiDistribution(String angadiId) =>
      '/home/annabhagya/$angadiId';
}

class AppRouteNames {
  static const home = 'home';
  static const news = 'news';
  static const weather = 'weather';
  static const health = 'health';
  static const panchayat = 'panchayat';
  static const temples = 'temples';
  static const templeDetail = 'templeDetail';
  static const annabhagya = 'annabhagya';
  static const angadiDistribution = 'angadiDistribution';
}
