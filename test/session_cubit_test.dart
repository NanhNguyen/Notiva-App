import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/data/database/app_database.dart' as db_pkg;
import 'package:notiva/data/helpers/clock.dart';
import 'package:notiva/data/helpers/id_generator.dart';
import 'package:notiva/data/repositories/piece_repository.dart';
import 'package:notiva/data/repositories/plan_repository.dart';
import 'package:notiva/data/repositories/section_repository.dart';
import 'package:notiva/data/repositories/session_repository.dart';
import 'package:notiva/domain/enums/hand_status.dart';
import 'package:notiva/domain/enums/piece_status.dart';
import 'package:notiva/domain/enums/plan_item_priority.dart';
import 'package:notiva/domain/enums/plan_item_state.dart';
import 'package:notiva/domain/enums/practice_outcome.dart';
import 'package:notiva/domain/models/plan_selection_draft.dart';
import 'package:notiva/features/practice/cubit/session_cubit.dart';

class _TestClock implements AppClock {
  _TestClock(this._now);

  DateTime _now;

  void advance(Duration d) => _now = _now.add(d);

  @override
  DateTime nowUtc() => _now.toUtc();

  @override
  String todayLocalDate() => '2026-11-26';

  @override
  String yesterdayLocalDate() => '2026-11-25';
}

void main() {
  late db_pkg.AppDatabase db;
  late _TestClock clock;
  late DriftPieceRepository pieceRepo;
  late DriftSectionRepository sectionRepo;
  late DriftPlanRepository planRepo;
  late DriftSessionRepository sessionRepo;
  late SessionCubit cubit;

  setUp(() {
    db = db_pkg.AppDatabase.forTesting(NativeDatabase.memory());
    clock = _TestClock(DateTime.utc(2026, 11, 26, 19, 0, 0));
    final idGen = UuidIdGenerator();
    pieceRepo = DriftPieceRepository(db: db, idGenerator: idGen, clock: clock);
    sectionRepo = DriftSectionRepository(db: db, idGenerator: idGen, clock: clock);
    planRepo = DriftPlanRepository(db: db, idGenerator: idGen, clock: clock);
    sessionRepo = DriftSessionRepository(db: db, idGenerator: idGen, clock: clock);
    cubit = SessionCubit(
      sessionRepository: sessionRepo,
      planRepository: planRepo,
      sectionRepository: sectionRepo,
      pieceRepository: pieceRepo,
      clock: clock,
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('smart defaults reflect last entry and current section state', () async {
    final piece = await pieceRepo.create(
      title: 'Clair de Lune',
      status: PieceStatus.learning,
    );
    final section = await sectionRepo.create(
      pieceId: piece.id,
      name: 'Giai điệu chính',
      rhStatus: HandStatus.solid,
      lhStatus: HandStatus.learning,
      htStatus: HandStatus.notStarted,
      nextAction: 'Tập chậm tay trái',
    );

    // No prior entries -> defaults to ['ht'], null tempo, PracticeOutcome.same.
    final initialDefaults = await cubit.loadDefaults(section);
    expect(initialDefaults.hands, equals(['ht']));
    expect(initialDefaults.lastTempo, isNull);
    expect(initialDefaults.outcome, equals(PracticeOutcome.same));
    expect(initialDefaults.rh, equals(HandStatus.solid));
    expect(initialDefaults.nextAction, equals('Tập chậm tay trái'));

    // Save an entry with ['lh', 'ht'], tempo 62, updated statuses.
    final session = await sessionRepo.startSession();
    await sessionRepo.saveEntry(
      sessionId: session.id,
      section: section,
      hands: const ['lh', 'ht'],
      tempo: 62,
      outcome: PracticeOutcome.improved,
      note: 'Tốt hơn rồi',
      nextAction: 'Tăng lên 66 bpm',
      rhAfter: HandStatus.solid,
      lhAfter: HandStatus.solid,
      htAfter: HandStatus.learning,
    );

    final updatedSection = (await sectionRepo.getById(section.id))!;
    final nextDefaults = await cubit.loadDefaults(updatedSection);
    expect(nextDefaults.hands, equals(['lh', 'ht']));
    expect(nextDefaults.lastTempo, equals(62));
    expect(nextDefaults.outcome, equals(PracticeOutcome.same));
    expect(nextDefaults.lh, equals(HandStatus.solid));
    expect(nextDefaults.ht, equals(HandStatus.learning));
    expect(nextDefaults.nextAction, equals('Tăng lên 66 bpm'));
  });

  test(
      'logEntry updates entry, section, and plan item in one transaction; endSession records duration',
      () async {
    final piece = await pieceRepo.create(
      title: 'Für Elise',
      status: PieceStatus.maintaining,
    );
    final section = await sectionRepo.create(
      pieceId: piece.id,
      name: 'Mở đầu',
      rhStatus: HandStatus.learning,
      lhStatus: HandStatus.notStarted,
      htStatus: HandStatus.notStarted,
    );
    await planRepo.saveTodayPlan([
      PlanSelectionDraft(
        sectionId: section.id,
        goal: 'Chơi đều',
        priority: PlanItemPriority.high,
      ),
    ]);

    await cubit.startSession();
    expect(cubit.state.isActive, isTrue);
    expect(cubit.state.queue, hasLength(1));

    clock.advance(const Duration(minutes: 10));
    await cubit.togglePause();
    clock.advance(const Duration(minutes: 3));
    await cubit.togglePause();
    clock.advance(const Duration(minutes: 5));

    // 10 + 5 = 15 minutes active (3 paused minutes excluded).
    expect(cubit.state.elapsedAt(clock.nowUtc()).inMinutes, equals(15));

    await cubit.logEntry(
      item: cubit.state.queue.first,
      hands: const ['rh', 'ht'],
      tempo: 72,
      outcome: PracticeOutcome.improved,
      note: 'Đều nhịp hơn',
      nextAction: 'Giữ 72 bpm',
      rhAfter: HandStatus.solid,
      lhAfter: HandStatus.learning,
      htAfter: HandStatus.learning,
    );

    // Verify section updated.
    final updatedSection = (await sectionRepo.getById(section.id))!;
    expect(updatedSection.rhStatus, equals(HandStatus.solid));
    expect(updatedSection.lhStatus, equals(HandStatus.learning));
    expect(updatedSection.htStatus, equals(HandStatus.learning));
    expect(updatedSection.nextAction, equals('Giữ 72 bpm'));
    expect(updatedSection.lastPracticedAt, isNotNull);

    // Verify plan item marked done.
    final planItems = await planRepo.getByDate(clock.todayLocalDate());
    expect(planItems, hasLength(1));
    expect(planItems.first.state, equals(PlanItemState.done));

    // Verify entry recorded before/after.
    final entries = await sessionRepo.watchEntriesForSection(section.id).first;
    expect(entries, hasLength(1));
    expect(entries.first.rhBefore, equals(HandStatus.learning));
    expect(entries.first.rhAfter, equals(HandStatus.solid));

    // End session and verify duration + note saved.
    await cubit.endSession(durationMinutes: 15, note: 'Buổi tập tốt');
    expect(cubit.state.isActive, isFalse);

    final recentSessions = await sessionRepo.getRecent();
    expect(recentSessions, hasLength(1));
    expect(recentSessions.first.durationMinutes, equals(15));
    expect(recentSessions.first.note, equals('Buổi tập tốt'));
  });
}

