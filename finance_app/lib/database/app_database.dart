import 'package:finance_app/models/finance_item_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  // ====== SINGLETON PATTERN ======
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  // ====== INITIALIZATION ======
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Enable foreign keys for cascading deletes
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // === Muscles Table ===
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

  }

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

  // ====== CLOSE DATABASE ======
  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}
