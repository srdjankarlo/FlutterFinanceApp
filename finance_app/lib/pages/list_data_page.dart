import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../models/finance_item_model.dart';
import '../providers/main_currency_provider.dart';
import '../services/currency_conversion_service.dart';
import '../widgets/edit_item_dialog.dart';
import '../widgets/outline_text.dart';

class ConvertedTotals {
  double income;
  double expense;

  ConvertedTotals({this.income = 0, this.expense = 0});
}

class FinanceListPage extends StatefulWidget {
  const FinanceListPage({super.key});

  @override
  State<FinanceListPage> createState() => _FinanceListPageState();
}

class _FinanceListPageState extends State<FinanceListPage> {
  List<FinanceItemModel> _items = [];
  bool _loading = true;
  Map<String, Map<String, ConvertedTotals>> _totals = {};
  String _mainCurrency = "";
  bool _didInitDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prov = Provider.of<MainCurrencyProvider>(context);
    if (!_didInitDependencies || _mainCurrency != prov.currency) {
      _didInitDependencies = true;
      _mainCurrency = prov.currency;
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);

    final items = await AppDatabase.instance.getAllItems();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final mainCurrency = _mainCurrency;
    final totals = <String, Map<String, ConvertedTotals>>{};
    final service = CurrencyConversionService.instance;

    // Pre-fetch all conversions asynchronously (sequentially is OK for small lists; optimize later if needed)
    final convertedValues = <int, double>{}; // use ID/index stable key
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final converted = await service.convert(amount: item.amount, from: item.currency, to: mainCurrency);
      convertedValues[i] = converted ?? 0;
    }

    // Compute totals in a single pass
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final monthKey = DateFormat('yyyy-MM').format(item.timestamp);
      final dayKey = DateFormat('yyyy-MM-dd').format(item.timestamp);

      totals.putIfAbsent(monthKey, () => {});
      totals[monthKey]!.putIfAbsent(dayKey, () => ConvertedTotals());

      final conv = convertedValues[i] ?? 0;

      if (item.flow == 'Income') {
        totals[monthKey]![dayKey]!.income += conv;
      } else {
        totals[monthKey]![dayKey]!.expense += conv;
      }
    }

    if (!mounted) return;
    setState(() {
      _items = items;
      _totals = totals;
      _loading = false;
    });
  }

  String _formatAmount(double amount) {
    final f = NumberFormat('#,##0.##');
    return f.format(amount);
  }

  Future<void> _editItem(FinanceItemModel item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditFinanceItemDialog(item: item),
    );

    if (result == true) {
      await _loadItems();
    }
  }

  Map<String, Map<String, List<FinanceItemModel>>> _groupByMonthDay(List<FinanceItemModel> items) {
    final map = <String, Map<String, List<FinanceItemModel>>>{};
    for (var item in items) {
      final monthKey = DateFormat('yyyy-MM').format(item.timestamp);
      final dayKey = DateFormat('yyyy-MM-dd').format(item.timestamp);
      map.putIfAbsent(monthKey, () => {});
      map[monthKey]!.putIfAbsent(dayKey, () => []);
      map[monthKey]![dayKey]!.add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final mainCurrency = Provider.of<MainCurrencyProvider>(context).currency;
    final grouped = _groupByMonthDay(_items);
    final primaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Finance Records')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(12),
        children: grouped.entries.expand((monthEntry) {
          final monthKey = monthEntry.key;
          final monthName = DateFormat('MMMM yyyy').format(DateTime.parse('$monthKey-01'));
          final monthDays = monthEntry.value.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

          final monthIncome = _totals[monthKey]!.values.fold(0.0, (sum, t) => sum + t.income);
          final monthExpense = _totals[monthKey]!.values.fold(0.0, (sum, t) => sum + t.expense);

          return [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.grey[300],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Balance: ${_formatAmount(monthIncome - monthExpense)} $mainCurrency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (monthIncome - monthExpense) >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Income: ${_formatAmount(monthIncome)} $mainCurrency'),
                      Text('Expense: ${_formatAmount(monthExpense)} $mainCurrency'),
                    ],
                  ),
                ],
              ),
            ),
            // Days + items
            ...monthDays.expand((dayEntry) {
              final dayKey = dayEntry.key;
              final dayDate = DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(dayKey));
              final dayItems = dayEntry.value;

              final dayIncome = _totals[monthKey]![dayKey]!.income;
              final dayExpense = _totals[monthKey]![dayKey]!.expense;

              return [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  color: Colors.grey[200],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        'Balance: ${_formatAmount(dayIncome - dayExpense)} $mainCurrency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (dayIncome - dayExpense) >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Income: ${_formatAmount(dayIncome)} $mainCurrency'),
                          Text('Expense: ${_formatAmount(dayExpense)} $mainCurrency'),
                        ],
                      ),
                    ],
                  ),
                ),
                ...dayItems.map((item) {
                  return GestureDetector(
                    onTap: () => _editItem(item),
                    child: Card(
                      color: primaryColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('HH:mm:ss').format(item.timestamp)),
                                OutlinedText(
                                  text: item.flow,
                                  size: 18,
                                  strokeWidth: 3,
                                  outlineColor: Colors.black,
                                  fillColor: item.flow == 'Income' ? Colors.green : Colors.red,
                                ),
                                Text(
                                  '${_formatAmount(item.amount)} ${item.currency}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.category,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              softWrap: true,
                              maxLines: null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                })
              ];
            })
          ];
        }).toList(),
      ),
    );
  }
}
