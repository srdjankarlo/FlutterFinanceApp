class ExchangeRateModel {
  final int? id;
  final String mainCurrency;
  final String targetCurrency;
  final double rate;
  final DateTime timestamp;

  ExchangeRateModel({
    this.id,
    required this.mainCurrency,
    required this.targetCurrency,
    required this.rate,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'main_currency': mainCurrency,
    'target_currency': targetCurrency,
    'rate': rate,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ExchangeRateModel.fromMap(Map<String, dynamic> map) {
    return ExchangeRateModel(
      id: map['id'] as int?,
      mainCurrency: map['main_currency'],
      targetCurrency: map['target_currency'],
      rate: map['rate'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}
