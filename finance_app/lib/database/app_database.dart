import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/finance_item_model.dart';
import '../models/exchange_rate_model.dart';

class AppDatabase {
  AppDatabase._privateConstructor();
  static final AppDatabase instance = AppDatabase._privateConstructor();

  static Database? _db;

  /// Ensure DB is opened (call from main())
  Future<void> init() async {
    await db;
  }

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
      CREATE TABLE currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL
      );
    ''');

    // Pre-populate
    await db.insert('currencies', {'code': 'EUR'});
    await db.insert('currencies', {'code': 'USD'});
    await db.insert('currencies', {'code': 'GBP'});
  }

  // -------------------------------------------------------------- Finance Item
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

  // ---------------------------------------------------------------- Categories
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

  Future<void> updateCategoryByName(String oldName, String newName) async {
    final dbClient = await db;
    await dbClient.update('categories', {'name': newName}, where: 'name = ?', whereArgs: [oldName]);
  }

  Future<void> deleteCategoryByName(String name) async {
    final dbClient = await db;
    await dbClient.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  // ------------------------------------------------------------ Exchange Rates
  Future<List<ExchangeRateModel>> getAllExchangeRates() async {
    final database = await db;
    final res = await database.query('exchange_rates');
    return res.map((e) => ExchangeRateModel.fromMap(e)).toList();
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

  // ---------------------------------------------------------------- Currencies
  Future<int> insertCurrency(String code) async {
    final database = await db;
    return await database.insert(
      'currencies',
      {'code': code},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getCurrencies() async {
    final database = await db;
    final res = await database.query('currencies', orderBy: 'code');
    return res.map((e) => e['code'] as String).toList();
  }

  Future<int> updateCurrency(int id, String newCode) async {
    final database = await db;
    return await database.update(
      'currencies',
      {'code': newCode},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCurrency(int id) async {
    final database = await db;
    return await database.delete(
        'currencies',
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> updateCurrencyByCode(String oldCode, String newCode) async {
    final dbClient = await db;
    await dbClient.update('currencies', {'code': newCode}, where: 'code = ?', whereArgs: [oldCode]);
  }

  Future<void> deleteCurrencyByCode(String code) async {
    final dbClient = await db;
    await dbClient.delete('currencies', where: 'code = ?', whereArgs: [code]);
  }
}
