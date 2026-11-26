import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/strings/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/helpers/clock.dart';
import 'data/helpers/id_generator.dart';
import 'data/repositories/piece_repository.dart';
import 'data/repositories/plan_repository.dart';
import 'data/repositories/section_repository.dart';
import 'data/repositories/session_repository.dart';
import 'features/home/cubit/plan_cubit.dart';
import 'features/repertoire/cubit/pieces_cubit.dart';
import 'features/sections/cubit/sections_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final db = AppDatabase();
  final idGenerator = UuidIdGenerator();
  const clock = SystemAppClock();

  // Open the database early so any initialization issue surfaces immediately.
  await db.customSelect('SELECT 1').get();

  runApp(
    NotivaApp(
      db: db,
      idGenerator: idGenerator,
      clock: clock,
    ),
  );
}

class NotivaApp extends StatelessWidget {
  const NotivaApp({
    super.key,
    required this.db,
    required this.idGenerator,
    required this.clock,
  });

  final AppDatabase db;
  final IdGenerator idGenerator;
  final AppClock clock;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PieceRepository>(
          create: (_) => DriftPieceRepository(
            db: db,
            idGenerator: idGenerator,
            clock: clock,
          ),
        ),
        RepositoryProvider<SectionRepository>(
          create: (_) => DriftSectionRepository(
            db: db,
            idGenerator: idGenerator,
            clock: clock,
          ),
        ),
        RepositoryProvider<PlanRepository>(
          create: (_) => DriftPlanRepository(
            db: db,
            idGenerator: idGenerator,
            clock: clock,
          ),
        ),
        RepositoryProvider<SessionRepository>(
          create: (_) => DriftSessionRepository(
            db: db,
            idGenerator: idGenerator,
            clock: clock,
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PlanCubit>(
            create: (context) => PlanCubit(
              pieceRepository: context.read<PieceRepository>(),
              planRepository: context.read<PlanRepository>(),
              sessionRepository: context.read<SessionRepository>(),
            ),
          ),
          BlocProvider<PiecesCubit>(
            create: (context) => PiecesCubit(context.read<PieceRepository>()),
          ),
          BlocProvider<SectionsCubit>(
            create: (context) => SectionsCubit(
              pieceRepository: context.read<PieceRepository>(),
              sectionRepository: context.read<SectionRepository>(),
              planRepository: context.read<PlanRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
