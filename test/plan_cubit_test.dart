import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/data/database/app_database.dart' as db_pkg;
import 'package:notiva/data/helpers/clock.dart';
import 'package:notiva/data/helpers/id_generator.dart';
import 'package:notiva/data/repositories/piece_repository.dart';
import 'package:notiva/data/repositories/plan_repository.dart';
import 'package:notiva/data/repositories/section_repository.dart';
import 'package:notiva/data/repositories/session_repository.dart';
import 'package:notiva/domain/enums/piece_status.dart';
import 'package:notiva/domain/enums/plan_item_priority.dart';
import 'package:notiva/domain/enums/plan_item_state.dart';
import 'package:notiva/domain/enums/practice_outcome.dart';
import 'package:notiva/domain/models/plan_selection_draft.dart';
import 'package:notiva/features/home/cubit/plan_cubit.dart';

class _ControllableClock implements AppClock {
  _ControllableClock(this._now);

  DateTime _now;

  void advance(Duration d) => _now = _now.add(d);

  @override
  DateTime nowUtc() => _now.toUtc();

  @override
  String todayLocalDate() => _fmt(_now);

  @override
  String yesterdayLocalDate() => _fmt(_now.subtract(const Duration(days: 1)));

  String _fmt(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

void main() {
  late db_pkg.AppDatabase db;
  late _ControllableClock clock;
  late DriftPieceRepository pieceRepo;
  late DriftSectionRepository sectionRepo;
  late DriftPlanRepository planRepo;
  late DriftSessionRepository sessionRepo;
  late PlanCubit cubit;

  setUp(() {
    db = db_pkg.AppDatabase.forTesting(NativeDatabase.memory());
    clock = _ControllableClock(DateTime.utc(2026, 11, 26, 14, 0, 0));
    final idGen = UuidIdGenerator();
    pieceRepo = DriftPieceRepository(db: db, idGenerator: idGen, clock: clock);
    sectionRepo = DriftSectionRepository(db: db, idGenerator: idGen, clock: clock);
    planRepo = DriftPlanRepository(db: db, idGenerator: idGen, clock: clock);
    sessionRepo = DriftSessionRepository(db: db, idGenerator: idGen, clock: clock);
    cubit = PlanCubit(
      pieceRepository: pieceRepo,
      planRepository: planRepo,
      sessionRepository: sessionRepo,
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('Smart Resume is null without entries and selects latest practiced section',
      () async {
    final piece = await pieceRepo.create(
      title: 'Clair de Lune',
      status: PieceStatus.learning,
    );
    final s1 = await sectionRepo.create(pieceId: piece.id, name: 'Mở đầu');
    final s2 = await sectionRepo.create(pieceId: piece.id, name: 'Giai điệu chính');

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.smartResume, isNull);

    await sessionRepo.recordQuickEntry(
      section: s1,
      outcome: PracticeOutcome.same,
      note: 'Ghi chú cũ',
      nextAction: 'Việc cũ',
    );
    clock.advance(const Duration(hours: 2));
    await sessionRepo.recordQuickEntry(
      section: s2,
      outcome: PracticeOutcome.improved,
      note: 'Tay trái còn chưa đều',
      nextAction: 'Tập chậm tay trái, 60 bpm',
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final resume = cubit.state.smartResume;
    expect(resume, isNotNull);
    expect(resume!.section.id, equals(s2.id));
    expect(resume.latestEntry.note, equals('Tay trái còn chưa đều'));
    expect(resume.latestEntry.nextAction, equals('Tập chậm tay trái, 60 bpm'));
  });

  test('savePlan creates, updates, toggles, and soft-deletes deselected items',
      () async {
    final piece = await pieceRepo.create(
      title: 'Für Elise',
      status: PieceStatus.maintaining,
    );
    final s1 = await sectionRepo.create(pieceId: piece.id, name: 'Đoạn A');
    final s2 = await sectionRepo.create(pieceId: piece.id, name: 'Đoạn B');

    await cubit.savePlan([
      PlanSelectionDraft(
        sectionId: s1.id,
        goal: 'Mục tiêu A',
        priority: PlanItemPriority.high,
      ),
      PlanSelectionDraft(
        sectionId: s2.id,
        goal: 'Mục tiêu B',
        priority: PlanItemPriority.normal,
      ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.todayItems, hasLength(2));
    expect(cubit.state.completedTodayCount, equals(0));

    await cubit.togglePlanItem(cubit.state.todayItems.first);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.completedTodayCount, equals(1));

    // Re-save keeping only s1 -> s2 should be soft-deleted.
    await cubit.savePlan([
      PlanSelectionDraft(
        sectionId: s1.id,
        goal: 'Mục tiêu A mới',
        priority: PlanItemPriority.normal,
      ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.todayItems, hasLength(1));
    expect(cubit.state.todayItems.first.item.goal, equals('Mục tiêu A mới'));
  });

  test('loadCarryOverSectionIds returns only incomplete items from yesterday',
      () async {
    final piece = await pieceRepo.create(
      title: 'Nocturne Op. 9 No. 2',
      status: PieceStatus.learning,
    );
    final sPending = await sectionRepo.create(pieceId: piece.id, name: 'Mở đầu');
    final sDone = await sectionRepo.create(pieceId: piece.id, name: 'Đoạn 2');

    final yesterday = clock.yesterdayLocalDate();
    final now = clock.nowUtc();

    await db.into(db.planItems).insert(
          db_pkg.PlanItemsCompanion.insert(
            id: 'y-pending',
            sectionId: sPending.id,
            date: yesterday,
            priority: PlanItemPriority.normal.name,
            state: PlanItemState.pending.name,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.planItems).insert(
          db_pkg.PlanItemsCompanion.insert(
            id: 'y-done',
            sectionId: sDone.id,
            date: yesterday,
            priority: PlanItemPriority.normal.name,
            state: PlanItemState.done.name,
            createdAt: now,
            updatedAt: now,
          ),
        );

    final carryOver = await cubit.loadCarryOverSectionIds();
    expect(carryOver, equals({sPending.id}));
  });
}
