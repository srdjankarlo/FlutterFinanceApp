import 'package:finance_app/models/finance_item_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/exchange_rate_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE finance_item (
        id INTEGER PRIMARY KEY,
        currency TEXT NOT NULL,
        amount REAL NOT NULL,
        flow TEXT NOT NULL,
        category TEXT NOT NULL,
        timestamp TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE NOT NULL
      );
    ''');

    // Keep base column (we'll always store rows with base='EUR')
    await db.execute('''
      CREATE TABLE exchange_rates (
        base TEXT NOT NULL,
        target TEXT NOT NULL,
        rate REAL NOT NULL,
        timestamp TEXT NOT NULL,
        PRIMARY KEY (base, target)
      );
    ''');
  }

  // Finance item CRUD (unchanged)
  Future<int> insertItem(FinanceItemModel item) async {
    final db = await instance.database;
    return await db.insert('finance_item', item.toMap());
  }

  Future<List<FinanceItemModel>> getAllItems() async {
    final db = await instance.database;
    final maps = await db.query('finance_item');
    return maps.map((map) => FinanceItemModel.fromMap(map)).toList();
  }

  Future<int> updateItem(FinanceItemModel item) async {
    final db = await instance.database;
    return await db.update(
      'finance_item',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'finance_item',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Categories
  Future<void> insertCategory(String name) async {
    final db = await instance.database;
    await db.insert(
      'categories',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name');
    return result.map((row) => row['name'] as String).toList();
  }

  // Exchange rate CRUD
  Future<void> upsertRate(ExchangeRateModel rate) async {
    final db = await instance.database;
    await db.insert(
      'exchange_rates',
      rate.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ExchangeRateModel?> getRate(String base, String target) async {
    final db = await instance.database;
    final result = await db.query(
      'exchange_rates',
      where: 'base = ? AND target = ?',
      whereArgs: [base, target],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ExchangeRateModel.fromMap(result.first);
  }

  Future<List<ExchangeRateModel>> getRatesForBase(String base) async {
    final db = await instance.database;
    final result = await db.query(
      'exchange_rates',
      where: 'base = ?',
      whereArgs: [base],
    );

    return result.map((row) => ExchangeRateModel.fromMap(row)).toList();
  }

  Future<List<ExchangeRateModel>> getAllRates() async {
    final db = await instance.database;
    final result = await db.query('exchange_rates');
    return result.map((row) => ExchangeRateModel.fromMap(row)).toList();
  }

  Future<void> deleteRate(String base, String target) async {
    final db = await instance.database;
    await db.delete(
      'exchange_rates',
      where: 'base = ? AND target = ?',
      whereArgs: [base, target],
    );
  }

  Future<void> clearAllRates() async {
    final db = await instance.database;
    await db.delete('exchange_rates');
  }

  // helper for manual insert given base='EUR'
  Future<void> upsertManualEurRate(String target, double rate) async {
    final db = await instance.database;
    await db.insert(
      'exchange_rates',
      {
        'base': 'EUR',
        'target': target,
        'rate': rate,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}
