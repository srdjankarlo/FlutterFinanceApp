import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

class MainCurrencyProvider extends ChangeNotifier {
  static const _prefKey = 'main_currency';

  String _currency = 'EUR';
  String get currency => _currency;

  MainCurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    final list = await AppDatabase.instance.getCurrencies();

    // If saved value exists AND exists in DB, use it
    if (saved != null && list.contains(saved)) {
      _currency = saved;
      notifyListeners();
      return;
    }

    // If saved is invalid OR missing → try default from DB
    if (list.isNotEmpty) {
      _currency = list.first;
      prefs.setString(_prefKey, _currency);
      notifyListeners();
    }
  }

  Future<void> setCurrency(String code) async {
    final list = await AppDatabase.instance.getCurrencies();
    if (!list.contains(code)) return;

    if (_currency != code) {
      _currency = code;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    }
  }
}
