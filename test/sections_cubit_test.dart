import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/data/database/app_database.dart';
import 'package:notiva/data/helpers/clock.dart';
import 'package:notiva/data/helpers/id_generator.dart';
import 'package:notiva/data/repositories/piece_repository.dart';
import 'package:notiva/data/repositories/plan_repository.dart';
import 'package:notiva/data/repositories/section_repository.dart';
import 'package:notiva/domain/enums/hand_status.dart';
import 'package:notiva/domain/enums/piece_status.dart';
import 'package:notiva/features/sections/cubit/sections_cubit.dart';
import 'package:notiva/ui/widgets/hand_status_stepper.dart';

void main() {
  late AppDatabase db;
  late DriftPieceRepository pieceRepo;
  late DriftSectionRepository sectionRepo;
  late DriftPlanRepository planRepo;
  late SectionsCubit cubit;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final idGen = UuidIdGenerator();
    const clock = SystemAppClock();
    pieceRepo = DriftPieceRepository(db: db, idGenerator: idGen, clock: clock);
    sectionRepo = DriftSectionRepository(db: db, idGenerator: idGen, clock: clock);
    planRepo = DriftPlanRepository(db: db, idGenerator: idGen, clock: clock);
    cubit = SectionsCubit(
      pieceRepository: pieceRepo,
      sectionRepository: sectionRepo,
      planRepository: planRepo,
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('createSection assigns sequential orderIndex and updates hand status',
      () async {
    final piece = await pieceRepo.create(
      title: 'Clair de Lune',
      status: PieceStatus.learning,
    );
    cubit.watchPiece(piece.id);

    final s1 = await cubit.createSection(
      pieceId: piece.id,
      name: 'Mở đầu',
      measureStart: 1,
      measureEnd: 8,
      pageRef: '1',
      difficultyTags: const ['Nốt'],
      nextAction: 'Tập chậm tay trái',
    );
    final s2 = await cubit.createSection(
      pieceId: piece.id,
      name: 'Giai điệu chính',
    );

    expect(s1.orderIndex, equals(0));
    expect(s2.orderIndex, equals(1));

    await cubit.updateHandStatus(s1, PracticeHand.ht, HandStatus.solid);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.sections, hasLength(2));
    expect(cubit.state.sections.first.htStatus, equals(HandStatus.solid));
  });

  test('addToToday creates plan_item with nextAction and avoids duplicates',
      () async {
    final piece = await pieceRepo.create(
      title: 'Für Elise',
      status: PieceStatus.maintaining,
    );
    final section = await cubit.createSection(
      pieceId: piece.id,
      name: 'Đoạn A',
      nextAction: 'Giữ nhịp đều 72 bpm',
    );

    final firstAdd = await cubit.addToToday(section);
    final secondAdd = await cubit.addToToday(section);

    expect(firstAdd, isTrue);
    expect(secondAdd, isFalse);

    final todayItems =
        await planRepo.getByDate(const SystemAppClock().todayLocalDate());
    expect(todayItems, hasLength(1));
    expect(todayItems.first.sectionId, equals(section.id));
    expect(todayItems.first.goal, equals('Giữ nhịp đều 72 bpm'));
  });
}

