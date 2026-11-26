import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/data/database/app_database.dart';
import 'package:notiva/data/helpers/clock.dart';
import 'package:notiva/data/helpers/id_generator.dart';
import 'package:notiva/data/repositories/piece_repository.dart';
import 'package:notiva/domain/enums/piece_status.dart';

class _FakeClock implements AppClock {
  _FakeClock(this._now);

  DateTime _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  @override
  DateTime nowUtc() => _now.toUtc();

  @override
  String todayLocalDate() => '2026-11-26';
}

final _uuidV4Regex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

void main() {
  late AppDatabase db;
  late _FakeClock clock;
  late DriftPieceRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = _FakeClock(DateTime.utc(2026, 11, 26, 12, 0, 0));
    repository = DriftPieceRepository(
      db: db,
      idGenerator: UuidIdGenerator(),
      clock: clock,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('(a) new rows receive a valid UUID v4 id', () async {
    final piece1 = await repository.create(
      title: 'Clair de Lune',
      composer: 'Claude Debussy',
    );
    final piece2 = await repository.create(
      title: 'Nocturne Op. 9 No. 2',
      composer: 'Frédéric Chopin',
    );

    expect(_uuidV4Regex.hasMatch(piece1.id), isTrue);
    expect(_uuidV4Regex.hasMatch(piece2.id), isTrue);
    expect(piece1.id, isNot(equals(piece2.id)));
  });

  test('(b) every write updates updatedAt in UTC', () async {
    final created = await repository.create(
      title: 'Arabesque No. 1',
      status: PieceStatus.planned,
    );
    expect(created.createdAt.isUtc, isTrue);
    expect(created.updatedAt.isUtc, isTrue);
    expect(created.updatedAt, equals(DateTime.utc(2026, 11, 26, 12, 0, 0)));

    clock.advance(const Duration(minutes: 5));
    final updated = await repository.update(
      created.copyWith(status: PieceStatus.learning),
    );
    expect(updated.updatedAt.isUtc, isTrue);
    expect(updated.updatedAt, equals(DateTime.utc(2026, 11, 26, 12, 5, 0)));

    final fetched = await repository.getById(created.id);
    expect(fetched, isNotNull);
    expect(fetched!.updatedAt, equals(DateTime.utc(2026, 11, 26, 12, 5, 0)));
    expect(fetched.status, equals(PieceStatus.learning));

    clock.advance(const Duration(minutes: 10));
    await repository.softDelete(created.id);

    // Verify raw row in DB has updatedAt and deletedAt set to the delete timestamp.
    final rawRows = await db.select(db.pieces).get();
    expect(rawRows, hasLength(1));
    expect(
      rawRows.first.updatedAt.toUtc(),
      equals(DateTime.utc(2026, 11, 26, 12, 15, 0)),
    );
    expect(
      rawRows.first.deletedAt?.toUtc(),
      equals(DateTime.utc(2026, 11, 26, 12, 15, 0)),
    );
  });

  test('(c) soft-deleted rows are excluded from reads and streams', () async {
    final keep = await repository.create(title: 'Gymnopédie No. 1');
    final remove = await repository.create(title: 'Prelude in C major');

    await repository.softDelete(remove.id);

    final byIdRemoved = await repository.getById(remove.id);
    expect(byIdRemoved, isNull);

    final byIdKept = await repository.getById(keep.id);
    expect(byIdKept, isNotNull);
    expect(byIdKept!.title, equals('Gymnopédie No. 1'));

    final all = await repository.getAll();
    expect(all.map((p) => p.id), equals([keep.id]));

    final streamed = await repository.watchAll().first;
    expect(streamed.map((p) => p.id), equals([keep.id]));
  });
}

