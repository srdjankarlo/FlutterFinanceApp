import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/currencies.dart';
import '../providers/main_currency_provider.dart';
import '../theme/color_schemes.dart';
import '../main.dart'; // for ThemeProvider

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mainCurrencyProvider = Provider.of<MainCurrencyProvider>(context);

    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // --- Header ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),

          // --- Language (placeholder) ---
          ListTile(
            title: const Text('Language'),
            onTap: () {},
          ),

          // --- Color Scheme ---
          ListTile(
            title: const Text('Color Scheme'),
            subtitle: Text('Current: ${themeProvider.schemeName}'),
            onTap: () => _showColorSchemeDialog(context, themeProvider),
          ),

          // --- Main Currency ---
          ListTile(
            title: const Text('Default Currency'),
            subtitle: Text('Current: ${mainCurrencyProvider.currency}'),
            onTap: () => _showCurrencyDialog(context, mainCurrencyProvider),
          ),

          // --- Donate (placeholder) ---
          ListTile(
            title: const Text('Donate'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(
      BuildContext context, MainCurrencyProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Default Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Currencies.all.map((c) {
              final isSelected = provider.currency == c;
              return ListTile(
                title: Text(c),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  provider.setCurrency(c);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showColorSchemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Color Scheme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: appColorSchemes.keys.map((schemeName) {
              final isSelected = themeProvider.schemeName == schemeName;
              return ListTile(
                title: Text(schemeName),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  themeProvider.changeScheme(schemeName);
                  Navigator.pop(context); // close dialog
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

