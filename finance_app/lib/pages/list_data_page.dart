import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../models/finance_item_model.dart';
import '../providers/main_currency_provider.dart';
import '../services/currency_conversion_service.dart';
import '../widgets/edit_item_dialog.dart';
import '../widgets/outline_text.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';

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

  // NEW: Expansion logic
  bool _expandMonths = true;
  bool _expandDays = true;

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

  Future<void> _exportDataToCsv() async {
    final file = await ExportService.exportCsv(_items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported: ${file.path}')),
    );
  }

  Future<void> _exportPdf() async {
    final file = await ExportService.exportPdf(_items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF exported: ${file.path}')),
    );
  }

  Future<void> _importDataFromCsv() async {
    final count = await ImportService.importCsvAndStore();
    if (!mounted) return;
    if (count > 0) {
      await _loadItems(); // reload data from DB
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count items')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items imported')),
      );
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);

    final items = await AppDatabase.instance.getAllItems();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final mainCurrency = _mainCurrency;
    final totals = <String, Map<String, ConvertedTotals>>{};
    final service = CurrencyConversionService.instance;

    final convertedValues = <int, double>{};
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final converted = await service.convert(
          amount: item.amount, from: item.currency, to: mainCurrency);
      convertedValues[i] = converted ?? 0;
    }

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

  Map<String, Map<String, List<FinanceItemModel>>> _groupByMonthDay(
      List<FinanceItemModel> items) {
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

  // ----------------------------------------------
  // UI
  // ----------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mainCurrency =
        Provider.of<MainCurrencyProvider>(context).currency;

    final grouped = _groupByMonthDay(_items);

    final primaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Records'),
        actions: [
          IconButton(
            tooltip: _expandMonths ? 'Collapse all months' : 'Expand all months',
            icon: Icon(_expandMonths ? Icons.unfold_less : Icons.unfold_more),
            onPressed: () {
              setState(() {
                _expandMonths = !_expandMonths;
                if (!_expandMonths) _expandDays = false;
              });
            },
          ),
          IconButton(
            tooltip: _expandDays ? 'Collapse all days' : 'Expand all days',
            icon: Icon(_expandDays ? Icons.expand_less : Icons.expand_more),
            onPressed: _expandMonths
                ? () {
              setState(() => _expandDays = !_expandDays);
            }
                : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'pdf') {
                await _exportPdf();
              } else if (value == 'export') {
                await _exportDataToCsv();
              } else if (value == 'import') {
                await _importDataFromCsv();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Make PDF report')),
              const PopupMenuItem(value: 'export', child: Text('Export data')),
              const PopupMenuItem(value: 'import', child: Text('Import data')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(grouped, mainCurrency, primaryColor),
    );
  }

  Widget _buildList(
      Map<String, Map<String, List<FinanceItemModel>>> grouped,
      String currency,
      Color primaryColor) {
    final months = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: months.map((monthKey) {
        return _buildMonthTile(monthKey, grouped[monthKey]!, currency, primaryColor);
      }).toList(),
    );
  }

  Widget _buildMonthTile(
      String monthKey,
      Map<String, List<FinanceItemModel>> days,
      String currency,
      Color primaryColor) {
    final monthName =
    DateFormat('MMMM yyyy').format(DateTime.parse('$monthKey-01'));

    final monthIncome =
    _totals[monthKey]!.values.fold(0.0, (a, b) => a + b.income);
    final monthExpense =
    _totals[monthKey]!.values.fold(0.0, (a, b) => a + b.expense);
    final monthBalance = monthIncome - monthExpense;

    final sortedDays = days.keys.toList()..sort((a, b) => b.compareTo(a));

    return Card(
      color: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        key: ValueKey('$monthKey-$_expandMonths'),
        initiallyExpanded: _expandMonths,
        title: Column(
          children: [
            Text(monthName,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface)),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                    child: _metricBox(
                        'Income\n${_formatAmount(monthIncome)} $currency')),
                Expanded(
                    child: _metricBox(
                        'Expense\n${_formatAmount(monthExpense)} $currency')),
                Expanded(
                    child: _metricBox(
                        'Balance\n${_formatAmount(monthBalance)} $currency',
                        color: monthBalance >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
        children: sortedDays.map((dayKey) {
          return _buildDayTile(
              monthKey, dayKey, days[dayKey]!, currency, primaryColor);
        }).toList(),
      ),
    );
  }

  Widget _buildDayTile(
      String monthKey,
      String dayKey,
      List<FinanceItemModel> items,
      String currency,
      Color primaryColor) {
    final date = DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(dayKey));

    final inc = _totals[monthKey]![dayKey]!.income;
    final exp = _totals[monthKey]![dayKey]!.expense;
    final bal = inc - exp;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        key: ValueKey('$dayKey-$_expandDays'),
        initiallyExpanded: _expandDays && _expandMonths,
        title: Column(
          children: [
            Text(date,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(child: _metricBox('Income\n${_formatAmount(inc)} $currency')),
                Expanded(child: _metricBox('Expense\n${_formatAmount(exp)} $currency')),
                Expanded(
                  child: _metricBox(
                    'Balance\n${_formatAmount(bal)} $currency',
                    color: bal >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: items.map((item) {
          return _buildItemCard(item, primaryColor);
        }).toList(),
      ),
    );
  }

  Widget _buildItemCard(FinanceItemModel item, Color primaryColor) {
    return Card(
      color: primaryColor,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _editItem(item), // immediately open the Edit Item dialog
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _metricBox(DateFormat('HH:mm').format(item.timestamp)),
                  ),
                  Expanded(
                    child: Center(
                      child: OutlinedText(
                        text: item.flow,
                        size: 18,
                        strokeWidth: 3,
                        outlineColor: Colors.black,
                        fillColor: item.flow == 'Income' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _metricBox('${_formatAmount(item.amount)} ${item.currency}'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricBox(String text, {Color? color}) {
    return Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style:
          TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
