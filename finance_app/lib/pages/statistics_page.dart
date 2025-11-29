import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // for mapIndexed
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

  Widget _buildHorizontalBarChart(Map<String, double> data, String title) {
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text("No $title data", textAlign: TextAlign.center),
      );
    }

    final total = data.values.fold(0.0, (a, b) => a + b);
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // AUTO SIZED SCROLLABLE LIST OF HORIZONTAL BARS
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final cat = entries[i].key;
            final val = entries[i].value;
            final percent = (val / total) * 100;
            final barWidthFactor = val / maxValue;

            final color = Colors.primaries[i % Colors.primaries.length];

            // Text visibility inside bar
            final labelInside = barWidthFactor > 0.25;
            final labelColor = labelInside ? Colors.white : Colors.black;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // CATEGORY NAME
                  SizedBox(
                    width: 100,
                    child: Text(
                      cat,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // BAR + LABEL
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // BAR
                        FractionallySizedBox(
                          widthFactor: barWidthFactor,
                          child: Container(
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),

                        // LABEL (amount + percentage)
                        Positioned(
                          left: labelInside
                              ? 10
                              : (barWidthFactor *
                              (MediaQuery.of(context).size.width - 160)) +
                              6,
                          child: Text(
                            "${val.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
          _buildHorizontalBarChart(_expenseByCategory, "Expenses"),

          const SizedBox(height: 30),

          // PIE CHART – INCOME
          _buildHorizontalBarChart(_incomeByCategory, "Income"),
        ],
      ),
    );
  }
}
