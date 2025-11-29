import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../models/finance_item_model.dart';
import '../providers/main_currency_provider.dart';
import '../services/currency_conversion_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _loading = true;

  double _monthIncome = 0;
  double _monthExpense = 0;

  Map<String, double> _expenseByCategory = {};
  Map<String, double> _incomeByCategory = {};

  final TextEditingController _saveController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final db = AppDatabase.instance;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final items = await db.getItemsBetween(monthStart, monthEnd);
    final mainCurrency = Provider.of<MainCurrencyProvider>(context, listen: false).currency;
    final service = CurrencyConversionService.instance;

    // Convert all items to main currency
    final convertedValues = <FinanceItemModel, double>{};
    for (var item in items) {
      final converted = await service.convert(
        amount: item.amount,
        from: item.currency,
        to: mainCurrency,
      );
      convertedValues[item] = converted ?? 0;
    }

    double income = 0;
    double expense = 0;

    final expCat = <String, double>{};
    final incCat = <String, double>{};

    for (var item in items) {
      final conv = convertedValues[item] ?? 0;
      if (item.flow == "Income") {
        income += conv;
        incCat[item.category] = (incCat[item.category] ?? 0) + conv;
      } else {
        expense += conv;
        expCat[item.category] = (expCat[item.category] ?? 0) + conv;
      }
    }

    setState(() {
      _monthIncome = income;
      _monthExpense = expense;
      _expenseByCategory = expCat;
      _incomeByCategory = incCat;
      _loading = false;
    });
  }

  double? _calculateDailyLimit() {
    if (_saveController.text.trim().isEmpty) return null;
    final saveAmount = double.tryParse(_saveController.text);
    if (saveAmount == null || saveAmount <= 0) return null;

    final balance = _monthIncome - _monthExpense;
    if (balance <= 0 || balance < saveAmount) return null;

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    final remaining = balance - saveAmount;
    return remaining / daysInMonth;
  }

  Widget _buildPie(Map<String, double> data, String title) {
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text("No $title data", textAlign: TextAlign.center),
      );
    }

    final total = data.values.fold(0.0, (a, b) => a + b);

    final sections = data.entries.map((e) {
      final percent = (e.value / total * 100).toStringAsFixed(1);
      final idx = data.keys.toList().indexOf(e.key);

      return PieChartSectionData(
        value: e.value,
        title: "$percent%",
        radius: 55,
        color: Colors.primaries[idx % Colors.primaries.length],
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
      );
    }).toList();

    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        SizedBox(height: 200, child: PieChart(PieChartData(sections: sections))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: data.keys.map((cat) {
            final idx = data.keys.toList().indexOf(cat);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  color: Colors.primaries[idx % Colors.primaries.length],
                ),
                const SizedBox(width: 5),
                Text(cat),
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final main = Provider.of<MainCurrencyProvider>(context).currency;
    final balance = _monthIncome - _monthExpense;
    final dailyLimit = _calculateDailyLimit();

    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // MONTH SUMMARY
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("This month", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Text("Income: ${_monthIncome.toStringAsFixed(2)} $main", style: const TextStyle(color: Colors.green)),
                  Text("Expense: ${_monthExpense.toStringAsFixed(2)} $main", style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  Text(
                    "Balance: ${balance.toStringAsFixed(2)} $main",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.blue : Colors.redAccent),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // SAVINGS CALCULATOR
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Daily Spend Limit Calculator",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _saveController,
                    decoration: InputDecoration(
                        labelText: "How much do you want to save $main monthly?"),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (dailyLimit == null)
                    const Text(
                      "Enter valid amount. Must be less than balance.",
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    Text(
                      "You can spend: ${dailyLimit.toStringAsFixed(2)} $main per day",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // PIE CHART – EXPENSES
          _buildPie(_expenseByCategory, "Expenses"),

          const SizedBox(height: 30),

          // PIE CHART – INCOME
          _buildPie(_incomeByCategory, "Income"),
        ],
      ),
    );
  }
}
