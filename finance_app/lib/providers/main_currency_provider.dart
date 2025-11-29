import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/currencies.dart';

class MainCurrencyProvider extends ChangeNotifier {
  static const _prefKey = 'main_currency';

  String _currency = 'RSD';
  String get currency => _currency;

  MainCurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && Currencies.all.contains(saved)) {
      _currency = saved;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String c) async {
    if (!Currencies.all.contains(c)) return;
    if (_currency != c) {
      _currency = c;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, c);
    }
  }
}
