import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/main_currency_provider.dart';
import '../services/currency_conversion_service.dart';
import '../constants/currencies.dart';
import '../models/exchange_rate_model.dart';

class RatesPage extends StatefulWidget {
  const RatesPage({super.key});

  @override
  State<RatesPage> createState() => _RatesPageState();
}

class _RatesPageState extends State<RatesPage> {
  final Map<String, TextEditingController> controllers = {};
  Map<String, ExchangeRateModel> currentRates = {};
  String mainCurrency = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    mainCurrency = Provider.of<MainCurrencyProvider>(context, listen: false).currency;

    await CurrencyConversionService.instance.reloadRates();

    final rates = <String, ExchangeRateModel>{};
    for (var c in Currencies.all) {
      if (c == mainCurrency) continue;
      final model = await CurrencyConversionService.instance.getRateModelForPair(mainCurrency, c);
      if (model != null) rates[c] = model; // only add non-null
    }

    setState(() {
      currentRates = rates;
      controllers.clear();
      for (var c in Currencies.all) {
        if (c == mainCurrency) continue;
        controllers[c] = TextEditingController(text: '');
      }
    });

    for (var c in Currencies.all) {
      if (c == mainCurrency) continue;
      final rateValue =
      await CurrencyConversionService.instance.getDisplayRate(mainCurrency, c);
      controllers[c]?.text = rateValue.toStringAsFixed(6);
    }
  }

  Future<void> _saveRate(String target) async {
    final text = controllers[target]?.text.trim();
    if (text == null || text.isEmpty) return;

    final value = double.tryParse(text);
    if (value == null) return;

    final success = await CurrencyConversionService.instance.upsertFromMain(
      main: mainCurrency,
      target: target,
      inputValue: value,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rate saved!')),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to save rate (missing base rate).')),
      );
    }
  }

  Future<void> _deleteRate(String target) async {
    await CurrencyConversionService.instance.deleteRate(target);
    setState(() {
      controllers[target]?.text = '';
      currentRates.remove(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = Currencies.all.where((c) => c != mainCurrency).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Exchange Rates')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text('Main currency: $mainCurrency',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final curr = items[i];
                  final rate = currentRates[curr];

                  return Card(
                    child: ListTile(
                      subtitle: Text(rate == null
                          ? 'No rate set'
                          : 'Last updated: ${rate.timestamp.toLocal().toString().split(".")[0]}'),
                      trailing: SizedBox(
                        width: 210,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controllers[curr],
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  suffixText: curr,
                                  hintText: 'Rate',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () => _saveRate(curr),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteRate(curr),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
