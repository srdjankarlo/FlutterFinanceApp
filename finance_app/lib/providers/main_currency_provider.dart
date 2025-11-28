import 'package:flutter/material.dart';

import '../constants/currencies.dart';

class MainCurrencyProvider extends ChangeNotifier {
  String _currency = 'RSD';
  String get currency => _currency;

  void setCurrency(String c) {
    if (!Currencies.all.contains(c)) return;
    if (_currency != c) {
      _currency = c;
      notifyListeners();
    }
  }
}
