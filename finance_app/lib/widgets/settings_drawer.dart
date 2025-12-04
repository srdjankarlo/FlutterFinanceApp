import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../providers/main_currency_provider.dart';
import '../theme/color_schemes.dart';
import '../main.dart'; // ThemeProvider

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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 10),

          // Language placeholder
          ListTile(
            title: const Text('Language'),
            onTap: () {},
          ),

          // Color Scheme
          ListTile(
            title: const Text('Color Scheme'),
            subtitle: Text('Current: ${themeProvider.schemeName}'),
            onTap: () => _showColorSchemeDialog(context, themeProvider),
          ),

          // Default Currency
          ListTile(
            title: const Text('Default Currency'),
            subtitle: Text('Current: ${mainCurrencyProvider.currency}'),
            onTap: () => _showCurrencyDialog(context, mainCurrencyProvider),
          ),

          // Donate placeholder
          ListTile(
            title: const Text('Donate'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  //                Currency Dialog (DB-driven)
  // ------------------------------------------------------
  void _showCurrencyDialog(
      BuildContext context, MainCurrencyProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Default Currency'),
          content: FutureBuilder<List<String>>(
            future: AppDatabase.instance.getCurrencies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No currencies found in database.');
              }

              final list = snapshot.data!;

              return SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: list.map((code) {
                    final isSelected = provider.currency == code;

                    return ListTile(
                      title: Text(code),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        provider.setCurrency(code);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ------------------------------------------------------
  //                  Color Scheme Dialog
  // ------------------------------------------------------
  void _showColorSchemeDialog(
      BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Color Scheme'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: appColorSchemes.keys.map((schemeName) {
                final isSelected = themeProvider.schemeName == schemeName;

                return ListTile(
                  title: Text(schemeName),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    themeProvider.changeScheme(schemeName);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
