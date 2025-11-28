import 'package:intl/intl.dart';

class FinanceItemModel {
  final int? id;
  final String currency;
  final double amount;
  final String flow;
  final String category;
  final DateTime timestamp ;

  FinanceItemModel({
    this.id,
    required this.currency,
    required this.amount,
    required this.flow,
    required this.category,
    required this.timestamp,
  });

  // --- Helpers ---
  String get timeFormatted => DateFormat('HH:mm').format(timestamp);
  String get dateFormatted => DateFormat('dd.MM.yyyy').format(timestamp);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currency': currency,
      'amount': amount,
      'flow': flow,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FinanceItemModel.fromMap(Map<String, dynamic> map) {
    return FinanceItemModel(
      id: map['id'],
      currency: map['currency'],
      amount: (map['amount'] as num).toDouble(),
      flow: map['flow'],
      category: map['category'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
