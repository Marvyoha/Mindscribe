import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

import '../models/journal_entry.dart';

/// SQLite-backed persistence for [JournalEntry] records.
///
/// The database is a singleton so every caller shares a single connection.
/// All public methods are safe to call before initialization: they await the
/// lazily-opened database instance.
class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  static const _dbName = 'mindscribe.db';
  static const _dbVersion = 1;

  static const tableEntries = 'journal_entries';

  Database? _database;

  Future<Database> get database async {
    final db = _database;
    if (db != null) return db;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(docsDir.path, _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableEntries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            date TEXT NOT NULL,
            mood TEXT NOT NULL,
            ai_summary TEXT,
            ai_sentiment TEXT,
            ai_takeaways TEXT,
            ai_reflection_prompt TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Reserved for future schema migrations.
      },
    );
  }

  // --- CRUD --------------------------------------------------------------

  /// Inserts a new entry and returns its auto-generated id.
  Future<int> insertEntry(JournalEntry entry) async {
    final db = await database;
    try {
      return await db.insert(
        tableEntries,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw DatabaseException('insertEntry failed: $e\n$st');
    }
  }

  /// Returns every entry, newest first.
  Future<List<JournalEntry>> getAllEntries() async {
    final db = await database;
    try {
      final rows = await db.query(
        tableEntries,
        orderBy: 'date DESC, id DESC',
      );
      return rows.map(JournalEntry.fromMap).toList();
    } catch (e, st) {
      throw DatabaseException('getAllEntries failed: $e\n$st');
    }
  }

  /// Updates an existing entry by id. Returns number of rows changed.
  Future<int> updateEntry(JournalEntry entry) async {
    final db = await database;
    if (entry.id == null) {
      throw ArgumentError('updateEntry requires an entry with a non-null id');
    }
    try {
      return await db.update(
        tableEntries,
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e, st) {
      throw DatabaseException('updateEntry failed: $e\n$st');
    }
  }

  /// Deletes an entry by id. Returns number of rows removed.
  Future<int> deleteEntry(int id) async {
    final db = await database;
    try {
      return await db.delete(
        tableEntries,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw DatabaseException('deleteEntry failed: $e\n$st');
    }
  }

  /// Case-insensitive substring search across title, content, and sentiment.
  Future<List<JournalEntry>> searchEntries(String query) async {
    final db = await database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAllEntries();

    final like = '%${trimmed.toLowerCase()}%';
    try {
      final rows = await db.query(
        tableEntries,
        where: 'title LIKE ? OR content LIKE ? OR ai_sentiment LIKE ?',
        whereArgs: [like, like, like],
        orderBy: 'date DESC, id DESC',
      );
      return rows.map(JournalEntry.fromMap).toList();
    } catch (e, st) {
      throw DatabaseException('searchEntries failed: $e\n$st');
    }
  }

  /// Deletes every entry. Used by the "clear data" action.
  Future<int> clearAllEntries() async {
    final db = await database;
    try {
      return await db.delete(tableEntries);
    } catch (e, st) {
      throw DatabaseException('clearAllEntries failed: $e\n$st');
    }
  }
}

class DatabaseException implements Exception {
  DatabaseException(this.message);
  final String message;
  @override
  String toString() => message;
}