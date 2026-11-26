import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/data/database/app_database.dart' as db_pkg;
import 'package:notiva/data/helpers/clock.dart';
import 'package:notiva/data/helpers/id_generator.dart';
import 'package:notiva/data/repositories/piece_repository.dart';
import 'package:notiva/data/repositories/section_repository.dart';
import 'package:notiva/data/repositories/session_repository.dart';
import 'package:notiva/domain/enums/hand_status.dart';
import 'package:notiva/domain/enums/piece_status.dart';
import 'package:notiva/domain/enums/practice_outcome.dart';
import 'package:notiva/features/progress/cubit/progress_cubit.dart';
import 'package:notiva/features/progress/cubit/progress_state.dart';

class _FixedClock implements AppClock {
  _FixedClock(this._now);

  DateTime _now;

  void advance(Duration d) => _now = _now.add(d);

  @override
  DateTime nowUtc() => _now.toUtc();

  @override
  String todayLocalDate() =>
      '${_now.year.toString().padLeft(4, '0')}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}';

  @override
  String yesterdayLocalDate() {
    final y = _now.subtract(const Duration(days: 1));
    return '${y.year.toString().padLeft(4, '0')}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }
}

void main() {
  late db_pkg.AppDatabase db;
  late _FixedClock clock;
  late DriftPieceRepository pieceRepo;
  late DriftSectionRepository sectionRepo;
  late DriftSessionRepository sessionRepo;
  late ProgressCubit cubit;

  setUp(() {
    db = db_pkg.AppDatabase.forTesting(NativeDatabase.memory());
    clock = _FixedClock(DateTime.utc(2026, 11, 26, 19, 0, 0));
    final idGen = UuidIdGenerator();
    pieceRepo = DriftPieceRepository(db: db, idGenerator: idGen, clock: clock);
    sectionRepo = DriftSectionRepository(db: db, idGenerator: idGen, clock: clock);
    sessionRepo = DriftSessionRepository(db: db, idGenerator: idGen, clock: clock);
    cubit = ProgressCubit(
      sessionRepository: sessionRepo,
      pieceRepository: pieceRepo,
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('ProgressCubit derives weekly summary, status changes, and tempo series',
      () async {
    final piece = await pieceRepo.create(
      title: 'Clair de Lune',
      status: PieceStatus.learning,
    );
    final section = await sectionRepo.create(
      pieceId: piece.id,
      name: 'Giai điệu chính',
      rhStatus: HandStatus.learning,
      lhStatus: HandStatus.notStarted,
      htStatus: HandStatus.notStarted,
    );

    // Session 1: 20 minutes, tempo 58, LH improves from notStarted -> learning.
    final s1 = await sessionRepo.startSession();
    await sessionRepo.saveEntry(
      sessionId: s1.id,
      section: section,
      hands: const ['lh'],
      tempo: 58,
      outcome: PracticeOutcome.improved,
      rhAfter: HandStatus.learning,
      lhAfter: HandStatus.learning,
      htAfter: HandStatus.notStarted,
    );
    await sessionRepo.endSession(sessionId: s1.id, durationMinutes: 20);

    // Session 2: 25 minutes, tempo 64, no status change.
    clock.advance(const Duration(hours: 2));
    final updatedSection = (await sectionRepo.getById(section.id))!;
    final s2 = await sessionRepo.startSession();
    await sessionRepo.saveEntry(
      sessionId: s2.id,
      section: updatedSection,
      hands: const ['ht'],
      tempo: 64,
      outcome: PracticeOutcome.same,
      rhAfter: HandStatus.learning,
      lhAfter: HandStatus.learning,
      htAfter: HandStatus.notStarted,
    );
    await sessionRepo.endSession(sessionId: s2.id, durationMinutes: 25);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.snapshot.thisWeek.sessionCount, equals(2));
    expect(cubit.state.snapshot.thisWeek.totalMinutes, equals(45));
    expect(cubit.state.snapshot.sessionHistory, hasLength(2));
    // Only Session 1 changed status (LH notStarted -> learning).
    expect(cubit.state.snapshot.recentStatusChanges, hasLength(1));
    expect(
      cubit.state.snapshot.recentStatusChanges.first.entry.lhAfter,
      equals(HandStatus.learning),
    );

    cubit.setTabMode(ProgressTabMode.tempo);
    cubit.selectTempoSection(section.id);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.tabMode, equals(ProgressTabMode.tempo));
    expect(cubit.state.tempoPoints.map((p) => p.tempo), equals([58, 64]));
  });
}

