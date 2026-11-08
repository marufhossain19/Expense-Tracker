import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DatabaseHelper manages local SQLite database using sqflite.
/// Database Name: expense_tracker.db
/// Table Name: transactions
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String dbName = 'expense_tracker.db';
  static const String tableName = 'transactions';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    // Enable FFI on Windows and Linux desktops
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  /// Insert a new transaction and return generated autoincrement ID
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await database;
    // Remove null or non-int id so AUTOINCREMENT takes effect
    final cleanRow = Map<String, dynamic>.from(row);
    if (cleanRow['id'] == null || cleanRow['id'] is! int) {
      cleanRow.remove('id');
    }
    return await db.insert(tableName, cleanRow);
  }

  /// Fetch all transactions ordered by date descending
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query(tableName, orderBy: 'date DESC, id DESC');
  }

  /// Update an existing transaction by ID
  Future<int> updateTransaction(Map<String, dynamic> row) async {
    final db = await database;
    final id = row['id'];
    if (id == null) return 0;
    return await db.update(
      tableName,
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a transaction by ID
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all transactions from table
  Future<int> clearTransactions() async {
    final db = await database;
    return await db.delete(tableName);
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
