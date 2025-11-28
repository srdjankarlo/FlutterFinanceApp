class ExchangeRateModel {
  final String base; // will be 'EUR' in our design
  final String target; // e.g. 'RSD', 'USD', 'GBP'
  final double rate; // meaning: 1 base (EUR) = rate target
  final DateTime timestamp;

  ExchangeRateModel({
    required this.base,
    required this.target,
    required this.rate,
    required this.timestamp,
  });

  factory ExchangeRateModel.fromMap(Map<String, dynamic> map) {
    final rateVal = map['rate'];
    final parsedRate = rateVal is int
        ? rateVal.toDouble()
        : (rateVal is double ? rateVal : double.tryParse(rateVal.toString()) ?? 0.0);

    final tsVal = map['timestamp'];
    DateTime parsedTs;
    if (tsVal == null) {
      parsedTs = DateTime.now();
    } else if (tsVal is String) {
      parsedTs = DateTime.tryParse(tsVal) ?? DateTime.now();
    } else if (tsVal is DateTime) {
      parsedTs = tsVal;
    } else {
      parsedTs = DateTime.now();
    }

    return ExchangeRateModel(
      base: map['base'] as String,
      target: map['target'] as String,
      rate: parsedRate,
      timestamp: parsedTs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'base': base,
      'target': target,
      'rate': rate,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
