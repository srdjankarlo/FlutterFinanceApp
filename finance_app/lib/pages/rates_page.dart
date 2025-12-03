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
  Map<String, ExchangeRateModel?> currentRates = {};
  String mainCurrency = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    mainCurrency = Provider.of<MainCurrencyProvider>(context, listen: false).currency;

    await CurrencyConversionService.instance.reloadRates();

    final rates = <String, ExchangeRateModel?>{};
    for (var c in Currencies.all) {
      if (c == mainCurrency) continue;
      rates[c] = await CurrencyConversionService.instance.getRateModel(mainCurrency, c);
    }

    setState(() {
      currentRates = rates;
      controllers.clear();

      for (var c in Currencies.all) {
        if (c == mainCurrency) continue;
        controllers[c] = TextEditingController(
          text: currentRates[c]?.rate.toString() ?? '',
        );
      }
    });
  }

  Future<void> _saveRate(String target) async {
    final text = controllers[target]?.text.trim();
    if (text == null || text.isEmpty) return;

    final value = double.tryParse(text);
    if (value == null) return;

    final ok = await CurrencyConversionService.instance.savePair(
      main: mainCurrency,
      target: target,
      rate: value,
    );

    if (ok) {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    }
  }

  Future<void> _deleteRate(String target) async {
    await CurrencyConversionService.instance.deletePair(mainCurrency, target);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = Currencies.all.where((c) => c != mainCurrency).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Exchange Rates')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Main currency: $mainCurrency',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final curr = items[i];
                  final model = currentRates[curr];

                  return Card(
                    child: ListTile(
                      subtitle: Text(
                        model == null
                            ? 'No rate'
                            : 'Updated: ${model.timestamp.toLocal().toString().split(".")[0]}',
                      ),
                      trailing: SizedBox(
                        width: 210,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controllers[curr],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            Text(curr),
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
