import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/data/database/app_database.dart';
import 'package:notiva/data/helpers/clock.dart';
import 'package:notiva/data/helpers/id_generator.dart';
import 'package:notiva/data/repositories/piece_repository.dart';
import 'package:notiva/data/repositories/section_repository.dart';
import 'package:notiva/domain/enums/hand_status.dart';
import 'package:notiva/domain/enums/piece_status.dart';
import 'package:notiva/features/repertoire/cubit/pieces_cubit.dart';

void main() {
  late AppDatabase db;
  late DriftPieceRepository pieceRepo;
  late DriftSectionRepository sectionRepo;
  late PiecesCubit cubit;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final idGen = UuidIdGenerator();
    const clock = SystemAppClock();
    pieceRepo = DriftPieceRepository(db: db, idGenerator: idGen, clock: clock);
    sectionRepo = DriftSectionRepository(db: db, idGenerator: idGen, clock: clock);
    cubit = PiecesCubit(pieceRepo);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('watchAllWithSections groups sections and excludes soft-deleted pieces',
      () async {
    final clair = await pieceRepo.create(
      title: 'Clair de Lune',
      composer: 'Claude Debussy',
      status: PieceStatus.learning,
    );
    await sectionRepo.create(
      pieceId: clair.id,
      name: 'Mở đầu',
      orderIndex: 0,
      htStatus: HandStatus.mastered,
    );
    await sectionRepo.create(
      pieceId: clair.id,
      name: 'Giai điệu chính',
      orderIndex: 1,
      htStatus: HandStatus.learning,
    );

    final list = await pieceRepo.watchAllWithSections().first;
    expect(list, hasLength(1));
    expect(list.first.sections, hasLength(2));
    expect(
      list.first.sectionsSummaryCaption,
      equals('2 đoạn: 1 thuần thục, 1 đang tập'),
    );

    // Soft-delete Clair de Lune and verify both piece & sections are excluded.
    await pieceRepo.softDelete(clair.id);
    final afterDelete = await pieceRepo.watchAllWithSections().first;
    expect(afterDelete, isEmpty);
    expect(await sectionRepo.getByPieceId(clair.id), isEmpty);
  });

  test('PiecesCubit creates, filters, searches, updates, and deletes pieces',
      () async {
    await cubit.createPiece(
      title: 'Clair de Lune',
      composer: 'Claude Debussy',
      status: PieceStatus.learning,
    );
    await cubit.createPiece(
      title: 'Für Elise',
      composer: 'Ludwig van Beethoven',
      status: PieceStatus.maintaining,
    );

    // Wait for stream emission.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.allPieces, hasLength(2));
    expect(cubit.state.filteredPieces, hasLength(2));

    // Filter by status.
    cubit.setStatusFilter(PieceStatus.maintaining);
    expect(cubit.state.filteredPieces, hasLength(1));
    expect(cubit.state.filteredPieces.first.piece.title, equals('Für Elise'));

    // Clear filter and search by composer.
    cubit.setStatusFilter(null);
    cubit.setSearchQuery('debussy');
    expect(cubit.state.filteredPieces, hasLength(1));
    expect(
      cubit.state.filteredPieces.first.piece.title,
      equals('Clair de Lune'),
    );

    // Update piece.
    cubit.setSearchQuery('');
    final clair = cubit.state.allPieces
        .firstWhere((p) => p.piece.title == 'Clair de Lune')
        .piece;
    await cubit.updatePiece(
      clair,
      title: 'Clair de Lune (Rev)',
      composer: null,
      status: PieceStatus.completed,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final updated = cubit.state.allPieces
        .firstWhere((p) => p.piece.id == clair.id)
        .piece;
    expect(updated.title, equals('Clair de Lune (Rev)'));
    expect(updated.composer, isNull);
    expect(updated.status, equals(PieceStatus.completed));

    // Soft-delete piece.
    await cubit.deletePiece(clair.id);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.allPieces, hasLength(1));
    expect(cubit.state.allPieces.first.piece.title, equals('Für Elise'));
  });
}

