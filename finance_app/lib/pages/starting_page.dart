import 'package:finance_app/pages/input_data_page.dart';
import 'package:finance_app/pages/list_data_page.dart';
import 'package:finance_app/pages/rates_page.dart';
import 'package:flutter/material.dart';
import '../widgets/settings_drawer.dart';

class StartingPage extends StatelessWidget {
  const StartingPage({super.key});

  final List<String> menuItems = const [
    'Input',
    'Data List View',
    'Statistics',
    'Rates'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance App'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      endDrawer: const SettingsDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: menuItems.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  if (item == 'Input') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InputDataPage()),
                    );
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(content: Text('$item page not implemented yet')),
                    // );
                  } else if (item == 'Data List View') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FinanceListPage()),
                    );
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(content: Text('$item page not implemented yet')),
                    // );
                  } else if (item == 'Statistics') {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => const PersonalRecordsPage()),
                    // );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$item page not implemented yet')),
                    );
                  } else if (item == 'Rates') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RatesPage()),
                    );
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(content: Text('$item page not implemented yet')),
                    // );
                  }
                  else {
                    // Placeholder for other pages
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$item page not implemented yet')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(item, style: const TextStyle(fontSize: 25)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
