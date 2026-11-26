import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/piece.dart';
import '../../features/dev/dev_gallery_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/plan_screen.dart';
import '../../features/repertoire/screens/piece_form_screen.dart';
import '../../features/repertoire/screens/repertoire_screen.dart';
import '../../features/sections/screens/piece_detail_screen.dart';
import '../../features/sections/screens/section_detail_screen.dart';
import '../../features/sections/screens/section_form_screen.dart';
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
  static const String pieceDetail = '/piece';
  static const String pieceForm = '/piece/form';
  static const String sectionDetail = '/section';
  static const String sectionForm = '/section/form';
  static const String planForm = '/plan/form';
  static const String devGallery = '/dev/gallery';
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
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.repertoire,
              builder: (context, state) => const RepertoireScreen(),
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
      builder: (context, state) => PieceFormScreen(
        piece: state.extra as Piece?,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '${AppRoutes.pieceDetail}/:id',
      builder: (context, state) => PieceDetailScreen(
        pieceId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.sectionForm,
      builder: (context, state) => SectionFormScreen(
        args: state.extra as SectionFormArgs,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '${AppRoutes.sectionDetail}/:id',
      builder: (context, state) => SectionDetailScreen(
        sectionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.planForm,
      builder: (context, state) => const PlanScreen(),
    ),
    if (kDebugMode)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.devGallery,
        builder: (context, state) => const DevGalleryScreen(),
      ),
  ],
);

