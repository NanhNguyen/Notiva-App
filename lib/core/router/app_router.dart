import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/shell/app_shell.dart';
import '../../features/shell/placeholder_route_screen.dart';
import '../../features/shell/placeholder_tab_screen.dart';
import '../strings/app_strings.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Route paths for Notiva.
abstract final class AppRoutes {
  static const String today = '/today';
  static const String repertoire = '/repertoire';
  static const String progress = '/progress';

  // Outside-shell routes (bottom navigation hidden)
  static const String practiceSession = '/practice/session';
  static const String practiceLog = '/practice/log';
  static const String pieceForm = '/piece/form';
  static const String sectionForm = '/section/form';
  static const String planForm = '/plan/form';
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.today,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.today,
              builder: (context, state) => const PlaceholderTabScreen(
                title: AppStrings.todayTitle,
                emptyTitle: AppStrings.todayEmptyTitle,
                emptySubtitle: AppStrings.todayEmptySubtitle,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.repertoire,
              builder: (context, state) => const PlaceholderTabScreen(
                title: AppStrings.repertoireTitle,
                emptyTitle: AppStrings.repertoireEmptyTitle,
                emptySubtitle: AppStrings.repertoireEmptySubtitle,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, state) => const PlaceholderTabScreen(
                title: AppStrings.progressTitle,
                emptyTitle: AppStrings.progressEmptyTitle,
                emptySubtitle: AppStrings.progressEmptySubtitle,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.practiceSession,
      builder: (context, state) => const PlaceholderRouteScreen(
        title: AppStrings.practiceSessionTitle,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.practiceLog,
      builder: (context, state) => const PlaceholderRouteScreen(
        title: AppStrings.practiceLogTitle,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.pieceForm,
      builder: (context, state) => const PlaceholderRouteScreen(
        title: AppStrings.pieceFormTitle,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.sectionForm,
      builder: (context, state) => const PlaceholderRouteScreen(
        title: AppStrings.sectionFormTitle,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.planForm,
      builder: (context, state) => const PlaceholderRouteScreen(
        title: AppStrings.planFormTitle,
      ),
    ),
  ],
);

