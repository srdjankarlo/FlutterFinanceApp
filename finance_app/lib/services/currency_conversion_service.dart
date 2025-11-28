import '../constants/currencies.dart';
import '../database/app_database.dart';
import '../models/exchange_rate_model.dart';

class CurrencyConversionService {
  // Singleton
  static final CurrencyConversionService instance = CurrencyConversionService._init();
  CurrencyConversionService._init();

  // Internal cache: EUR -> X
  final Map<String, ExchangeRateModel> _eurRates = {};
  bool _loaded = false;

  /// Load all EUR->X rates from database
  Future<void> loadRates() async {
    if (_loaded) return;

    _eurRates.clear();
    final rows = await AppDatabase.instance.getRatesForBase('EUR');
    for (final r in rows) {
      _eurRates[r.target] = r;
    }

    _loaded = true;
  }

  /// Force reload from database
  Future<void> reloadRates() async {
    _loaded = false;
    await loadRates();
  }

  /// Convert amount from any currency to any currency using EUR as pivot
  Future<double?> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    await loadRates();
    if (from == to) return amount;

    final eurFrom = from == 'EUR' ? 1.0 : _eurRates[from]?.rate;
    final eurTo = to == 'EUR' ? 1.0 : _eurRates[to]?.rate;

    if (eurFrom == null || eurTo == null || eurFrom == 0) return null;

    return amount * (eurTo / eurFrom);
  }

  /// Get rate to display in UI (1 MAIN = ? TARGET)
  Future<double> getDisplayRate(String main, String target) async {
    await loadRates();

    if (main == target) return 1.0;

    final eurMain = main == 'EUR' ? 1.0 : _eurRates[main]?.rate;
    final eurTarget = target == 'EUR' ? 1.0 : _eurRates[target]?.rate;

    if (eurMain == null || eurTarget == null || eurMain == 0) return 0;

    return eurTarget / eurMain; // always correct
  }

  /// Save a rate from main -> target entered by user
  /// Meaning: 1 MAIN = inputValue TARGET
  Future<bool> upsertFromMain({
    required String main,
    required String target,
    required double inputValue,
  }) async {
    await loadRates();
    if (main == target) return false; // meaningless

    final now = DateTime.now();
    late ExchangeRateModel model;

    if (main == 'EUR') {
      // Direct: EUR -> target
      model = ExchangeRateModel(
        base: 'EUR',
        target: target,
        rate: inputValue,
        timestamp: now,
      );
      _eurRates[target] = model;
    } else if (target == 'EUR') {
      // 1 MAIN = inputValue EUR => EUR->MAIN = 1/inputValue
      if (inputValue == 0) return false;
      model = ExchangeRateModel(
        base: 'EUR',
        target: main,
        rate: 1 / inputValue,
        timestamp: now,
      );
      _eurRates[main] = model;
    } else {
      // Both non-EUR: need EUR->MAIN
      final eurMain = _eurRates[main]?.rate;
      if (eurMain == null) return false;

      model = ExchangeRateModel(
        base: 'EUR',
        target: target,
        rate: eurMain * inputValue,
        timestamp: now,
      );
      _eurRates[target] = model;
    }

    await AppDatabase.instance.upsertRate(model);
    return true;
  }

  /// Delete EUR->target
  Future<void> deleteRate(String target) async {
    await AppDatabase.instance.deleteRate('EUR', target);
    _eurRates.remove(target);
  }

  /// Get model for EUR->target
  Future<ExchangeRateModel?> getRateModel(String target) async {
    await loadRates();
    return _eurRates[target];
  }

  /// Get numeric map EUR->X
  Future<Map<String, double>> getEurRates() async {
    await loadRates();
    return _eurRates.map((key, value) => MapEntry(key, value.rate));
  }
}
