import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:messageai/data/drift/daos/conversation_dao.dart';
import 'package:messageai/data/drift/daos/message_dao.dart';
import 'package:messageai/data/drift/daos/receipt_dao.dart';
import 'package:messageai/data/drift/daos/participant_dao.dart';
import 'package:messageai/data/drift/daos/pending_outbox_dao.dart';
// AI Analysis DAO commented out (using remote-only approach)
// Uncomment and restore from backup files when scaling to local cache
// import 'package:messageai/data/drift/daos/ai_analysis_dao.dart';

part 'app_db.g.dart';

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

// AI Analysis table commented out for now (using remote-only approach)
// Uncomment and restore from backup files when scaling to local cache
/*
class AiAnalysis extends Table {
  TextColumn get id => text()();
  TextColumn get messageId => text()();
  TextColumn get tone => text()();
  TextColumn get urgencyLevel => text().nullable()();
  TextColumn get intent => text().nullable()();
  RealColumn get confidenceScore => real().nullable()();
  IntColumn get analysisTimestamp => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
*/

// Main database class
// Note: AiAnalysis table and AIAnalysisDao commented out (using remote-only approach)
@DriftDatabase(
  tables: [Conversations, Messages, Participants, Receipts, PendingOutbox],
  daos: [ConversationDao, MessageDao, ReceiptDao, ParticipantDao, PendingOutboxDao],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1; // Reverted to 1 (AI table removed)

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // AI Analysis migration commented out (using remote-only approach)
        // if (from == 1 && to == 2) {
        //   await m.createTable(aiAnalysis);
        // }
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
  );
}
