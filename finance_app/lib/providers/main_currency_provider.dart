import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

class MainCurrencyProvider extends ChangeNotifier {
  static const _prefKey = 'main_currency';

  late String _currency;
  String get currency => _currency;

  MainCurrencyProvider._(this._currency);

  /// Creates a fully-initialized provider.
  static Future<MainCurrencyProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    // Load available currencies from DB
    final currencies = await AppDatabase.instance.getCurrencies();

    // Decide initial currency
    String initial = 'EUR';

    if (currencies.isNotEmpty) {
      if (saved != null && currencies.contains(saved)) {
        initial = saved;
      } else {
        // If nothing saved, default to the first available
        initial = currencies.first;
        await prefs.setString(_prefKey, initial);
      }
    }

    return MainCurrencyProvider._(initial);
  }

  /// Updates and persists main currency.
  Future<void> setCurrency(String code) async {
    // Validate input
    final currencies = await AppDatabase.instance.getCurrencies();
    if (!currencies.contains(code)) return;

    if (code == _currency) return; // No change

    _currency = code;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }
}
