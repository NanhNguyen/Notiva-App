import 'package:drift/drift.dart';

import '../../domain/models/section.dart';
import '../database/app_database.dart' as db;
import '../helpers/clock.dart';
import '../helpers/id_generator.dart';

/// Repository interface for practice sections.
abstract interface class SectionRepository {
  Future<List<Section>> getByPieceId(String pieceId);
}

/// Drift-backed skeleton implementation of [SectionRepository].
class DriftSectionRepository implements SectionRepository {
  DriftSectionRepository({
    required db.AppDatabase db,
    required IdGenerator idGenerator,
    required AppClock clock,
  })  : _db = db,
        _idGenerator = idGenerator,
        _clock = clock;

  final db.AppDatabase _db;
  // Kept for upcoming slices.
  // ignore: unused_field
  final IdGenerator _idGenerator;
  // ignore: unused_field
  final AppClock _clock;

  @override
  Future<List<Section>> getByPieceId(String pieceId) async {
    await (_db.select(_db.sections)
          ..where((t) => t.pieceId.equals(pieceId) & t.deletedAt.isNull()))
        .get();
    return const [];
  }
}
