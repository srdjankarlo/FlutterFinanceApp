import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../models/finance_item_model.dart';
import '../providers/main_currency_provider.dart';
import '../widgets/edit_item_dialog.dart';
import '../widgets/outline_text.dart';

class FinanceListPage extends StatefulWidget {
  const FinanceListPage({super.key});

  @override
  State<FinanceListPage> createState() => _FinanceListPageState();
}

class _FinanceListPageState extends State<FinanceListPage> {
  List<FinanceItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await AppDatabase.instance.getAllItems();

    // Sort newest first
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  // Group items by month -> day
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

  // Sum amounts for a given flow and currency
  double _sumFlow(List<FinanceItemModel> items, String flow, String currency) {
    return items.where((i) => i.flow == flow && i.currency == currency).fold(0.0, (prev, i) => prev + i.amount);
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
          final monthDays = monthEntry.value.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key)); // newest day first

          // Month totals
          final allMonthItems = monthDays.expand((e) => e.value).toList();
          final monthIncome = _sumFlow(allMonthItems, 'Income', mainCurrency);
          final monthExpense = _sumFlow(allMonthItems, 'Expense', mainCurrency);

          return [
            // Month header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.grey[300],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
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
            // Days
            ...monthDays.expand((dayEntry) {
              final dayKey = dayEntry.key;
              final dayDate = DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(dayKey));
              final dayItems = dayEntry.value;

              final dayIncome = _sumFlow(dayItems, 'Income', mainCurrency);
              final dayExpense = _sumFlow(dayItems, 'Expense', mainCurrency);

              return [
                // Day header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  color: Colors.grey[200],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
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
                // Items
                ...dayItems.map((item) => GestureDetector(
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
                          Column(
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
                                maxLines: null,  // unlimited lines
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
              ];
            })
          ];
        }).toList(),
      ),
    );
  }
}
