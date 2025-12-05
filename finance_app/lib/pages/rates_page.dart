import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/main_currency_provider.dart';
import '../services/currency_conversion_service.dart';
import '../database/app_database.dart';
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
  bool loading = true;
  bool firstRun = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Run only once when dependencies are ready
    if (firstRun) {
      firstRun = false;
      _safeLoad();
    }
  }

  Future<void> _safeLoad() async {
    final provider = Provider.of<MainCurrencyProvider>(context, listen: false);

    // Wait until provider finishes loading
    mainCurrency = provider.currency;

    await _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() => loading = true);

    await CurrencyConversionService.instance.reloadRates();

    final tempRates = <String, ExchangeRateModel?>{};
    final currencyList = await AppDatabase.instance.getCurrencies();

    for (var c in currencyList) {
      if (c == mainCurrency) continue;
      tempRates[c] =
      await CurrencyConversionService.instance.getRateModel(mainCurrency, c);
    }

    setState(() {
      currentRates = tempRates;

      controllers.clear();
      for (var c in currencyList) {
        if (c == mainCurrency) continue;

        controllers[c] = TextEditingController(
          text: currentRates[c]?.rate.toString() ?? '',
        );
      }

      loading = false;
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
      await _loadRates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    }
  }

  Future<void> _deleteRate(String target) async {
    await CurrencyConversionService.instance.deletePair(mainCurrency, target);
    await _loadRates();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = currentRates.keys.toList();

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
                    color: Theme.of(context).colorScheme.secondary,
                    child: ListTile(
                      subtitle: Text(
                        model == null
                            ? 'No rate'
                            : 'Updated: ${model.timestamp.toLocal().toString().split(".")[0]}',
                      ),
                      trailing: SizedBox(
                        width: 240,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controllers[curr],
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                              ),
                            ),
                            Text(
                              ' $curr',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
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
