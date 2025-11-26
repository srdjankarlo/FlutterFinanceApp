import 'package:flutter/material.dart';

class MainCurrencyProvider extends ChangeNotifier {
  String _currency = 'RSD';
  String get currency => _currency;

  void setCurrency(String c) {
    _currency = c;
    notifyListeners();
  }
}
