import '../models/finance_item_model.dart';

class CsvMapper {
  // Header order used for export
  static List<String> header = [
    'id',
    'currency',
    'amount',
    'flow',
    'category',
    'timestamp'
  ];

  // Model -> row
  static List<dynamic> toRow(FinanceItemModel item) {
    return [
      item.id ?? '',
      item.currency,
      item.amount,
      item.flow,
      item.category,
      item.timestamp.millisecondsSinceEpoch,
    ];
  }

  // Row (list) + headerIndexMap -> FinanceItemModel
  // row may contain numbers or strings; parse defensively
  static FinanceItemModel fromRowWithIndexMap(
      List<dynamic> row, Map<String, int> indexOf) {
    dynamic maybe(int? idx) => (idx != null && idx >= 0 && idx < row.length) ? row[idx] : null;

    final rawId = maybe(indexOf['id']);
    final id = (rawId == null || rawId == '') ? null : int.tryParse(rawId.toString()) ?? null;

    final rawCurrency = maybe(indexOf['currency']);
    final currency = (rawCurrency ?? '').toString();

    final rawAmount = maybe(indexOf['amount']);
    final amount = double.tryParse(rawAmount?.toString() ?? '') ??
        (rawAmount is num ? rawAmount.toDouble() : 0.0);

    final rawFlow = maybe(indexOf['flow']);
    final flow = (rawFlow ?? '').toString();

    final rawCategory = maybe(indexOf['category']);
    final category = (rawCategory ?? '').toString();

    final rawTs = maybe(indexOf['timestamp']);
    int tsMillis;
    if (rawTs == null || (rawTs is String && rawTs.isEmpty)) {
      tsMillis = DateTime.now().millisecondsSinceEpoch;
    } else if (rawTs is num) {
      tsMillis = rawTs.toInt();
    } else {
      // may be a string with ISO date or epoch string
      final s = rawTs.toString();
      final asInt = int.tryParse(s);
      if (asInt != null) {
        tsMillis = asInt;
      } else {
        // try parse ISO date
        final dt = DateTime.tryParse(s);
        tsMillis = (dt != null) ? dt.millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch;
      }
    }

    return FinanceItemModel(
      id: id,
      currency: currency,
      amount: amount,
      flow: flow,
      category: category,
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMillis),
    );
  }
}
