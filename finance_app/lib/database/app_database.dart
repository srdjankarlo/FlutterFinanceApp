import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/finance_item_model.dart';
import '../models/exchange_rate_model.dart';

class AppDatabase {
  AppDatabase._privateConstructor();
  static final AppDatabase instance = AppDatabase._privateConstructor();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'finance_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE finance_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency TEXT NOT NULL,
        amount REAL NOT NULL,
        flow TEXT NOT NULL,
        category TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE exchange_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        main_currency TEXT NOT NULL,
        target_currency TEXT NOT NULL,
        rate REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        UNIQUE(main_currency, target_currency)
      );
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        piggy_bank REAL NOT NULL,
        owing REAL NOT NULL,
        last_processed_month TEXT NOT NULL
      );
    ''');

    // INSERT DEFAULT SETTINGS ROW
    await db.insert('settings', {
      'id': 1,
      'piggy_bank': 0.0,
      'owing': 0.0,
      'last_processed_month': ''
    });

  }

  // Finance Item
  Future<int> insertItem(FinanceItemModel item) async {
    final database = await db;
    return await database.insert('finance_item', item.toMap());
  }

  Future<List<FinanceItemModel>> getAllItems() async {
    final database = await db;
    final res = await database.query('finance_item');
    return res.map((e) => FinanceItemModel.fromMap(e)).toList();
  }

  Future<List<FinanceItemModel>> getItemsBetween(DateTime start, DateTime end) async {
    final database = await db;
    final res = await database.query(
      'finance_item',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return res.map((e) => FinanceItemModel.fromMap(e)).toList();
  }

  Future<int> updateItem(FinanceItemModel item) async {
    final database = await db;
    return await database.update(
      'finance_item',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final database = await db;
    return await database.delete('finance_item', where: 'id = ?', whereArgs: [id]);
  }

  // Categories
  Future<int> insertCategory(String name) async {
    final database = await db;
    return await database.insert('categories', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getCategories() async {
    final database = await db;
    final res = await database.query('categories', orderBy: 'name');
    return res.map((e) => e['name'] as String).toList();
  }

  Future<int> updateCategory(int id, String name) async {
    final database = await db;
    return await database.update('categories', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final database = await db;
    return await database.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Exchange Rates
  Future<ExchangeRateModel?> getExchangeRate({required String main, required String target}) async {
    final database = await db;
    final res = await database.query(
      'exchange_rates',
      where: 'main_currency = ? AND target_currency = ?',
      whereArgs: [main, target],
    );
    if (res.isEmpty) return null;
    return ExchangeRateModel.fromMap(res.first);
  }

  Future<bool> upsertExchangeRate(ExchangeRateModel model) async {
    final database = await db;
    final id = await database.insert('exchange_rates', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return id > 0;
  }

  Future<void> deleteExchangeRate({required String main, required String target}) async {
    final database = await db;
    await database.delete(
      'exchange_rates',
      where: 'main_currency = ? AND target_currency = ?',
      whereArgs: [main, target],
    );
  }

}
