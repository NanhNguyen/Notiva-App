import 'package:uuid/uuid.dart';

/// Generates client-side UUID v4 identifiers for all entities.
abstract interface class IdGenerator {
  String nextId();
}

class UuidIdGenerator implements IdGenerator {
  UuidIdGenerator([Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  @override
  String nextId() => _uuid.v4();
}

