import '../constants/currencies.dart';
import '../database/app_database.dart';
import '../models/exchange_rate_model.dart';

class CurrencyConversionService {
  static final CurrencyConversionService instance = CurrencyConversionService._init();
  CurrencyConversionService._init();

  final Map<String, ExchangeRateModel> _eurRates = {};
  bool _loaded = false;

  /// Load all EUR->X rates from database
  Future<void> loadRates() async {
    if (_loaded) return;

    _eurRates.clear();
    for (var c in Currencies.all) {
      if (c == 'EUR') continue;
      final model = await AppDatabase.instance.getExchangeRate(main: 'EUR', target: c);
      if (model != null) _eurRates[c] = model;
    }

    _loaded = true;
  }

  Future<void> reloadRates() async {
    _loaded = false;
    await loadRates();
  }

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

  Future<double> getDisplayRate(String main, String target) async {
    await loadRates();
    if (main == target) return 1.0;

    final eurMain = main == 'EUR' ? 1.0 : _eurRates[main]?.rate;
    final eurTarget = target == 'EUR' ? 1.0 : _eurRates[target]?.rate;

    if (eurMain == null || eurTarget == null || eurMain == 0) return 0;

    return eurTarget / eurMain;
  }

  Future<bool> upsertFromMain({
    required String main,
    required String target,
    required double inputValue,
  }) async {
    await loadRates();
    if (main == target) return false;

    final now = DateTime.now();
    late ExchangeRateModel model;

    if (main == 'EUR') {
      model = ExchangeRateModel(
        mainCurrency: 'EUR',
        targetCurrency: target,
        rate: inputValue,
        timestamp: now,
      );
      _eurRates[target] = model;
    } else if (target == 'EUR') {
      if (inputValue == 0) return false;
      model = ExchangeRateModel(
        mainCurrency: 'EUR',
        targetCurrency: main,
        rate: 1 / inputValue,
        timestamp: now,
      );
      _eurRates[main] = model;
    } else {
      final eurMain = _eurRates[main]?.rate;
      if (eurMain == null) return false;
      model = ExchangeRateModel(
        mainCurrency: 'EUR',
        targetCurrency: target,
        rate: eurMain * inputValue,
        timestamp: now,
      );
      _eurRates[target] = model;
    }

    return await AppDatabase.instance.upsertExchangeRate(model);
  }

  Future<void> deleteRate(String target) async {
    await AppDatabase.instance.deleteExchangeRate(main: 'EUR', target: target);
    _eurRates.remove(target);
  }

  Future<ExchangeRateModel?> getRateModel(String target) async {
    await loadRates();
    return _eurRates[target];
  }

  Future<Map<String, double>> getEurRates() async {
    await loadRates();
    return _eurRates.map((key, value) => MapEntry(key, value.rate));
  }

  /// Returns ExchangeRateModel for main -> target, or null if not set
  Future<ExchangeRateModel?> getRateModelForPair(String main, String target) async {
    await loadRates();

    if (main == 'EUR') {
      return _eurRates[target];
    } else if (target == 'EUR') {
      return _eurRates[main];
    } else {
      final eurMainRate = _eurRates[main]?.rate;
      final eurTargetRate = _eurRates[target]?.rate;
      if (eurMainRate == null || eurTargetRate == null) return null;

      // Construct virtual model for display
      return ExchangeRateModel(
        mainCurrency: main,
        targetCurrency: target,
        rate: eurTargetRate / eurMainRate,
        timestamp: DateTime.now(), // Optional: could leave null or show earliest relevant
      );
    }
  }

}
