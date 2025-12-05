import '../database/app_database.dart';
import '../models/exchange_rate_model.dart';

class CurrencyConversionService {
  static final CurrencyConversionService instance = CurrencyConversionService._();

  CurrencyConversionService._();

  final Map<String, ExchangeRateModel> _cache = {};
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;

    _cache.clear();
    final db = AppDatabase.instance;
    final allPairs = await db.getAllExchangeRates();

    for (final m in allPairs) {
      _cache['${m.mainCurrency}_${m.targetCurrency}'] = m;
    }

    _loaded = true;
  }

  /// Public initializer to call from main()
  Future<void> init() => _load();

  Future<void> reloadRates() async {
    _loaded = false;
    await _load();
  }

  // READ: return direct rate if exists
  Future<double?> getRate(String main, String target) async {
    await _load();
    if (main == target) return 1;

    final key = '${main}_${target}';
    return _cache[key]?.rate;
  }

  // READ model directly
  Future<ExchangeRateModel?> getRateModel(String main, String target) async {
    await _load();
    return _cache['${main}_${target}'];
  }

  // CONVERT directly using pair
  Future<double?> convert({
    required String from,
    required String to,
    required double amount,
  }) async {
    final rate = await getRate(from, to);
    if (rate == null) return null;
    return amount * rate;
  }

  // SAVE direct + reverse
  Future<bool> savePair({
    required String main,
    required String target,
    required double rate,
  }) async {
    if (rate == 0) return false;

    final now = DateTime.now();
    final db = AppDatabase.instance;

    final direct = ExchangeRateModel(
      mainCurrency: main,
      targetCurrency: target,
      rate: rate,
      timestamp: now,
    );

    final reverse = ExchangeRateModel(
      mainCurrency: target,
      targetCurrency: main,
      rate: 1 / rate,
      timestamp: now,
    );

    final ok1 = await db.upsertExchangeRate(direct);
    final ok2 = await db.upsertExchangeRate(reverse);

    if (ok1 && ok2) {
      _cache['${main}_${target}'] = direct;
      _cache['${target}_${main}'] = reverse;
      return true;
    }

    return false;
  }

  // DELETE both directions
  Future<void> deletePair(String main, String target) async {
    final db = AppDatabase.instance;

    await db.deleteExchangeRate(main: main, target: target);
    await db.deleteExchangeRate(main: target, target: main);

    _cache.remove('${main}_${target}');
    _cache.remove('${target}_${main}');
  }
}
