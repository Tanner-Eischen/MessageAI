import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Table definitions
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer()(); // Unix timestamp
  IntColumn get updatedAt => integer()();
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();
  IntColumn get lastMessageAt => integer().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  TextColumn get body => text()();
  TextColumn get mediaUrl => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {conversationId, id}
  ];
}

class Participants extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get userId => text()();
  IntColumn get joinedAt => integer()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {conversationId, userId}
  ];
}

class Receipts extends Table {
  TextColumn get id => text()();
  TextColumn get messageId => text()();
  TextColumn get userId => text()();
  TextColumn get status => text()(); // 'delivered', 'read'
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {messageId, userId}
  ];
}

class PendingOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()(); // 'send_message', 'ack_receipt'
  TextColumn get payload => text()(); // JSON serialized
  TextColumn get conversationId => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Main database class
@DriftDatabase(tables: [Conversations, Messages, Participants, Receipts, PendingOutbox])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle schema migrations here
      },
    );
  }

  /// Get the singleton instance of the database
  static AppDb? _instance;

  static AppDb get instance => _instance ??= AppDb();

  /// Close the database connection
  Future<void> close() async {
    await super.close();
    _instance = null;
  }
}

// Connection logic
QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'messageai_db',
    native: DriftNativeSqlite3Database.memory(),
  );
}
