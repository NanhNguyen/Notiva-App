import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Pieces extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get composer => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Sections extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get pieceId => text().references(Pieces, #id)();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer()();
  TextColumn get pageRef => text().nullable()();
  IntColumn get measureStart => integer().nullable()();
  IntColumn get measureEnd => integer().nullable()();
  TextColumn get difficultyTags => text().withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  TextColumn get links => text().withDefault(const Constant('[]'))();
  IntColumn get rhStatus => integer().withDefault(const Constant(0))();
  IntColumn get lhStatus => integer().withDefault(const Constant(0))();
  IntColumn get htStatus => integer().withDefault(const Constant(0))();
  TextColumn get nextAction => text().nullable()();
  DateTimeColumn get lastPracticedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PlanItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get sectionId => text().references(Sections, #id)();
  TextColumn get date => text()();
  TextColumn get goal => text().nullable()();
  TextColumn get priority => text()();
  TextColumn get state => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  TextColumn get date => text()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get sectionId => text().references(Sections, #id)();
  TextColumn get planItemId =>
      text().nullable().references(PlanItems, #id)();
  TextColumn get hands => text().withDefault(const Constant('[]'))();
  IntColumn get tempo => integer().nullable()();
  TextColumn get outcome => text()();
  TextColumn get note => text().nullable()();
  TextColumn get nextAction => text().nullable()();
  IntColumn get rhBefore => integer()();
  IntColumn get lhBefore => integer()();
  IntColumn get htBefore => integer()();
  IntColumn get rhAfter => integer()();
  IntColumn get lhAfter => integer()();
  IntColumn get htAfter => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Pieces, Sections, PlanItems, Sessions, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'notiva.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}

