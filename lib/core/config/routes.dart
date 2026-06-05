import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../admin/admin.dart';
import '../../features/features.dart';
import '../core.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final GoRouter setRouter = GoRouter(
    errorBuilder: (context, state) {
      return NotFoundPage(message:state.error?.message);
      // return animatedDialog(context, state.error?.message ?? "없어용", () {});
    },
    initialLocation: '/splash',
    navigatorKey: navigatorKey,
    observers: kIsWeb ? [] : [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
    routes: <RouteBase>[
      GoRoute(
          path: '/',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return const NoTransitionPage(child: HomePage());
          },
          routes: [
            GoRoute(
              path: 'location',
              builder: (BuildContext context, GoRouterState state) {
                return const LocationPage();
              },
            ),
          ]),
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        path: '/permission',
        builder: (BuildContext context, GoRouterState state) {
          return const PermissionPage();
        },
      ),
      GoRoute(
        path: '/guide',
        builder: (BuildContext context, GoRouterState state) {
          return const /**/GuidePage();
        },
      ),
      GoRoute(
        path: '/error/:code',
        builder: (BuildContext context, GoRouterState state) {
          if (state.pathParameters['code'] != null && state.pathParameters['code'] != '') {
            return ErrorPage(errorCode: state.pathParameters['code']!);
          } else {
            return const ErrorPage(errorCode: 'ER500');
          }
        },
      ),
      GoRoute(
        path: '/ban',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(
            child: BanPage(),
          );
        },
      ),
    ],
  );

  final GoRouter setDesktopRouter = GoRouter(
    errorBuilder: (context, state) => const NotFoundPage(),
    initialLocation: '/',
    navigatorKey: navigatorKey,
    routes: <RouteBase>[
      GoRoute(
          path: '/',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return const NoTransitionPage(child: MainPage());
          },
          routes: [
            GoRoute(
              path: 'login',
              pageBuilder: (BuildContext context, GoRouterState state) {
                return const NoTransitionPage(child: AdminLoginPage());
              },
            ),
          ]),
    ],
  );
}
